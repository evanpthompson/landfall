// Item H — ticker_strip_test.dart
// Pre-condition: server running at INTEGRATION_TEST_SERVER_URL.

import 'package:flutter_test/flutter_test.dart';

import 'package:display/main.dart' as app;

import 'helpers/app_driver.dart';
import 'helpers/integration_test_main.dart';
import 'helpers/seed_data.dart';
import 'helpers/test_client.dart';

void main() {
  setupIntegrationTest();

  group('TickerStrip', () {
    testWidgets('ticker message pushed to server scrolls across strip', (tester) async {
      final client = createTestClient();
      final apiKey = await seedApiKey(client);
      final driver = AppDriver(tester);
      app.main();
      await driver.pumpWithTimeout();

      // TODO(H): push ticker card, assert TickerStripWidget visible and scrolling

      await clearAllCards(client, apiKey);
    });
  });
}
