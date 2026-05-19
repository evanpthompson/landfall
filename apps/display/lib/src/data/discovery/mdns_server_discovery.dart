import 'dart:async';

import 'package:nsd/nsd.dart';

/// A single Landfall server found via mDNS service discovery.
class DiscoveredServer {
  const DiscoveredServer({
    required this.name,
    required this.serverUrl,
    this.version,
  });

  final String name;
  final String serverUrl;
  final String? version;

  @override
  bool operator ==(Object other) =>
      other is DiscoveredServer && other.serverUrl == serverUrl;

  @override
  int get hashCode => serverUrl.hashCode;
}

typedef ServiceStreamFactory = Stream<(Service, ServiceStatus)> Function(
  String serviceType,
);

/// Discovers Landfall servers on the LAN by scanning for `_landfall._tcp`
/// mDNS services. Each emitted list is the complete current set of live
/// servers.
///
/// The [serviceStream] parameter is injectable for testing. In production
/// it defaults to a stream built on top of the `nsd` package.
///
/// After [timeout] elapses with no services found, an empty list is emitted
/// so callers can offer the manual-URL fallback. Default is 8 seconds.
class MdnsServerDiscovery {
  MdnsServerDiscovery({
    ServiceStreamFactory? serviceStream,
    this.timeout = const Duration(seconds: 8),
  }) : _serviceStreamFactory = serviceStream ?? _defaultServiceStream;

  final ServiceStreamFactory _serviceStreamFactory;
  final Duration timeout;

  final _servers = <String, DiscoveredServer>{};
  final _controller = StreamController<List<DiscoveredServer>>.broadcast();
  StreamSubscription<(Service, ServiceStatus)>? _subscription;
  Timer? _timeoutTimer;
  bool _started = false;

  /// Emits the current list of discovered servers every time it changes.
  Stream<List<DiscoveredServer>> get servers => _controller.stream;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    _timeoutTimer = Timer(timeout, () {
      if (!_controller.isClosed) {
        _controller.add(List.unmodifiable(_servers.values));
      }
    });

    final stream = _serviceStreamFactory('_landfall._tcp');
    _subscription = stream.listen(_onEvent);
  }

  Future<void> stop() async {
    _timeoutTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
    _servers.clear();
  }

  void _onEvent((Service, ServiceStatus) event) {
    final (service, status) = event;
    final serverUrl = _extractServerUrl(service);
    if (serverUrl == null) return;

    if (status == ServiceStatus.found) {
      _servers[serverUrl] = DiscoveredServer(
        name: service.name ?? serverUrl,
        serverUrl: serverUrl,
        version: _extractTxt(service, 'version'),
      );
    } else if (status == ServiceStatus.lost) {
      _servers.remove(serverUrl);
    }

    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_servers.values));
    }
  }

  static String? _extractServerUrl(Service service) =>
      _extractTxt(service, 'serverUrl');

  static String? _extractTxt(Service service, String key) {
    final bytes = service.txt?[key];
    if (bytes == null) return null;
    return String.fromCharCodes(bytes);
  }
}

// Production stream: wraps nsd startDiscovery + listener into a Dart stream.
Stream<(Service, ServiceStatus)> _defaultServiceStream(String serviceType) {
  late StreamController<(Service, ServiceStatus)> ctrl;
  Discovery? discovery;

  ctrl = StreamController<(Service, ServiceStatus)>(
    onListen: () async {
      discovery = await startDiscovery(serviceType);
      discovery!.addServiceListener((service, status) {
        if (!ctrl.isClosed) ctrl.add((service, status));
      });
    },
    onCancel: () async {
      if (discovery != null) await stopDiscovery(discovery!);
    },
  );

  return ctrl.stream;
}
