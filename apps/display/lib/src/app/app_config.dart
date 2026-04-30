/// Compile-time server URL injected via `--dart-define`.
///
/// When non-empty, the app skips the setup wizard and boots directly to
/// [DisplayScreen] using this URL. Set by integration tests:
///
/// ```
/// flutter test integration_test/ \
///   --dart-define=INTEGRATION_TEST_SERVER_URL=http://localhost:8080/
/// ```
const kIntegrationTestServerUrl = String.fromEnvironment(
  'INTEGRATION_TEST_SERVER_URL',
  defaultValue: '',
);

/// Set to `true` to run the setup wizard against an in-memory database.
///
/// Guarantees a fresh-install state (no persisted server URL) and bypasses
/// auth after the wizard completes. Used by wizard integration tests:
///
/// ```
/// flutter test integration_test/setup_wizard_test.dart \
///   --dart-define=INTEGRATION_TEST_WIZARD_MODE=true
/// ```
const kIntegrationTestWizardMode = bool.fromEnvironment(
  'INTEGRATION_TEST_WIZARD_MODE',
  defaultValue: false,
);
