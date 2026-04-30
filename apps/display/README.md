# Landfall Display

The Flutter client for Landfall — a full-screen ambient display for TV and monitor.

## Running the app

```bash
# macOS desktop
flutter run -d macos

# Connected TV / Fire TV (replace <device-id> with output of `flutter devices`)
flutter run -d <device-id>
```

---

## Integration tests

Integration tests run on **macOS desktop** (`-d macos`). The test harness
automatically starts the Landfall server before the first test and stops it
after the last, so no manual server management is required.

The server is started from `../../server/landfall_server/` relative to this
package. If something is already listening on port 8080 when the tests begin,
the harness skips startup and leaves that process alone.

### Prerequisites

- Dart SDK in `PATH` (used to start the server subprocess)
- Server dependencies installed: `cd ../../server/landfall_server && dart pub get`
- Database configured and reachable (Postgres, same as normal dev setup)

### Standard tests (items E, G, H, I)

These tests boot the app pointed at a real server and exercise full user journeys.

```bash
flutter test \
  integration_test/display_screen_test.dart \
  integration_test/settings_navigation_test.dart \
  integration_test/ticker_strip_test.dart \
  integration_test/layout_editor_test.dart \
  -d macos \
  --dart-define=INTEGRATION_TEST_SERVER_URL=http://localhost:8080/
```

### Setup wizard test (item F)

The wizard test uses an **in-memory database** so the app always starts in
fresh-install state, regardless of prior runs. The server must still be
reachable for the step-1 connectivity check.

```bash
flutter test integration_test/setup_wizard_test.dart \
  -d macos \
  --dart-define=INTEGRATION_TEST_WIZARD_MODE=true
```

### Running all tests at once

Standard tests and the wizard test use different `--dart-define` flags and
cannot be combined into a single invocation. Run them sequentially:

```bash
flutter test \
  integration_test/display_screen_test.dart \
  integration_test/settings_navigation_test.dart \
  integration_test/ticker_strip_test.dart \
  integration_test/layout_editor_test.dart \
  -d macos \
  --dart-define=INTEGRATION_TEST_SERVER_URL=http://localhost:8080/

flutter test integration_test/setup_wizard_test.dart \
  -d macos \
  --dart-define=INTEGRATION_TEST_WIZARD_MODE=true
```

### How the server startup works

`integration_test/helpers/server_manager.dart` handles the lifecycle:

1. Checks whether port 8080 is already accepting connections.
2. If not, runs `dart run bin/main.dart --apply-migrations` from the server
   directory and polls every 500 ms until the port is ready (30 s timeout).
3. On `tearDownAll`, kills only the process it started — an externally started
   server is left running.

### Test inventory

| File | What it covers |
|---|---|
| `display_screen_test.dart` | Clock display, agent card appearance and dismiss, grid layout |
| `setup_wizard_test.dart` | First-run wizard: server connect, location, accounts, completion |
| `settings_navigation_test.dart` | Settings pill, tab navigation, back to display |
| `ticker_strip_test.dart` | Empty strip invisible, ticker push appears, TTL expiry |
| `layout_editor_test.dart` | Editor opens, card tiles, hidden indicator, visibility toggle, persistence |
