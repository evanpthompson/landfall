// Item E — display_screen_test.dart
// Pre-condition: server running at INTEGRATION_TEST_SERVER_URL.
//
// Start the server with:
//   cd server/landfall_server && dart run bin/main.dart --apply-migrations

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:display/main.dart' as app;
import 'package:display/src/features/cards/cubit/card_cubit.dart';
import 'package:display/src/features/display/screens/display_screen.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_state.dart';

import 'helpers/app_driver.dart';
import 'helpers/integration_test_main.dart';
import 'helpers/seed_data.dart';
import 'helpers/test_client.dart';

void main() {
  setupIntegrationTest();

  group('DisplayScreen', () {
    testWidgets('clock card renders with a time string', (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      expect(driver.displayScreen, findsOneWidget);
      expect(driver.clockCard, findsOneWidget);

      // Verify a HH:MM time string is visible somewhere inside the clock card.
      final hhmmPattern = RegExp(r'^\d{2}:\d{2}$');
      Iterable<Text> clockTexts() => tester
          .widgetList<Text>(
            find.descendant(of: driver.clockCard, matching: find.byType(Text)),
          )
          .where((t) => hhmmPattern.hasMatch(t.data ?? ''));

      final initialTexts = clockTexts().toList();
      expect(initialTexts, isNotEmpty, reason: 'Expected HH:MM text inside ClockCard');

      // Pump 2 seconds — the clock ticks every second, so the time should update.
      await tester.pump(const Duration(seconds: 2));
      final updatedTexts = clockTexts().toList();
      // Time may or may not have ticked over a minute boundary — we just
      // verify the widget is still showing a valid HH:MM string.
      expect(updatedTexts, isNotEmpty);
    });

    testWidgets('agent card pushed to server appears on display', (tester) async {
      final client = createTestClient();
      final apiKey = await seedApiKey(client);

      // Use a unique title so leftover cards from previous test runs (pushed
      // with different API keys) don't cause findsOneWidget to see extras.
      final uniqueTitle = 'E2E Test Card ${DateTime.now().millisecondsSinceEpoch}';

      final driver = AppDriver(tester);
      await driver.launch(app.main);

      await seedActiveCard(client, title: uniqueTitle);

      // Manually trigger the card refresh — the display polls every 30 s,
      // which is too long to wait in a test.
      final ctx = tester.element(find.byType(DisplayScreen));
      await ctx.read<CardCubit>().fetchCards();
      await driver.pumpWithTimeout();

      expect(find.text(uniqueTitle), findsOneWidget);

      await clearAllCards(client, apiKey);
    });

    testWidgets('dismissing a card removes it from the display', (tester) async {
      final client = createTestClient();
      final apiKey = await seedApiKey(client);

      final driver = AppDriver(tester);
      await driver.launch(app.main);

      await seedCardWithDismissAction(client, title: 'Dismiss Me');

      final ctx = tester.element(find.byType(DisplayScreen));
      await ctx.read<CardCubit>().fetchCards();
      await driver.pumpWithTimeout();

      expect(find.text('Dismiss Me'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);

      await tester.tap(find.text('Dismiss'));
      await driver.pumpWithTimeout();

      expect(find.text('Dismiss Me'), findsNothing);

      await clearAllCards(client, apiKey);
    });

    testWidgets('layout grid renders with default 12 columns', (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      expect(find.byKey(const Key('dashboard_grid')), findsOneWidget);

      final ctx = tester.element(find.byType(DisplayScreen));
      final profileState = ctx.read<DashboardProfileCubit>().state;
      expect(profileState, isA<DashboardProfileLoaded>());
      final columns = (profileState as DashboardProfileLoaded).active.layout.columns;
      expect(columns, 12);
    });
  });
}
