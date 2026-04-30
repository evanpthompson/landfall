import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../../agent/api_key_service.dart';
import '../../../agent/card_validator.dart';
import '../../../generated/protocol.dart';
import 'rest_helpers.dart';

/// REST handler for the card collection.
///
/// GET  /api/v1/cards  — list all active (non-expired, non-dismissed) cards
/// POST /api/v1/cards  — push a new card (or upsert by externalId)
class CardsRoute extends Route {
  CardsRoute() : super(methods: {Method.get, Method.post});

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final key = await authenticateRequest(session, request);
    if (key == null) return unauthorized();

    if (request.method == Method.post) return _push(session, request, key);
    return _list(session);
  }

  Future<Response> _list(Session session) async {
    final now = DateTime.now().toUtc();
    final rows = await CardRow.db.find(
      session,
      where: (t) =>
          t.dismissedAt.equals(null) & t.layout.notEquals('ticker'),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );
    final active = rows.where((c) {
      if (c.persistent) return true;
      if (c.expiresAt == null) return true;
      return c.expiresAt!.isAfter(now);
    }).toList();
    return ok(active.map(cardToJson).toList());
  }

  Future<Response> _push(
    Session session,
    Request request,
    ApiKey key,
  ) async {
    final body = await readJsonBody(request);
    if (body == null) {
      return badRequest('Request body must be a JSON object.');
    }

    final source = body['source'] as String?;
    final title = body['title'] as String?;
    if (source == null || title == null) {
      return badRequest('"source" and "title" are required.');
    }

    final pushRequest = CardPushRequest(
      source: source,
      title: title,
      body: body['body'] as String?,
      dataJson: body['data'] != null ? jsonEncode(body['data']) : null,
      actionsJson: body['actions'] != null ? jsonEncode(body['actions']) : null,
      layout: body['layout'] as String?,
      priority: body['priority'] as String?,
      expiresAt: body['expiresAt'] != null
          ? DateTime.tryParse(body['expiresAt'] as String)
          : null,
      persistent: body['persistent'] as bool?,
      externalId: body['id'] as String?,
    );

    final errors = validateCardPushRequest(pushRequest);
    if (errors.isNotEmpty) return badRequest(errors.join(' '));

    try {
      await ApiKeyService.instance.checkAndIncrementRateLimit(session, key);
    } on LandfallException catch (e) {
      return rateLimitExceeded(e.message);
    }

    final now = DateTime.now().toUtc();
    final externalId = pushRequest.externalId ?? Uuid().v4();

    final existing = await CardRow.db.findFirstRow(
      session,
      where: (t) => t.externalId.equals(externalId),
    );

    final CardRow saved;
    if (existing != null) {
      saved = await CardRow.db.updateRow(
        session,
        existing.copyWith(
          source: pushRequest.source,
          title: pushRequest.title,
          body: pushRequest.body,
          dataJson: pushRequest.dataJson,
          actionsJson: pushRequest.actionsJson,
          layout: pushRequest.layout ?? existing.layout,
          priority: pushRequest.priority ?? existing.priority,
          expiresAt: pushRequest.expiresAt,
          persistent: pushRequest.persistent ?? existing.persistent,
          dismissedAt: null,
          createdAt: now,
        ),
      );
    } else {
      saved = await CardRow.db.insertRow(
        session,
        CardRow(
          externalId: externalId,
          source: pushRequest.source,
          title: pushRequest.title,
          body: pushRequest.body,
          dataJson: pushRequest.dataJson,
          actionsJson: pushRequest.actionsJson,
          layout: pushRequest.layout ?? 'medium',
          priority: pushRequest.priority ?? 'normal',
          expiresAt: pushRequest.expiresAt,
          persistent: pushRequest.persistent ?? false,
          dismissedAt: null,
          createdAt: now,
        ),
      );
    }

    return created(cardToJson(saved));
  }
}
