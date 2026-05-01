import 'package:flutter/material.dart' show BackButton, Key, Size;
import 'package:flutter_test/flutter_test.dart';

import 'package:display/src/features/clock/widgets/clock_card.dart';
import 'package:display/src/features/display/screens/display_screen.dart';
import 'package:display/src/features/settings/screens/settings_screen.dart';
import 'package:display/src/features/settings/widgets/layout_editor.dart';
import 'package:display/src/features/setup/screens/setup_wizard_screen.dart';
import 'package:display/src/features/ticker/widgets/ticker_strip_widget.dart';


/// Typed widget finders and action helpers for Landfall integration tests.
class AppDriver {
  const AppDriver(this.tester);

  final WidgetTester tester;

  // ---------------------------------------------------------------------------
  // Finders
  // ---------------------------------------------------------------------------

  Finder get displayScreen => find.byType(DisplayScreen);
  Finder get setupWizardScreen => find.byType(SetupWizardScreen);
  Finder get settingsScreen => find.byType(SettingsScreen);
  Finder get clockCard => find.byType(ClockCard);
  Finder get tickerStrip => find.byType(TickerStripWidget);
  Finder get layoutEditor => find.byType(LayoutEditor);

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Sets the virtual surface to 1920×1080 (the app's canonical TV size),
  /// calls [appMain] to launch the app, then waits for the display grid to
  /// be ready before returning.
  ///
  /// Uses a polling loop rather than [pumpAndSettle] for two reasons:
  ///   1. Ongoing periodic timers (1-second clock, 30-second card refresh)
  ///      prevent pumpAndSettle from ever reaching a "settled" state.
  ///   2. [DashboardProfileCubit.loadProfiles] may need to seed default
  ///      profiles on a fresh server (5+ sequential RPC calls), which takes
  ///      longer than a fixed pump window on the first run.
  ///
  /// Each iteration of the loop calls [pump(500ms)] — in integration tests
  /// this waits real calendar time — then checks whether the dashboard grid
  /// key is visible. Polls for up to 20 seconds before giving up.
  Future<void> launch(void Function() appMain) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    appMain();
    await tester.pump(); // initial build frame

    // Wait for dashboard_grid to appear (profile loads from server).
    const pollInterval = Duration(milliseconds: 500);
    const maxPolls = 40; // 40 × 500ms = 20s maximum wait
    for (var i = 0; i < maxPolls; i++) {
      await tester.pump(pollInterval);
      if (find.byKey(const Key('dashboard_grid')).evaluate().isNotEmpty) {
        // Grid is visible — wait one more interval for the first clock tick.
        await tester.pump(pollInterval);
        return;
      }
      // Wizard-mode tests: stop as soon as the setup wizard appears so we
      // don't burn the full 20-second timeout on every test.
      if (find.byType(SetupWizardScreen).evaluate().isNotEmpty) {
        return;
      }
    }
    // Timeout — return and let the test assertion report the failure.
  }

  /// Reveals the settings pill by tapping the display, then opens settings.
  ///
  /// Uses [pump] with a fixed duration rather than [pumpAndSettle] because
  /// ongoing loading animations (CircularProgressIndicator) produce frames
  /// indefinitely and prevent [pumpAndSettle] from ever settling. The 400 ms
  /// is enough to cover the 300 ms AnimatedOpacity transition on the pill.
  Future<void> openSettings() async {
    await tester.tap(find.byType(DisplayScreen));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('settings_pill')));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> navigateBack() async {
    await tester.tap(find.byType(BackButton));
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Waits for async data after an action (navigation, tap, server call).
  ///
  /// Uses [pump(Duration)] rather than [pumpAndSettle] — ongoing timers in
  /// the app prevent pumpAndSettle from ever returning on its own.
  Future<void> pumpWithTimeout([
    Duration timeout = const Duration(seconds: 3),
  ]) async {
    await tester.pump();
    await tester.pump(timeout);
  }
}
