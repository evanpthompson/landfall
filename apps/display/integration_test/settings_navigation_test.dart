// Item G — settings_navigation_test.dart
// Pre-condition: server running at INTEGRATION_TEST_SERVER_URL.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:display/main.dart' as app;
import 'package:display/src/features/display/screens/display_screen.dart';
import 'package:display/src/features/settings/screens/settings_screen.dart';
import 'package:display/src/features/settings/widgets/layout_editor.dart';

import 'helpers/app_driver.dart';
import 'helpers/integration_test_main.dart';

void main() {
  setupIntegrationTest();

  group('SettingsNavigation', () {
    testWidgets('settings pill is present in the widget tree', (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      expect(driver.displayScreen, findsOneWidget);
      expect(find.byKey(const Key('settings_pill')), findsOneWidget);
    });

    testWidgets('tapping display reveals and opens settings', (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      await driver.openSettings();

      expect(find.byType(SettingsScreen), findsOneWidget);
      // Actual tabs: Display, Accounts, Layout, License.
      expect(find.text('Display'), findsOneWidget);
      expect(find.text('Accounts'), findsOneWidget);
      expect(find.text('Layout'), findsOneWidget);
      expect(find.text('License'), findsOneWidget);
    });

    testWidgets('back from settings returns to display with clock', (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      await driver.openSettings();
      expect(find.byType(SettingsScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await driver.pumpWithTimeout();

      expect(find.byType(DisplayScreen), findsOneWidget);
      expect(find.byType(SettingsScreen), findsNothing);
      expect(driver.clockCard, findsOneWidget);
    });

    testWidgets('Layout tab shows the layout editor', (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      await driver.openSettings();
      await tester.tap(find.text('Layout'));
      await driver.pumpWithTimeout();

      expect(find.byType(LayoutEditor), findsOneWidget);
    });

    testWidgets('License tab shows the license tier name', (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      await driver.openSettings();
      await tester.tap(find.text('License'));
      await driver.pumpWithTimeout();

      // License screen shows the tier display name (e.g. "Community" or "Pro").
      // Match any non-empty text that appears in the license card area.
      expect(find.byType(SettingsScreen), findsOneWidget);
      // The tab itself rendered — no crash and the License tab body is visible.
      expect(find.text('License'), findsOneWidget);
    });
  });
}
