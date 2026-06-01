import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;

/// Reads non-sensitive display config from the server's `GET /config` route.
///
/// Mirrors [HttpDeviceAuthClient]'s direct-HTTP approach (the web routes live
/// on the Serverpod web server / Caddy catch-all, not the RPC API server).
abstract interface class DisplayConfigClient {
  /// Returns the configured IANA timezone name (e.g. "America/Chicago"), or
  /// null when unset or unreachable. Never throws — the clock degrades to
  /// device-local time on any failure.
  Future<String?> fetchTimezone();
}

class HttpDisplayConfigClient implements DisplayConfigClient {
  HttpDisplayConfigClient({required String serverUrl, http.Client? httpClient})
      : _base = serverUrl.endsWith('/')
            ? serverUrl.substring(0, serverUrl.length - 1)
            : serverUrl,
        _http = httpClient ?? http.Client();

  final String _base;
  final http.Client _http;

  @override
  Future<String?> fetchTimezone() async {
    try {
      final res = await _http.get(Uri.parse('$_base/config'));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final tz = body['timezone'];
      if (tz is String && tz.isNotEmpty) return tz;
      return null;
    } catch (_) {
      // Server unreachable / malformed response — fall back to device-local.
      return null;
    }
  }
}

/// Resolves the server-configured timezone into a [tz.Location], or null when
/// none is configured or the name is unknown to the tz database.
///
/// [lookup] is injectable for tests; production uses [tz.getLocation], which
/// requires the tz database to have been initialised (see `main.dart`).
Future<tz.Location?> resolveServerTimezone(
  DisplayConfigClient client, {
  tz.Location Function(String name)? lookup,
}) async {
  final name = await client.fetchTimezone();
  if (name == null || name.isEmpty) return null;
  final look = lookup ?? tz.getLocation;
  try {
    return look(name);
  } catch (_) {
    // Unknown zone name — keep device-local time rather than crashing.
    return null;
  }
}
