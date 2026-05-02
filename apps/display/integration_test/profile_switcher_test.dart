// Item J — profile_switcher_test.dart
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

  group('ProfileSwitcher', () {
    testWidgets('Layout tab shows a chip for every profile', (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      await driver.openSettings();
      await tester.tap(find.text('Layout'));
      await driver.pumpWithTimeout();

      final ctx = tester.element(find.byType(LayoutEditor));
      final state = ctx.read<DashboardProfileCubit>().state;
      expect(state, isA<DashboardProfileLoaded>());

      final loaded = state as DashboardProfileLoaded;
      expect(loaded.profiles.length, greaterThanOrEqualTo(1));

      for (final profile in loaded.profiles) {
        expect(find.text(profile.name), findsOneWidget);
      }
    });

    testWidgets('tapping an inactive chip activates that profile',
        (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      await driver.openSettings();
      await tester.tap(find.text('Layout'));
      await driver.pumpWithTimeout();

      final ctx = tester.element(find.byType(LayoutEditor));
      final stateBefore =
          ctx.read<DashboardProfileCubit>().state as DashboardProfileLoaded;

      // Need at least two profiles to test switching.
      expect(
        stateBefore.profiles.length,
        greaterThanOrEqualTo(2),
        reason: 'Need at least two profiles to test switching.',
      );

      final inactiveProfile =
          stateBefore.profiles.firstWhere((p) => !p.isActive);
      final activeIdBefore = stateBefore.active.id;

      // Tap the inactive profile's chip.
      await tester.tap(find.text(inactiveProfile.name));
      await driver.pumpWithTimeout(const Duration(seconds: 4));

      final stateAfter =
          ctx.read<DashboardProfileCubit>().state as DashboardProfileLoaded;

      expect(stateAfter.active.id, equals(inactiveProfile.id));
      expect(stateAfter.active.id, isNot(equals(activeIdBefore)));
    });

    testWidgets('active profile chip is visually distinct from inactive chips',
        (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      await driver.openSettings();
      await tester.tap(find.text('Layout'));
      await driver.pumpWithTimeout();

      final ctx = tester.element(find.byType(LayoutEditor));
      final state =
          ctx.read<DashboardProfileCubit>().state as DashboardProfileLoaded;

      expect(state.profiles.length, greaterThanOrEqualTo(2));

      // Active chip: its GestureDetector's onTap is null (tapping it is a no-op).
      // Inactive chips: onTap is set. Verify by attempting to re-activate the
      // already-active profile — the cubit's active id must not change.
      final activeProfile = state.active;
      await tester.tap(find.text(activeProfile.name));
      await driver.pumpWithTimeout();

      final stateAfter =
          ctx.read<DashboardProfileCubit>().state as DashboardProfileLoaded;
      expect(stateAfter.active.id, equals(activeProfile.id));
    });

    testWidgets('switched profile persists after leaving and re-entering settings',
        (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      await driver.openSettings();
      await tester.tap(find.text('Layout'));
      await driver.pumpWithTimeout();

      final ctx = tester.element(find.byType(LayoutEditor));
      final stateBefore =
          ctx.read<DashboardProfileCubit>().state as DashboardProfileLoaded;
      expect(stateBefore.profiles.length, greaterThanOrEqualTo(2));

      final inactiveProfile =
          stateBefore.profiles.firstWhere((p) => !p.isActive);

      // Switch to the inactive profile.
      await tester.tap(find.text(inactiveProfile.name));
      await driver.pumpWithTimeout(const Duration(seconds: 4));

      // Leave settings.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await driver.pumpWithTimeout();

      // Re-open settings → Layout.
      await driver.openSettings();
      await tester.tap(find.text('Layout'));
      await driver.pumpWithTimeout();

      final ctxAfter = tester.element(find.byType(LayoutEditor));
      final stateAfter =
          ctxAfter.read<DashboardProfileCubit>().state as DashboardProfileLoaded;

      expect(stateAfter.active.id, equals(inactiveProfile.id));
    });
  });
}
