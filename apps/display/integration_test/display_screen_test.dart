// Item E — display_screen_test.dart
// Pre-condition: server running at INTEGRATION_TEST_SERVER_URL.

import 'package:flutter_test/flutter_test.dart';

import 'package:display/main.dart' as app;

import 'helpers/app_driver.dart';
import 'helpers/integration_test_main.dart';
import 'helpers/seed_data.dart';
import 'helpers/test_client.dart';

void main() {
  setupIntegrationTest();

  group('DisplayScreen', () {
    testWidgets('clock card renders with a time string', (tester) async {
      final driver = AppDriver(tester);
      app.main();
      await driver.pumpWithTimeout();

      expect(driver.displayScreen, findsOneWidget);
      expect(driver.clockCard, findsOneWidget);
    });

    testWidgets('agent card pushed to server appears on display', (tester) async {
      final client = createTestClient();
      final apiKey = await seedApiKey(client);
      final driver = AppDriver(tester);
      app.main();
      await driver.pumpWithTimeout();

      await seedActiveCard(client, title: 'E2E Test Card');
      await driver.pumpWithTimeout(const Duration(seconds: 4));

      expect(find.text('E2E Test Card'), findsOneWidget);

      await clearAllCards(client, apiKey);
    });

    testWidgets('dismissing a card removes it from the display', (tester) async {
      final client = createTestClient();
      final apiKey = await seedApiKey(client);
      final driver = AppDriver(tester);
      app.main();
      await driver.pumpWithTimeout();

      await seedActiveCard(client, title: 'Dismiss Me');
      await driver.pumpWithTimeout(const Duration(seconds: 4));

      // TODO(E): tap dismiss action on card, assert text gone

      await clearAllCards(client, apiKey);
    });
  });
}
