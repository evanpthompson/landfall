// Item F — setup_wizard_test.dart
// Pre-condition: dev server running — RPC on http://localhost:8080/ and the
// web server (which serves /config + /auth/device/*) on http://localhost:8082/.
//
// Run with wizard mode flag — does NOT use INTEGRATION_TEST_SERVER_URL. The
// LANDFALL_WEB_SERVER_URL define mirrors the split-port dev/Pi topology so the
// wizard's hardened reachability check probes /config on the web server:
//   flutter test integration_test/setup_wizard_test.dart \
//     -d macos --dart-define=INTEGRATION_TEST_WIZARD_MODE=true \
//     --dart-define=LANDFALL_WEB_SERVER_URL=http://localhost:8082/

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:display/main.dart' as app;
import 'package:display/src/features/clock/widgets/clock_card.dart';
import 'package:display/src/features/display/screens/display_screen.dart';
import 'package:display/src/features/setup/screens/setup_wizard_screen.dart';

import 'helpers/app_driver.dart';
import 'helpers/integration_test_main.dart';

void main() {
  setupIntegrationTest();

  group('SetupWizard', () {
    testWidgets('wizard shown on first launch with no server configured',
        (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      expect(find.byType(SetupWizardScreen), findsOneWidget);
      expect(find.byType(DisplayScreen), findsNothing);
      expect(find.text('Connect to your server'), findsOneWidget);
    });

    testWidgets('step 1 — valid server URL passes connectivity check',
        (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      await tester.enterText(find.byType(TextField), 'http://localhost:8080');
      await tester.tap(find.text('Connect'));
      await driver.pumpWithTimeout(const Duration(seconds: 6));

      // Should have advanced to step 2 (location).
      expect(find.text('Where are you?'), findsOneWidget);
      expect(find.text('Connect to your server'), findsNothing);
    });

    testWidgets('step 1 — unreachable URL shows inline error', (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      await tester.enterText(
          find.byType(TextField), 'http://localhost:19999');
      await tester.tap(find.text('Connect'));
      await driver.pumpWithTimeout(const Duration(seconds: 8));

      // Should stay on step 1 with an error message.
      expect(find.text('Connect to your server'), findsOneWidget);
      expect(
        find.textContaining('Could not reach'),
        findsOneWidget,
      );
    });

    testWidgets('step 2 — enter location and advance to step 3',
        (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      // Step 1 — connect.
      await tester.enterText(find.byType(TextField), 'http://localhost:8080');
      await tester.tap(find.text('Connect'));
      await driver.pumpWithTimeout(const Duration(seconds: 6));
      expect(find.text('Where are you?'), findsOneWidget);

      // Step 2 — enter location.
      await tester.enterText(find.byType(TextField), 'Kansas City');
      await tester.tap(find.text('Save & Continue'));
      await driver.pumpWithTimeout();

      // Should be on step 3 (connect accounts).
      expect(find.text('Connect accounts'), findsOneWidget);
    });

    testWidgets('step 3 — Got it advances to done step', (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      // Step 1.
      await tester.enterText(find.byType(TextField), 'http://localhost:8080');
      await tester.tap(find.text('Connect'));
      await driver.pumpWithTimeout(const Duration(seconds: 6));

      // Step 2 — skip location.
      await tester.tap(find.text('Skip for now'));
      await driver.pumpWithTimeout();
      expect(find.text('Connect accounts'), findsOneWidget);

      // Step 3 — advance.
      await tester.tap(find.text('Got it'));
      await driver.pumpWithTimeout();

      expect(find.text("You're all set"), findsOneWidget);
    });

    testWidgets('completing wizard lands on display screen', (tester) async {
      final driver = AppDriver(tester);
      await driver.launch(app.main);

      // Walk all four steps.
      await tester.enterText(find.byType(TextField), 'http://localhost:8080');
      await tester.tap(find.text('Connect'));
      await driver.pumpWithTimeout(const Duration(seconds: 6));

      await tester.tap(find.text('Skip for now'));
      await driver.pumpWithTimeout();

      await tester.tap(find.text('Got it'));
      await driver.pumpWithTimeout();

      await tester.tap(find.text('Launch Landfall'));
      await driver.pumpWithTimeout();

      expect(find.byType(DisplayScreen), findsOneWidget);
      expect(find.byType(SetupWizardScreen), findsNothing);
      expect(find.byType(ClockCard), findsOneWidget);
    });
  });
}
