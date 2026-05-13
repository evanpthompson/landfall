import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'app_config.dart';

/// Dev-build-only self-hosted telemetry.
///
/// The entire class is a no-op when [kLandfallTelemetryEndpoint] is empty,
/// which is the default for every production build path. Release Pi images,
/// public Fire TV APKs, and public macOS dmgs ship without a telemetry URL
/// and never emit a single network call from here.
///
/// When enabled (dev build, `--dart-define=LANDFALL_TELEMETRY_ENDPOINT=...`),
/// events are POSTed fire-and-forget to the configured endpoint. Failures
/// are logged via [debugPrint] and never thrown — telemetry must never
/// affect display behaviour or surface user-visible errors.
///
/// Uses `dart:io` directly rather than `package:http` to avoid pulling in a
/// dependency only this one class needs; the rest of the display already
/// talks to the server via `HttpClient` (see `server_health_checker.dart`).
class Telemetry {
  Telemetry._();

  static const _userAgent = 'landfall-display/telemetry/1';
  static const _httpTimeout = Duration(seconds: 5);

  /// Bumped manually when the event schema changes — gives us a way to
  /// segment events in the log without depending on the app's pubspec
  /// version at runtime.
  static const _appVersion = '0.1.0-alpha';

  /// True only when the dev-only telemetry URL was baked into this build.
  /// Cheap getter — use to gate any work that's only worth doing when
  /// telemetry is on (e.g. measuring per-card render durations).
  static bool get isEnabled => kLandfallTelemetryEndpoint.isNotEmpty;

  /// Fire an event. Returns immediately — the HTTP POST happens in the
  /// background and is intentionally not awaited. Safe to call before the
  /// app is fully initialised; safe to call from build methods.
  static void event(String name, {Map<String, dynamic>? props}) {
    if (!isEnabled) return;
    // Unawaited intentionally: telemetry must never block UI work.
    unawaited(_post(name, props ?? const {}));
  }

  static Future<void> _post(String name, Map<String, dynamic> props) async {
    HttpClient? client;
    try {
      final uri = Uri.parse(kLandfallTelemetryEndpoint);
      final body = jsonEncode({
        'event': name,
        'platform': _platformName(),
        'app_version': _appVersion,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'props': props,
      });

      client = HttpClient()..connectionTimeout = _httpTimeout;
      final request = await client.postUrl(uri).timeout(_httpTimeout);
      request.headers
        ..set(HttpHeaders.contentTypeHeader, 'application/json')
        ..set(HttpHeaders.userAgentHeader, _userAgent);
      if (kLandfallTelemetryApiKey.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $kLandfallTelemetryApiKey',
        );
      }
      request.write(body);
      final response = await request.close().timeout(_httpTimeout);
      if (response.statusCode >= 400) {
        final responseBody = await response.transform(utf8.decoder).join();
        debugPrint(
          '[telemetry] $name → ${response.statusCode}: $responseBody',
        );
      } else {
        // Drain so the connection can be reused / closed cleanly.
        await response.drain<void>();
      }
    } catch (e) {
      debugPrint('[telemetry] $name → exception: $e');
    } finally {
      client?.close(force: true);
    }
  }

  static String _platformName() {
    if (kIsWeb) return 'web';
    if (Platform.isLinux) return 'linux';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    return 'unknown';
  }
}
