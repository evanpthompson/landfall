// ignore_for_file: avoid_print
/// Standalone example: push a card to a Landfall display.
///
/// Usage:
///   dart run example/push_card.dart
///
/// Requires LANDFALL_URL and LANDFALL_API_KEY environment variables.
library;

import 'dart:io';

import 'package:landfall_agent_sdk/landfall_agent_sdk.dart';

Future<void> main() async {
  final serverUrl = Platform.environment['LANDFALL_URL'];
  final apiKey = Platform.environment['LANDFALL_API_KEY'];

  if (serverUrl == null || apiKey == null) {
    stderr.writeln(
      'Set LANDFALL_URL and LANDFALL_API_KEY environment variables.',
    );
    exit(1);
  }

  final client = LandfallClient(serverUrl: serverUrl, apiKey: apiKey);

  try {
    // Push a ticker heartbeat so the display shows something immediately.
    await client.pushTicker(
      'Dart example running...',
      source: 'agent.dart_example',
    );
    print('Ticker pushed.');

    // Push the main card.
    final card = await client.push(
      CardDraft.build()
          .title('Hello from landfall_agent_sdk')
          .body('A Dart agent pushed this card using the official SDK.')
          .source('agent.dart_example')
          .layout(CardLayout.medium)
          .priority(CardPriority.normal)
          .cardId('agent.dart_example.hello')
          .expires(const Duration(hours: 2))(),
    );

    print('Card pushed: ${card.cardId}');
    print('  title:   ${card.title}');
    print('  source:  ${card.source}');
    print('  expires: ${card.expiresAt}');
  } on LandfallClientException catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  } finally {
    client.close();
  }
}
