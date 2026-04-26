import 'dart:io';

/// Checks whether a Landfall server is reachable at a given URL.
abstract interface class ServerHealthChecker {
  Future<bool> ping(String serverUrl);
}

/// Production implementation — issues an HTTP GET to [serverUrl] and returns
/// true if the server responds with any non-5xx status within 5 seconds.
class HttpServerHealthChecker implements ServerHealthChecker {
  const HttpServerHealthChecker();

  @override
  Future<bool> ping(String serverUrl) async {
    try {
      final uri = Uri.parse(serverUrl);
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(const Duration(seconds: 5));
      await response.drain<void>();
      client.close();
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }
}
