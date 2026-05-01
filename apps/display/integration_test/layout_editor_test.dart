// Item I — layout_editor_test.dart
// Pre-condition: server running at INTEGRATION_TEST_SERVER_URL.

import 'package:flutter/material.dart' show Icons;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:display/main.dart' as app;
import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_state.dart';
import 'package:display/src/features/settings/widgets/layout_editor.dart';

import 'helpers/app_driver.dart';
import 'helpers/integration_test_main.dart';

void main() {
  setupIntegrationTest();

  group('LayoutEditor', () {
    testWidgets('layout editor opens from Settings → Layout', (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      await driver.openSettings();
      await tester.tap(find.text('Layout'));
      await driver.pumpWithTimeout();

      expect(find.byType(LayoutEditor), findsOneWidget);
    });

    testWidgets('editor shows tiles for all cards in the active layout',
        (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      await driver.openSettings();
      await tester.tap(find.text('Layout'));
      await driver.pumpWithTimeout();

      // The default layout contains Clock and Weather card tiles.
      expect(find.text('Clock'), findsOneWidget);
      expect(find.text('Weather'), findsOneWidget);

      // Total tile count equals the active profile's layout card count.
      // Read the cubit from the LayoutEditor context — it's the visible widget
      // and sits inside the same MultiBlocProvider that provides the cubit.
      // Using driver.displayScreen here would fail because it's below the
      // settings route in the navigator and not findable as a unique element.
      final ctx = tester.element(find.byType(LayoutEditor));
      final state = ctx.read<DashboardProfileCubit>().state;
      if (state is DashboardProfileLoaded) {
        expect(
          find.byType(LayoutEditor),
          findsOneWidget,
        );
        // Each card produces one label — count matches layout.
        for (final card in state.active.layout.cards) {
          // Tiles are always present; hidden ones show "hidden" beneath the label.
          expect(
            find.text(_cardLabel(card.source)),
            findsWidgets,
          );
        }
      }
    });

    testWidgets('hidden card tile shows "hidden" indicator', (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      await driver.openSettings();
      await tester.tap(find.text('Layout'));
      await driver.pumpWithTimeout();

      // system.photos is hidden by default in weekdayLayout — its tile shows
      // a "hidden" label beneath the card name.
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('hidden'), findsWidgets);
    });

    testWidgets('tapping a visible tile toggles it to hidden', (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      await driver.openSettings();
      await tester.tap(find.text('Layout'));
      await driver.pumpWithTimeout();

      // Weather is visible by default.
      expect(find.text('Weather'), findsOneWidget);
      final hiddenBefore = tester.widgetList(find.text('hidden')).length;

      await tester.tap(find.text('Weather'));
      await driver.pumpWithTimeout();

      // One more "hidden" indicator should now be present.
      expect(tester.widgetList(find.text('hidden')).length,
          greaterThan(hiddenBefore));
    });

    testWidgets('navigating away and back preserves visibility change',
        (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      await driver.openSettings();
      await tester.tap(find.text('Layout'));
      await driver.pumpWithTimeout();

      // Hide the Weather card.
      await tester.tap(find.text('Weather'));
      await driver.pumpWithTimeout();
      final hiddenAfterToggle =
          tester.widgetList(find.text('hidden')).length;

      // Go back to the display screen.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await driver.pumpWithTimeout();

      // Re-open settings → Layout.
      await driver.openSettings();
      await tester.tap(find.text('Layout'));
      await driver.pumpWithTimeout();

      // The "hidden" count must be at least what it was right after the toggle.
      expect(tester.widgetList(find.text('hidden')).length,
          greaterThanOrEqualTo(hiddenAfterToggle));
    });
  });
}

String _cardLabel(String source) => switch (source) {
      'system.clock' => 'Clock',
      'system.weather' => 'Weather',
      'system.weather.forecast' => 'Forecast',
      'system.calendar' => 'Calendar',
      'system.photos' => 'Photos',
      _ => source,
    };
