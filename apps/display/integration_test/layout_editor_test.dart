// Item I — layout_editor_test.dart
// Pre-condition: server running at INTEGRATION_TEST_SERVER_URL.

import 'package:flutter_test/flutter_test.dart';

import 'package:display/main.dart' as app;

import 'helpers/app_driver.dart';
import 'helpers/integration_test_main.dart';

void main() {
  setupIntegrationTest();

  group('LayoutEditor', () {
    testWidgets('layout editor opens from settings screen', (tester) async {
      final driver = AppDriver(tester);
      app.main();
      await driver.pumpWithTimeout();

      // TODO(I): open settings, tap layout editor, assert LayoutEditor visible
    });

    testWidgets('dragging a card persists the layout', (tester) async {
      final driver = AppDriver(tester);
      app.main();
      await driver.pumpWithTimeout();

      // TODO(I): drag card to new position, close editor, reopen, assert position
    });
  });
}
