// Item H — ticker_strip_test.dart
// Pre-condition: server running at INTEGRATION_TEST_SERVER_URL.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:display/main.dart' as app;
import 'package:display/src/features/ticker/cubit/ticker_cubit.dart';

import 'helpers/app_driver.dart';
import 'helpers/integration_test_main.dart';
import 'helpers/seed_data.dart';
import 'helpers/test_client.dart';

void main() {
  setupIntegrationTest();

  group('TickerStrip', () {
    testWidgets('ticker strip is not visible when buffer is empty',
        (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      // With no ticker cards seeded the strip collapses to SizedBox.shrink().
      expect(driver.tickerStrip, findsOneWidget);
      final renderBox = tester.renderObject(driver.tickerStrip);
      expect(renderBox.paintBounds.isEmpty, isTrue);
    });

    testWidgets('ticker message appears after server push', (tester) async {
      final client = createTestClient();
      final apiKey = await seedApiKey(client);
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      await client.agent.pushTicker(
        apiKey,
        'system.test',
        'Breaking news from the test suite',
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );

      // Bypass the 15-second poll timer by driving the cubit directly.
      final ctx = tester.element(driver.displayScreen);
      await ctx.read<TickerCubit>().loadTicker();
      await driver.pumpWithTimeout();

      expect(
        find.text('Breaking news from the test suite'),
        findsOneWidget,
      );

      await clearAllCards(client, apiKey);
    });

    testWidgets('ticker strip disappears after TTL expires', (tester) async {
      final client = createTestClient();
      final apiKey = await seedApiKey(client);
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      await client.agent.pushTicker(
        apiKey,
        'system.test',
        'Short-lived ticker',
        expiresAt: DateTime.now().add(const Duration(seconds: 2)),
      );

      final ctx = tester.element(driver.displayScreen);
      await ctx.read<TickerCubit>().loadTicker();
      await driver.pumpWithTimeout();

      expect(find.text('Short-lived ticker'), findsOneWidget);

      // Wait for the TTL to elapse then poll again.
      await tester.pump(const Duration(seconds: 3));
      await ctx.read<TickerCubit>().loadTicker();
      await driver.pumpWithTimeout();

      final renderBox = tester.renderObject(driver.tickerStrip);
      expect(renderBox.paintBounds.isEmpty, isTrue);

      await clearAllCards(client, apiKey);
    });
  });
}
