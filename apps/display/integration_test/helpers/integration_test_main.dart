import 'package:integration_test/integration_test.dart';

/// Call once at the top of every integration test `main()`.
void setupIntegrationTest() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
}
