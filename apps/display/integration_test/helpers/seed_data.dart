import 'package:landfall_client/landfall_client.dart';

/// Pushes a single active card to the test server.
Future<CardRow> seedActiveCard(
  Client client, {
  String title = 'Test card',
  String source = 'system.test',
}) async {
  return client.card.pushCard(
    CardPushRequest(source: source, title: title),
  );
}

/// Pushes a card that expires in the past, making it immediately inactive.
Future<CardRow> seedExpiredCard(
  Client client, {
  String title = 'Expired card',
}) async {
  return client.card.pushCard(
    CardPushRequest(
      source: 'system.test',
      title: title,
      expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  );
}

/// Dismisses all cards visible to [apiKey] by fetching the list and dismissing each.
Future<void> clearAllCards(Client client, String apiKey) async {
  final cards = await client.agent.listCards(apiKey);
  for (final card in cards) {
    await client.agent.dismissCard(apiKey, card.externalId);
  }
}

/// Generates a fresh API key with the given name and returns the plaintext key.
Future<String> seedApiKey(Client client, {String name = 'test-key'}) async {
  final response = await client.apiKey.generateKey(name);
  return response.plainTextKey;
}
