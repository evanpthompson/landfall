import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsd/nsd.dart';

import 'package:display/src/data/discovery/mdns_server_discovery.dart';

void main() {
  group('MdnsServerDiscovery', () {
    late StreamController<(Service, ServiceStatus)> controller;
    late MdnsServerDiscovery discovery;

    setUp(() {
      controller = StreamController<(Service, ServiceStatus)>.broadcast();
      discovery = MdnsServerDiscovery(
        serviceStream: (_) => controller.stream,
        timeout: const Duration(milliseconds: 100),
      );
    });

    tearDown(() async {
      await discovery.stop();
      await controller.close();
    });

    test('emits discovered server when a service with serverUrl TXT appears', () async {
      final future = discovery.servers.first;

      await discovery.start();

      controller.add((_serviceWithTxt(
        name: 'Landfall',
        serverUrl: 'http://192.168.1.10:8080',
        version: '1.0.0',
      ), ServiceStatus.found));

      final servers = await future;
      expect(servers, hasLength(1));
      expect(servers.first.name, equals('Landfall'));
      expect(servers.first.serverUrl, equals('http://192.168.1.10:8080'));
      expect(servers.first.version, equals('1.0.0'));
    });

    test('accumulates multiple discovered servers', () async {
      await discovery.start();

      final serversList = <List<DiscoveredServer>>[];
      final subscription = discovery.servers.listen(serversList.add);

      controller.add((_serviceWithTxt(
        name: 'Landfall A',
        serverUrl: 'http://192.168.1.10:8080',
        version: '1.0.0',
      ), ServiceStatus.found));

      controller.add((_serviceWithTxt(
        name: 'Landfall B',
        serverUrl: 'http://192.168.1.20:8080',
        version: '1.0.0',
      ), ServiceStatus.found));

      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(serversList.last, hasLength(2));
      final urls = serversList.last.map((s) => s.serverUrl).toSet();
      expect(urls, containsAll(['http://192.168.1.10:8080', 'http://192.168.1.20:8080']));
    });

    test('removes server when ServiceStatus.lost fires', () async {
      await discovery.start();

      final serversList = <List<DiscoveredServer>>[];
      final subscription = discovery.servers.listen(serversList.add);

      final service = _serviceWithTxt(
        name: 'Landfall',
        serverUrl: 'http://192.168.1.10:8080',
        version: '1.0.0',
      );
      controller.add((service, ServiceStatus.found));
      await Future<void>.delayed(Duration.zero);
      controller.add((service, ServiceStatus.lost));
      await Future<void>.delayed(Duration.zero);

      await subscription.cancel();

      expect(serversList.last, isEmpty);
    });

    test('emits empty list after timeout when no services found', () async {
      final emittedValues = <List<DiscoveredServer>>[];
      final subscription = discovery.servers.listen(emittedValues.add);

      await discovery.start();

      // Wait longer than the 100ms timeout.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await subscription.cancel();

      expect(emittedValues, isNotEmpty);
      expect(emittedValues.last, isEmpty);
    });

    test('ignores services without a serverUrl TXT record', () async {
      await discovery.start();

      final serversList = <List<DiscoveredServer>>[];
      final subscription = discovery.servers.listen(serversList.add);

      // Service with no TXT records.
      controller.add((const Service(name: 'No TXT'), ServiceStatus.found));
      await Future<void>.delayed(Duration.zero);

      await subscription.cancel();

      // Should have no entries — the service was skipped.
      expect(serversList.isEmpty || serversList.last.isEmpty, isTrue);
    });

    test('stop() closes the stream with no errors', () async {
      await discovery.start();
      await expectLater(discovery.stop(), completes);
    });

    test('stop() before start() does not throw', () async {
      await expectLater(discovery.stop(), completes);
    });
  });
}

Service _serviceWithTxt({
  required String name,
  required String serverUrl,
  String? version,
}) {
  return Service(
    name: name,
    txt: {
      'serverUrl': Uint8List.fromList(serverUrl.codeUnits),
      if (version != null) 'version': Uint8List.fromList(version.codeUnits),
    },
  );
}
