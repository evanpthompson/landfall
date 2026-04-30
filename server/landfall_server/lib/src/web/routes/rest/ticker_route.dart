import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../../../agent/api_key_service.dart';
import '../../../generated/protocol.dart';
import 'rest_helpers.dart';

/// REST handler for ticker messages.
///
/// POST /api/v1/ticker  — push an ephemeral message to the ghost ticker strip
///
/// Request body:
/// ```json
/// {
///   "source": "agent.ci",
///   "message": "Deploy succeeded",
///   "expiresAt": "2026-04-30T10:00:00Z"   // optional, default 30s TTL
/// }
/// ```
class TickerRoute extends Route {
  TickerRoute() : super(methods: {Method.post});

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final key = await authenticateRequest(session, request);
    if (key == null) return unauthorized();

    final body = await readJsonBody(request);
    if (body == null) {
      return badRequest('Request body must be a JSON object.');
    }

    final source = body['source'] as String?;
    final message = body['message'] as String?;
    if (source == null || message == null) {
      return badRequest('"source" and "message" are required.');
    }

    final expiresAt = body['expiresAt'] != null
        ? DateTime.tryParse(body['expiresAt'] as String)
        : null;

    try {
      await ApiKeyService.instance.checkAndIncrementRateLimit(session, key);
    } on LandfallException catch (e) {
      return rateLimitExceeded(e.message);
    }

    final now = DateTime.now().toUtc();
    final card = await CardRow.db.insertRow(
      session,
      CardRow(
        externalId: Uuid().v4(),
        source: source,
        title: message,
        layout: 'ticker',
        priority: 'ephemeral',
        expiresAt: expiresAt ?? now.add(const Duration(seconds: 30)),
        persistent: false,
        dismissedAt: null,
        createdAt: now,
      ),
    );

    return created(cardToJson(card));
  }
}
