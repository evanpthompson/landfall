import 'dart:io';

typedef ProcessStarter = Future<Process> Function(
  String executable,
  List<String> arguments,
);

/// Configuration for the mDNS service advertisement.
class MdnsBroadcasterConfig {
  const MdnsBroadcasterConfig({
    required this.serviceName,
    required this.port,
    required this.serverUrl,
    required this.version,
  });

  final String serviceName;
  final int port;
  final String serverUrl;
  final String version;
}

/// Abstract interface so callers and tests can depend on the contract, not the
/// platform-specific subprocess implementation.
abstract class MdnsBroadcaster {
  Future<void> start();
  Future<void> stop();
}

/// Broadcasts a `_landfall._tcp.local` mDNS service using the platform's
/// command-line mDNS tooling:
///
/// - Linux: `avahi-publish -s <name> _landfall._tcp <port> [txts]`
/// - macOS: `dns-sd -R <name> _landfall._tcp . <port> [txts]`
///
/// The [processStarter] parameter is injectable for testing. [isLinux] and
/// [isMacOS] override platform detection — used in unit tests only.
class ProcessMdnsBroadcaster implements MdnsBroadcaster {
  ProcessMdnsBroadcaster({
    required this.config,
    ProcessStarter? processStarter,
    bool? isLinux,
    bool? isMacOS,
  })  : _start = processStarter ?? Process.start,
        _isLinux = isLinux ?? Platform.isLinux,
        _isMacOS = isMacOS ?? Platform.isMacOS;

  final MdnsBroadcasterConfig config;
  final ProcessStarter _start;
  final bool _isLinux;
  final bool _isMacOS;

  Process? _process;

  @override
  Future<void> start() async {
    if (_process != null) return; // idempotent

    final txtRecords = [
      'serverUrl=${config.serverUrl}',
      'version=${config.version}',
    ];

    if (_isLinux) {
      _process = await _start('avahi-publish', [
        '-s',
        config.serviceName,
        '_landfall._tcp',
        '${config.port}',
        ...txtRecords,
      ]);
    } else if (_isMacOS) {
      _process = await _start('dns-sd', [
        '-R',
        config.serviceName,
        '_landfall._tcp',
        '.',
        '${config.port}',
        ...txtRecords,
      ]);
    }
  }

  @override
  Future<void> stop() async {
    _process?.kill();
    await _process?.exitCode;
    _process = null;
  }
}
