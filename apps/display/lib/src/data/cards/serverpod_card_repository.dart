import 'dart:convert';

import 'package:landfall_client/landfall_client.dart';
import 'package:landfall_shared/landfall_shared.dart';

/// Production [CardRepository] backed by the Serverpod RPC endpoint.
///
/// Converts [CardRow] (Serverpod wire model) to [Card] (domain model).
/// The [CardRow.externalId] maps to [Card.id] — this is the stable agent-facing
/// identifier used for in-place updates.
class ServerpodCardRepository implements CardRepository {
  const ServerpodCardRepository(this._client);

  final Client _client;

  @override
  Future<List<Card>> getActiveCards() async {
    final rows = await _client.card.getCards();
    return rows.map(_rowToCard).toList();
  }

  @override
  Future<bool> dismissCard(String cardId) async {
    return _client.card.dismissCard(cardId);
  }

  @override
  Future<List<Card>> getTickerMessages() async {
    final rows = await _client.card.getTickerMessages();
    return rows.map(_rowToCard).toList();
  }

  static Card _rowToCard(CardRow row) {
    Map<String, dynamic>? data;
    if (row.dataJson != null) {
      data = jsonDecode(row.dataJson!) as Map<String, dynamic>;
    }

    List<CardAction>? actions;
    if (row.actionsJson != null) {
      final decoded = jsonDecode(row.actionsJson!) as List<dynamic>;
      actions = decoded
          .map((e) => CardAction.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Card(
      id: row.externalId,
      source: row.source,
      title: row.title,
      body: row.body,
      data: data,
      actions: actions,
      layout: CardLayout.values.byName(row.layout),
      priority: CardPriority.values.byName(row.priority),
      expiresAt: row.expiresAt,
      persistent: row.persistent,
      createdAt: row.createdAt,
      dismissedAt: row.dismissedAt,
    );
  }
}
