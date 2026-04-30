import 'dart:io';

Process? _serverProcess;

/// Starts the Landfall server if it is not already listening on port 8080.
///
/// Resolves the server directory relative to the integration test working
/// directory (`apps/display/` at runtime) and runs:
///   dart run bin/main.dart --apply-migrations
///
/// Waits up to 30 seconds for the server to accept connections. If the server
/// is already up (e.g. started manually), this is a no-op.
Future<void> startServer() async {
  if (await _isServerUp()) return;

  final serverDir = _resolveServerDir();
  _serverProcess = await Process.start(
    'dart',
    ['run', 'bin/main.dart', '--apply-migrations'],
    workingDirectory: serverDir,
  );

  // Drain stdout/stderr so the process doesn't block on a full pipe buffer.
  _serverProcess!.stdout.drain<List<int>>();
  _serverProcess!.stderr.drain<List<int>>();

  const maxWait = Duration(seconds: 30);
  const pollInterval = Duration(milliseconds: 500);
  final deadline = DateTime.now().add(maxWait);

  while (DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(pollInterval);
    if (await _isServerUp()) return;
  }

  _serverProcess?.kill();
  _serverProcess = null;
  throw StateError(
    'Landfall server did not become ready within ${maxWait.inSeconds}s. '
    'Check that the server builds and that no migrations are pending.',
  );
}

/// Kills the server process that was started by [startServer].
///
/// If the server was already running when [startServer] was called (external
/// process), this is a no-op — we only kill what we started.
Future<void> stopServer() async {
  _serverProcess?.kill();
  _serverProcess = null;
}

/// Returns true if something is accepting TCP connections on localhost:8080.
Future<bool> _isServerUp() async {
  try {
    final socket = await Socket.connect(
      'localhost',
      8080,
      timeout: const Duration(seconds: 1),
    );
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}

/// Resolves the absolute path to `server/landfall_server/`.
///
/// When Flutter runs integration tests on macOS the working directory is the
/// app package root (`apps/display/`), so the server is two levels up.
String _resolveServerDir() {
  final repoRoot = Directory.current.parent.parent;
  return '${repoRoot.path}/server/landfall_server';
}
