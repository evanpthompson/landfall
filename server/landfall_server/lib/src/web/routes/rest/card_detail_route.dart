import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../../agent/card_validator.dart';
import '../../../generated/protocol.dart';
import 'rest_helpers.dart';

/// REST handler for a single card identified by its externalId.
///
/// Path: /api/v1/cards/:id
///
/// PUT    — update an existing card's content
/// DELETE — dismiss (soft-delete) a card
class CardDetailRoute extends Route {
  CardDetailRoute() : super(methods: {Method.put, Method.delete});

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final key = await authenticateRequest(session, request);
    if (key == null) return unauthorized();

    // Extract the externalId from the last path segment: /api/v1/cards/<id>
    final segments = request.url.pathSegments;
    final externalId = segments.isNotEmpty ? segments.last : null;
    if (externalId == null || externalId.isEmpty) {
      return badRequest('Card id is required in the path.');
    }

    if (request.method == Method.delete) return _dismiss(session, externalId);
    return _update(session, request, externalId);
  }

  Future<Response> _update(
    Session session,
    Request request,
    String externalId,
  ) async {
    final existing = await CardRow.db.findFirstRow(
      session,
      where: (t) => t.externalId.equals(externalId),
    );
    if (existing == null) {
      return notFound('No card with id "$externalId".');
    }

    final body = await readJsonBody(request);
    if (body == null) {
      return badRequest('Request body must be a JSON object.');
    }

    final source = body['source'] as String? ?? existing.source;
    final title = body['title'] as String? ?? existing.title;

    final updateRequest = CardPushRequest(
      source: source,
      title: title,
      body: body.containsKey('body') ? body['body'] as String? : existing.body,
      dataJson: body.containsKey('data')
          ? (body['data'] != null ? jsonEncode(body['data']) : null)
          : existing.dataJson,
      actionsJson: body.containsKey('actions')
          ? (body['actions'] != null ? jsonEncode(body['actions']) : null)
          : existing.actionsJson,
      layout: body['layout'] as String? ?? existing.layout,
      priority: body['priority'] as String? ?? existing.priority,
      expiresAt: body.containsKey('expiresAt')
          ? (body['expiresAt'] != null
              ? DateTime.tryParse(body['expiresAt'] as String)
              : null)
          : existing.expiresAt,
      persistent: body['persistent'] as bool? ?? existing.persistent,
    );

    final errors = validateCardPushRequest(updateRequest);
    if (errors.isNotEmpty) return badRequest(errors.join(' '));

    final saved = await CardRow.db.updateRow(
      session,
      existing.copyWith(
        source: updateRequest.source,
        title: updateRequest.title,
        body: updateRequest.body,
        dataJson: updateRequest.dataJson,
        actionsJson: updateRequest.actionsJson,
        layout: updateRequest.layout!,
        priority: updateRequest.priority!,
        expiresAt: updateRequest.expiresAt,
        persistent: updateRequest.persistent!,
      ),
    );

    return ok(cardToJson(saved));
  }

  Future<Response> _dismiss(Session session, String externalId) async {
    final card = await CardRow.db.findFirstRow(
      session,
      where: (t) => t.externalId.equals(externalId),
    );
    if (card == null) {
      return notFound('No card with id "$externalId".');
    }
    await CardRow.db.updateRow(
      session,
      card.copyWith(dismissedAt: DateTime.now().toUtc()),
    );
    return noContent();
  }
}
