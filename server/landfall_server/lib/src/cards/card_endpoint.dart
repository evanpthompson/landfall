import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Endpoint for card management.
///
/// [getCards] and [getTickerMessages] are read-only and may be called by the
/// local display without a session. [pushCard] and [dismissCard] mutate state
/// and require an authenticated session (SEC-01).
class CardEndpoint extends Endpoint {
  /// Returns all active grid cards for the display.
  ///
  /// Active = not dismissed AND (persistent OR not yet expired).
  /// Ticker-layout cards are excluded — use [getTickerMessages] for those.
  /// Cards are returned newest-first.
  Future<List<CardRow>> getCards(Session session) async {
    final now = DateTime.now().toUtc();

    final nonDismissed = await CardRow.db.find(
      session,
      where: (t) => t.dismissedAt.equals(null) & t.layout.notEquals('ticker'),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );

    return nonDismissed.where((card) {
      if (card.persistent) return true;
      if (card.expiresAt == null) return true;
      return card.expiresAt!.isAfter(now);
    }).toList();
  }

  /// Returns the current ticker buffer: non-expired ticker-layout cards,
  /// newest first, capped at 10 entries.
  Future<List<CardRow>> getTickerMessages(Session session) async {
    final now = DateTime.now().toUtc();

    final rows = await CardRow.db.find(
      session,
      where: (t) => t.layout.equals('ticker') & t.dismissedAt.equals(null),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: 10,
    );

    return rows.where((card) {
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
    CardPushRequest request,
  ) async {
    if (session.authenticated == null) {
      throw LandfallException(message: 'Authentication required.');
    }
    final now = DateTime.now().toUtc();
    final externalId = request.externalId ?? Uuid().v4();

    // Check for an existing card with this externalId.
    final existing = await CardRow.db.findFirstRow(
      session,
      where: (t) => t.externalId.equals(externalId),
    );

    if (existing != null) {
      // Update in-place.
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
        dismissedAt: null, // Re-pushing un-dismisses the card.
        createdAt: now,    // Reset createdAt so TTL starts fresh.
      );
      return CardRow.db.updateRow(session, updated);
    }

    // Create new card.
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

  /// Dismisses a card by its [externalId].
  ///
  /// Sets [CardRow.dismissedAt] to now. The card is retained in the database
  /// for history queries. Returns true if a card was found and dismissed,
  /// false if no card with that externalId exists.
  Future<bool> dismissCard(Session session, String externalId) async {
    if (session.authenticated == null) {
      throw LandfallException(message: 'Authentication required.');
    }
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
