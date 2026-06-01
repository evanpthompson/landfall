import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';

/// GET /config — non-sensitive display configuration for the client.
///
/// Currently exposes the configured display timezone as an IANA name (e.g.
/// "America/Chicago"), read from `piTimezone` in passwords.yaml. The display
/// clock uses it to render the household's wall-clock time even when the
/// device OS clock is in another zone — most importantly the Pi, whose server
/// container defaults to UTC. An empty string signals the client to fall back
/// to device-local time.
///
/// Mounted at `/config` (not under `/api/*`) so Caddy's catch-all routes it to
/// the web server (8082), matching the other web routes like `/device` and
/// `/health/build`. No authentication: the timezone is non-sensitive global
/// config and the clock must never be gated on auth state.
class ConfigRoute extends Route {
  ConfigRoute() : super(methods: {Method.get});

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final timezone = session.passwords['piTimezone'] ?? '';
    return Response(
      200,
      body: Body.fromString(
        jsonEncode({'timezone': timezone}),
        mimeType: MimeType.json,
      ),
    );
  }
}
