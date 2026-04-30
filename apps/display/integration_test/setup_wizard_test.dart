// Item F — setup_wizard_test.dart
// Pre-condition: server running at INTEGRATION_TEST_SERVER_URL.

import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_driver.dart';
import 'helpers/integration_test_main.dart';

void main() {
  setupIntegrationTest();

  group('SetupWizard', () {
    testWidgets(
      'wizard is bypassed when INTEGRATION_TEST_SERVER_URL is set',
      (tester) async {
        // TODO(F): implement
        final driver = AppDriver(tester);
        expect(driver.setupWizardScreen, findsNothing);
      },
    );
  });
}
