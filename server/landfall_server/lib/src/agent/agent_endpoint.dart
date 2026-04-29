import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'api_key_service.dart';
import 'card_validator.dart';

/// The authenticated agent push API.
///
/// All methods require [apiKey] — a valid plaintext API key generated via
/// [ApiKeyEndpoint.generateKey]. Rate limit: 500 pushCard calls per day
/// per key (configurable per key).
class AgentEndpoint extends Endpoint {
  final _keyService = ApiKeyService.instance;

  /// Returns all active (non-dismissed, non-expired) grid cards.
  ///
  /// Ticker-layout cards are excluded — they are presence signals, not content.
  /// Cards are returned newest-first.
  Future<List<CardRow>> listCards(Session session, String apiKey) async {
    await _keyService.authenticate(session, apiKey);
    final now = DateTime.now().toUtc();

    final nonDismissed = await CardRow.db.find(
      session,
      where: (t) =>
          t.dismissedAt.equals(null) & t.layout.notEquals('ticker'),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );

    return nonDismissed.where((card) {
      if (card.persistent) return true;
      if (card.expiresAt == null) return true;
      return card.expiresAt!.isAfter(now);
    }).toList();
  }

  /// Pushes a card to the display.
  ///
  /// If [CardPushRequest.externalId] is provided and a card with that ID
  /// already exists, the existing card is updated in-place. Otherwise a
  /// new card is created with a generated UUID.
  ///
  /// Returns the created or updated [CardRow].
  Future<CardRow> pushCard(
    Session session,
    String apiKey,
    CardPushRequest request,
  ) async {
    final key = await _keyService.authenticate(session, apiKey);
    await _keyService.checkAndIncrementRateLimit(session, key);

    final errors = validateCardPushRequest(request);
    if (errors.isNotEmpty) {
      throw LandfallException(
        message: 'Invalid card payload: ${errors.join(' ')}',
      );
    }

    final now = DateTime.now().toUtc();
    final externalId = request.externalId ?? Uuid().v4();

    final existing = await CardRow.db.findFirstRow(
      session,
      where: (t) => t.externalId.equals(externalId),
    );

    if (existing != null) {
      final updated = existing.copyWith(
        source: request.source,
        title: request.title,
        body: request.body,
        dataJson: request.dataJson,
        actionsJson: request.actionsJson,
        layout: request.layout ?? existing.layout,
        priority: request.priority ?? existing.priority,
        expiresAt: request.expiresAt,
        persistent: request.persistent ?? existing.persistent,
        dismissedAt: null, // Re-pushing un-dismisses.
        createdAt: now, // Reset so TTL starts fresh.
      );
      return CardRow.db.updateRow(session, updated);
    }

    final card = CardRow(
      externalId: externalId,
      source: request.source,
      title: request.title,
      body: request.body,
      dataJson: request.dataJson,
      actionsJson: request.actionsJson,
      layout: request.layout ?? 'medium',
      priority: request.priority ?? 'normal',
      expiresAt: request.expiresAt,
      persistent: request.persistent ?? false,
      dismissedAt: null,
      createdAt: now,
    );

    return CardRow.db.insertRow(session, card);
  }

  /// Updates an existing card by [externalId].
  ///
  /// Title and source in [request] replace the existing values.
  /// Returns the updated [CardRow], or throws if no card with that
  /// [externalId] exists.
  Future<CardRow> updateCard(
    Session session,
    String apiKey,
    String externalId,
    CardPushRequest request,
  ) async {
    await _keyService.authenticate(session, apiKey);

    final errors = validateCardPushRequest(request);
    if (errors.isNotEmpty) {
      throw LandfallException(
        message: 'Invalid card payload: ${errors.join(' ')}',
      );
    }

    final existing = await CardRow.db.findFirstRow(
      session,
      where: (t) => t.externalId.equals(externalId),
    );

    if (existing == null) {
      throw LandfallException(
        message: 'No card found with externalId "$externalId".',
      );
    }

    final updated = existing.copyWith(
      source: request.source,
      title: request.title,
      body: request.body,
      dataJson: request.dataJson,
      actionsJson: request.actionsJson,
      layout: request.layout ?? existing.layout,
      priority: request.priority ?? existing.priority,
      expiresAt: request.expiresAt,
      persistent: request.persistent ?? existing.persistent,
    );

    return CardRow.db.updateRow(session, updated);
  }

  /// Pushes a ticker heartbeat message to the ghost ticker strip.
  ///
  /// Convenience wrapper for [pushCard] with [layout: 'ticker'] and a
  /// default TTL of 30 seconds. [message] maps to the card title.
  /// [expiresAt] overrides the default TTL.
  Future<CardRow> pushTicker(
    Session session,
    String apiKey,
    String source,
    String message, {
    DateTime? expiresAt,
  }) async {
    final key = await _keyService.authenticate(session, apiKey);
    await _keyService.checkAndIncrementRateLimit(session, key);

    final now = DateTime.now().toUtc();
    final ttlExpiry = expiresAt ?? now.add(const Duration(seconds: 30));

    final card = CardRow(
      externalId: Uuid().v4(),
      source: source,
      title: message,
      layout: 'ticker',
      priority: 'ephemeral',
      expiresAt: ttlExpiry,
      persistent: false,
      dismissedAt: null,
      createdAt: now,
    );

    return CardRow.db.insertRow(session, card);
  }

  /// Dismisses a card by its [externalId].
  ///
  /// Sets [CardRow.dismissedAt] to now. The card is retained in the database
  /// for history queries. Returns true if a card was found and dismissed,
  /// false if no card with that externalId exists.
  Future<bool> dismissCard(
    Session session,
    String apiKey,
    String externalId,
  ) async {
    await _keyService.authenticate(session, apiKey);

    final card = await CardRow.db.findFirstRow(
      session,
      where: (t) => t.externalId.equals(externalId),
    );

    if (card == null) return false;

    await CardRow.db.updateRow(
      session,
      card.copyWith(dismissedAt: DateTime.now().toUtc()),
    );
    return true;
  }
}
