import 'package:flutter/material.dart';
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

  /// Taps the display screen to reveal the settings pill, then opens settings.
  Future<void> openSettings() async {
    await tester.tap(find.byType(DisplayScreen));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_pill')));
    await tester.pumpAndSettle();
  }

  Future<void> navigateBack() async {
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  /// Pumps with a generous settle timeout for screens that load async data.
  Future<void> pumpWithTimeout([
    Duration timeout = const Duration(seconds: 5),
  ]) async {
    await tester.pumpAndSettle(timeout);
  }
}
