import 'package:http/http.dart' as http;

/// Probes a candidate Landfall server for reachability and for the ability to
/// serve the web routes that sign-in depends on.
abstract interface class ServerHealthChecker {
  /// True if [url] answers any non-5xx HTTP response within the timeout.
  ///
  /// Used to confirm the RPC origin (the URL the user enters) is up.
  Future<bool> isReachable(String url);

  /// True if [webUrl] serves the web-only `GET /config` route (2xx).
  ///
  /// `/config` lives on the Serverpod **web server** (the Caddy catch-all
  /// origin), not the RPC API server, so a 2xx confirms [webUrl] can also serve
  /// `/auth/device/*`. Pointing the app at the bare API port instead 404s here.
  Future<bool> servesWebRoutes(String webUrl);
}

/// Production implementation over `package:http` (injectable for tests).
class HttpServerHealthChecker implements ServerHealthChecker {
  HttpServerHealthChecker({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  @override
  Future<bool> isReachable(String url) async {
    try {
      final res = await _http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      return res.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> servesWebRoutes(String webUrl) async {
    final base = webUrl.endsWith('/')
        ? webUrl.substring(0, webUrl.length - 1)
        : webUrl;
    try {
      final res = await _http
          .get(Uri.parse('$base/config'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
