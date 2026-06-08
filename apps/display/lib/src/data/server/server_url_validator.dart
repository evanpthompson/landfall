import 'package:display/src/app/app_config.dart';

import 'server_health_checker.dart';

/// Result of validating a candidate server URL.
class ServerUrlOutcome {
  const ServerUrlOutcome.ok(String url)
      : normalizedUrl = url,
        error = null;

  const ServerUrlOutcome.error(this.error) : normalizedUrl = null;

  /// The trailing-slash-normalized URL, set only when validation succeeded.
  final String? normalizedUrl;

  /// A user-facing message, set only when validation failed.
  final String? error;

  bool get isOk => normalizedUrl != null;
}

/// Shared "trim → normalize → reachability + web-origin check → message" logic,
/// used by both the first-run setup wizard and the in-app "change server
/// address" flow.
///
/// It validates two things, mirroring how the app routes traffic
/// (see `app.dart` `webServerUrl` derivation):
///   1. the entered URL (the RPC origin) is reachable, and
///   2. the **effective web-server URL** serves `/config` — so sign-in
///      (`/auth/device/*`) will work. When [kLandfallWebServerUrl] is baked in
///      (Pi/dev split-port builds) that fixed address is checked; otherwise
///      (Fire TV) the entered URL must itself be the web/Caddy origin.
class ServerUrlValidator {
  const ServerUrlValidator(this._health, {String? webServerUrlOverride})
      : _webServerUrlOverride = webServerUrlOverride;

  final ServerHealthChecker _health;

  /// Overrides [kLandfallWebServerUrl] — used in tests to inject the baked URL
  /// without a compile-time dart-define.
  final String? _webServerUrlOverride;

  /// Trims whitespace and ensures a single trailing slash.
  static String normalize(String raw) {
    final trimmed = raw.trim();
    return trimmed.endsWith('/') ? trimmed : '$trimmed/';
  }

  Future<ServerUrlOutcome> validate(String raw) async {
    final url = normalize(raw);
    final bakedWebUrl = _webServerUrlOverride ?? kLandfallWebServerUrl;
    final webUrl = bakedWebUrl.isNotEmpty ? bakedWebUrl : url;

    if (!await _health.isReachable(url)) {
      return const ServerUrlOutcome.error(
        'Could not reach the server. Check the URL and try again.',
      );
    }
    if (!await _health.servesWebRoutes(webUrl)) {
      return const ServerUrlOutcome.error(
        "Reached a server, but it can't handle sign-in. Use your Landfall "
        'web address (the one your phone uses), not the API port.',
      );
    }
    return ServerUrlOutcome.ok(url);
  }
}
