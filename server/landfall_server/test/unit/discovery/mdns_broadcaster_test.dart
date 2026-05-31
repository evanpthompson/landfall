import 'dart:io';

import 'package:test/test.dart';

import 'package:landfall_server/src/discovery/mdns_broadcaster.dart';

// Fake Process that records how it was started and whether kill was called.
class _FakeProcess implements Process {
  _FakeProcess(this.executable, this.arguments);

  final String executable;
  final List<String> arguments;
  bool killed = false;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    return true;
  }

  @override
  Future<int> get exitCode async => 0;

  @override
  Stream<List<int>> get stderr => const Stream.empty();
  @override
  Stream<List<int>> get stdout => const Stream.empty();
  @override
  IOSink get stdin => throw UnimplementedError();
  @override
  int get pid => 0;
}

void main() {
  const testConfig = MdnsBroadcasterConfig(
    serviceName: 'Landfall Server',
    port: 8080,
    serverUrl: 'http://MacBookPro-3.lan:8080',
    version: '1.0.0',
  );

  group('ProcessMdnsBroadcaster — Linux', () {
    late _FakeProcess fakeProcess;
    late ProcessMdnsBroadcaster broadcaster;

    setUp(() {
      broadcaster = ProcessMdnsBroadcaster(
        config: testConfig,
        isLinux: true,
        isMacOS: false,
        processStarter: (executable, args) async {
          fakeProcess = _FakeProcess(executable, args);
          return fakeProcess;
        },
      );
    });

    test('start() spawns avahi-publish with service type, port, and TXT records', () async {
      await broadcaster.start();

      expect(fakeProcess.executable, equals('avahi-publish'));
      expect(fakeProcess.arguments, contains('-s'));
      expect(fakeProcess.arguments, contains('Landfall Server'));
      expect(fakeProcess.arguments, contains('_landfall._tcp'));
      expect(fakeProcess.arguments, contains('8080'));
      expect(fakeProcess.arguments, contains('serverUrl=http://MacBookPro-3.lan:8080'));
      expect(fakeProcess.arguments, contains('version=1.0.0'));
    });

    test('stop() kills the process', () async {
      await broadcaster.start();
      await broadcaster.stop();

      expect(fakeProcess.killed, isTrue);
    });

    test('stop() before start() does not throw', () async {
      await broadcaster.stop();
    });

    test('start() is idempotent — second call does not spawn a second process', () async {
      int spawnCount = 0;
      final b = ProcessMdnsBroadcaster(
        config: testConfig,
        isLinux: true,
        isMacOS: false,
        processStarter: (executable, args) async {
          spawnCount++;
          return _FakeProcess(executable, args);
        },
      );

      await b.start();
      await b.start();

      expect(spawnCount, equals(1));
    });

    // Regression: a missing avahi-publish binary in the server's Alpine image
    // threw an unhandled ProcessException from run(), crashing the server
    // before the API port opened and trapping the Pi on the boot splash. mDNS
    // is a non-essential convenience and must degrade, never abort startup.
    test('start() swallows ProcessException when the binary is missing', () async {
      final b = ProcessMdnsBroadcaster(
        config: testConfig,
        isLinux: true,
        isMacOS: false,
        processStarter: (executable, args) async =>
            throw ProcessException(executable, args, 'No such file or directory', 2),
      );

      await expectLater(b.start(), completes);
    });

    test('start() can be retried after the binary was missing', () async {
      int attempts = 0;
      final b = ProcessMdnsBroadcaster(
        config: testConfig,
        isLinux: true,
        isMacOS: false,
        processStarter: (executable, args) async {
          attempts++;
          if (attempts == 1) {
            throw ProcessException(executable, args, 'No such file or directory', 2);
          }
          return _FakeProcess(executable, args);
        },
      );

      await b.start(); // first attempt fails and is swallowed
      await b.start(); // _process still null, so a retry is allowed

      expect(attempts, equals(2));
    });
  });

  group('mdnsBroadcastEnabled', () {
    test('defaults to true when the flag is unset', () {
      expect(mdnsBroadcastEnabled(const {}), isTrue);
    });

    test('is false for falsey values (case-insensitive)', () {
      for (final v in ['false', '0', 'off', 'no', 'FALSE', 'Off', 'No']) {
        expect(
          mdnsBroadcastEnabled({'LANDFALL_MDNS_BROADCAST': v}),
          isFalse,
          reason: 'expected "$v" to disable broadcast',
        );
      }
    });

    test('is true for any other value', () {
      for (final v in ['true', '1', 'on', 'yes', '']) {
        expect(
          mdnsBroadcastEnabled({'LANDFALL_MDNS_BROADCAST': v}),
          isTrue,
          reason: 'expected "$v" to enable broadcast',
        );
      }
    });
  });

  group('ProcessMdnsBroadcaster — macOS', () {
    late _FakeProcess fakeProcess;
    late ProcessMdnsBroadcaster broadcaster;

    setUp(() {
      broadcaster = ProcessMdnsBroadcaster(
        config: testConfig,
        isLinux: false,
        isMacOS: true,
        processStarter: (executable, args) async {
          fakeProcess = _FakeProcess(executable, args);
          return fakeProcess;
        },
      );
    });

    test('start() spawns dns-sd -R with service type, port, and TXT records', () async {
      await broadcaster.start();

      expect(fakeProcess.executable, equals('dns-sd'));
      expect(fakeProcess.arguments, contains('-R'));
      expect(fakeProcess.arguments, contains('Landfall Server'));
      expect(fakeProcess.arguments, contains('_landfall._tcp'));
      expect(fakeProcess.arguments, contains('8080'));
      expect(fakeProcess.arguments, contains('serverUrl=http://MacBookPro-3.lan:8080'));
      expect(fakeProcess.arguments, contains('version=1.0.0'));
    });

    test('stop() kills the dns-sd process', () async {
      await broadcaster.start();
      await broadcaster.stop();

      expect(fakeProcess.killed, isTrue);
    });
  });

  group('MdnsBroadcasterConfig', () {
    test('stores all fields', () {
      const config = MdnsBroadcasterConfig(
        serviceName: 'My Server',
        port: 9090,
        serverUrl: 'http://192.168.1.10:9090',
        version: '2.1.0',
      );

      expect(config.serviceName, equals('My Server'));
      expect(config.port, equals(9090));
      expect(config.serverUrl, equals('http://192.168.1.10:9090'));
      expect(config.version, equals('2.1.0'));
    });
  });
}
