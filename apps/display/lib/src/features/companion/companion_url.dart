/// Builds the companion page URL from a server-reported base URL and a
/// display ID.  Returns an empty string when [baseUrl] is empty so callers
/// can show a fallback rather than a useless QR code.
String buildCompanionUrl(String baseUrl, String displayId) {
  if (baseUrl.isEmpty) return '';
  final separator = baseUrl.endsWith('/') ? '' : '/';
  return '$baseUrl${separator}c/$displayId';
}

/// Converts an API URL (e.g. http://host:8080/) to the Serverpod web-server
/// URL (port + 2, e.g. http://host:8082/).  Used as a fallback when the
/// server has not yet reported its LAN base URL.
String companionWebServerUrl(String apiUrl) {
  final uri = Uri.tryParse(apiUrl);
  if (uri == null || uri.port == 0) return apiUrl;
  return uri.replace(port: uri.port + 2).toString();
}

/// Returns the origin (scheme + host + non-default port) that serves the
/// companion web page, derived from the page's own URL.
///
/// The companion is served *by* the Serverpod web server, and the OAuth
/// connect routes (`/calendar/oauth/start`, …) live on that same origin.
/// So the page's own origin is exactly the correct base for those links —
/// whether the page is reached directly on the web port (e.g. `:8082`) or
/// through Caddy on a default port (same origin, no port suffix).
String companionWebOriginFromPage(Uri pageUri) {
  final isDefaultPort = pageUri.port == 80 || pageUri.port == 443;
  final authority =
      isDefaultPort ? pageUri.host : '${pageUri.host}:${pageUri.port}';
  return '${pageUri.scheme}://$authority/';
}
