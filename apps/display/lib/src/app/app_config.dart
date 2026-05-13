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

/// Production default server URL injected via `--dart-define`.
///
/// The Raspberry Pi all-in-one image sets this to the local Serverpod backend
/// so the appliance boots past the setup wizard without asking for a server
/// address. Fire TV and generic Android builds leave it empty so users can
/// enter their self-hosted server URL on first launch.
const kLandfallDefaultServerUrl = String.fromEnvironment(
  'LANDFALL_DEFAULT_SERVER_URL',
  defaultValue: '',
);

/// Override for the Serverpod web server URL (port 8082 in direct-connect
/// setups). Defaults to [kLandfallDefaultServerUrl] so reverse-proxy
/// deployments (Caddy) need only set [kLandfallDefaultServerUrl].
///
/// Set this on Pi dev builds where the Flutter app talks directly to
/// Serverpod ports:
/// ```
/// flutter run --dart-define=LANDFALL_WEB_SERVER_URL=http://127.0.0.1:8082/
/// ```
const kLandfallWebServerUrl = String.fromEnvironment(
  'LANDFALL_WEB_SERVER_URL',
  defaultValue: '',
);

/// Telemetry endpoint URL injected via `--dart-define`.
///
/// **DEV BUILDS ONLY.** When empty (the default — and the value used by every
/// production build path: Pi appliance image, Fire TV APK, macOS dmg) the
/// [Telemetry] class is a no-op and emits zero network traffic. When set,
/// the display POSTs JSON-encoded events here. Self-hosted only — point at
/// your own Landfall server's `/api/v1/telemetry/event` endpoint:
///
/// ```
/// flutter build linux --release \
///   --dart-define=LANDFALL_TELEMETRY_ENDPOINT=http://192.168.1.42:8080/api/v1/telemetry/event \
///   --dart-define=LANDFALL_TELEMETRY_API_KEY=lf_dev_xxxxx
/// ```
const kLandfallTelemetryEndpoint = String.fromEnvironment(
  'LANDFALL_TELEMETRY_ENDPOINT',
  defaultValue: '',
);

/// API key used to authenticate telemetry POSTs against the self-hosted
/// server. Required alongside [kLandfallTelemetryEndpoint] — the route uses
/// the same `authenticateRequest` flow as the rest of `/api/v1/*`.
const kLandfallTelemetryApiKey = String.fromEnvironment(
  'LANDFALL_TELEMETRY_API_KEY',
  defaultValue: '',
);
