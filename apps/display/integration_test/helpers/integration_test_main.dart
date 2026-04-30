import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'server_manager.dart';

/// Call once at the top of every integration test `main()`.
///
/// Registers [setUpAll]/[tearDownAll] hooks that start the Landfall server
/// before the first test and stop it (if we started it) after the last.
/// If the server is already running on port 8080, startup is skipped.
void setupIntegrationTest() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await startServer();
  });

  tearDownAll(() async {
    await stopServer();
  });
}
