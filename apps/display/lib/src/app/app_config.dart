/// Compile-time server URL injected via `--dart-define`.
///
/// When non-empty, the app skips the setup wizard and boots directly to
/// [DisplayScreen] using this URL. Set by integration tests:
///
/// ```
/// flutter test integration_test/ \
///   --dart-define=INTEGRATION_TEST_SERVER_URL=http://localhost:8080
/// ```
const kIntegrationTestServerUrl = String.fromEnvironment(
  'INTEGRATION_TEST_SERVER_URL',
  defaultValue: '',
);
