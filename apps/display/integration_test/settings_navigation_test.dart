// Item G — settings_navigation_test.dart
// Pre-condition: server running at INTEGRATION_TEST_SERVER_URL.

import 'package:flutter_test/flutter_test.dart';

import 'package:display/main.dart' as app;

import 'helpers/app_driver.dart';
import 'helpers/integration_test_main.dart';

void main() {
  setupIntegrationTest();

  group('SettingsNavigation', () {
    testWidgets('opens settings screen from display', (tester) async {
      final driver = AppDriver(tester);
      app.main();
      await driver.pumpWithTimeout();

      // TODO(G): implement — tap settings pill, assert SettingsScreen visible
    });

    testWidgets('back button returns to display screen', (tester) async {
      final driver = AppDriver(tester);
      app.main();
      await driver.pumpWithTimeout();

      // TODO(G): implement — open settings, navigate back, assert DisplayScreen
    });
  });
}
