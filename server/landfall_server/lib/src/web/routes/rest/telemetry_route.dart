import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import 'rest_helpers.dart';

/// REST handler for **dev-build-only** self-hosted telemetry.
///
/// Receives structured events from a Landfall display app that was built
/// with `--dart-define=LANDFALL_TELEMETRY_ENDPOINT=...`. Production builds
/// (Pi appliance image, public Fire TV APK, public macOS dmg) do not include
/// the telemetry endpoint constant and therefore never call this route.
///
/// POST /api/v1/telemetry/event
///   Body: `{"event": "...", "platform": "...", "app_version": "...",
///           "props": {...}, "timestamp": "...iso8601..."}`
///   Logs a single `[LANDFALL_TELEMETRY]` marker line so log aggregation
///   tools (and `landfall-doctor`) can pick it up without a schema migration.
///
/// Auth: same API key as the rest of /api/v1/* — see `authenticateRequest`.
/// Rate limiting: inherits the per-key rate limit from `authenticateRequest`.
class TelemetryRoute extends Route {
  TelemetryRoute() : super(methods: {Method.post});

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final key = await authenticateRequest(session, request);
    if (key == null) return unauthorized();

    final body = await readJsonBody(request);
    if (body == null) {
      return badRequest('Body must be a JSON object');
    }

    final event = body['event'];
    final platform = body['platform'];
    if (event is! String || event.isEmpty) {
      return badRequest('Field "event" is required');
    }
    if (platform is! String || platform.isEmpty) {
      return badRequest('Field "platform" is required');
    }

    // Cap payload size before logging so a malformed client can't fill the
    // journal with megabytes of nested JSON.
    final appVersion = (body['app_version'] is String)
        ? body['app_version'] as String
        : 'unknown';
    final propsRaw = body['props'];
    final propsJson = propsRaw == null ? '{}' : jsonEncode(propsRaw);
    final propsSafe = propsJson.length > 2048
        ? '${propsJson.substring(0, 2048)}...'
        : propsJson;
    final timestamp = (body['timestamp'] is String)
        ? body['timestamp'] as String
        : DateTime.now().toUtc().toIso8601String();

    // Single-line structured marker. landfall-doctor and ad-hoc grep can
    // both consume this without parsing JSON out of multi-line journal output.
    session.log(
      '[LANDFALL_TELEMETRY] '
      'event=$event '
      'platform=$platform '
      'app_version=$appVersion '
      'key=${key.id ?? "?"} '
      'timestamp=$timestamp '
      'props=$propsSafe',
    );

    return ok({'accepted': true});
  }
}
