# Integration Tests

Integration tests run on **macOS desktop** (`-d macos`). The test harness
automatically starts the Landfall server before the first test and stops it
after the last, so no manual server management is required.

The server is started from `../../../server/landfall_server/` relative to this
directory. If something is already listening on port 8080 when the tests begin,
the harness skips startup and leaves that process alone.

## Prerequisites

- Dart SDK in `PATH` (used to start the server subprocess)
- Server dependencies installed: `cd ../../../server/landfall_server && dart pub get`
- Database configured and reachable (Postgres, same as normal dev setup)

## Running the tests

**Each test file must be run as a separate `flutter test` invocation.**
Passing multiple files at once causes macOS to fail launching sequential app
instances ("Error waiting for a debug connection"), so only one file per run.

### Standard tests (server-connected)

These tests boot the app pointed at a real server. Run from `apps/display/`:

```bash
flutter test integration_test/display_screen_test.dart \
  -d macos --dart-define=INTEGRATION_TEST_SERVER_URL=http://localhost:8080/

flutter test integration_test/settings_navigation_test.dart \
  -d macos --dart-define=INTEGRATION_TEST_SERVER_URL=http://localhost:8080/

flutter test integration_test/ticker_strip_test.dart \
  -d macos --dart-define=INTEGRATION_TEST_SERVER_URL=http://localhost:8080/

flutter test integration_test/layout_editor_test.dart \
  -d macos --dart-define=INTEGRATION_TEST_SERVER_URL=http://localhost:8080/
```

### Setup wizard test

Uses an **in-memory database** (fresh-install state). Do **not** pass
`INTEGRATION_TEST_SERVER_URL` — that flag bypasses the wizard entirely.
The server still needs to be reachable for the step-1 connectivity check.

```bash
flutter test integration_test/setup_wizard_test.dart \
  -d macos --dart-define=INTEGRATION_TEST_WIZARD_MODE=true
```

## How server auto-startup works

`helpers/server_manager.dart` handles the lifecycle:

1. Checks whether port 8080 is already accepting connections.
2. If not, runs `dart run bin/main.dart --apply-migrations` from the server
   directory and polls every 500 ms until the port is ready (30 s timeout).
3. On `tearDownAll`, kills only the process it started — an externally started
   server is left running.

## Test inventory

| File | What it covers |
|---|---|
| `display_screen_test.dart` | Clock display, agent card appearance and dismiss, grid layout |
| `setup_wizard_test.dart` | First-run wizard: server connect, location, accounts, completion |
| `settings_navigation_test.dart` | Settings pill, tab navigation, back to display |
| `ticker_strip_test.dart` | Empty strip invisible, ticker push appears, TTL expiry |
| `layout_editor_test.dart` | Editor opens, card tiles, hidden indicator, visibility toggle, persistence |

---

## For AI assistants

- **Run on macOS only** (`-d macos`). Integration tests do not run on iOS, Android, or Pi.
- **One file per invocation.** Multiple files in a single `flutter test` call fails with "Error waiting for a debug connection." Always run them individually.
- **Server auto-starts** via `helpers/server_manager.dart` unless port 8080 is already in use. Prerequisite: Postgres must be running and the server dependencies installed (`dart pub get` in `server/landfall_server/`).
- **`INTEGRATION_TEST_SERVER_URL`** bypasses the setup wizard and points the app at a running server. Required for all standard tests.
- **`INTEGRATION_TEST_WIZARD_MODE=true`** uses an in-memory database for wizard tests. Do NOT combine with `INTEGRATION_TEST_SERVER_URL` — passing both skips the wizard entirely.
- **No database mocks.** Tests hit a real local `landfall_test` Postgres database. See `CLAUDE.md` and `CONTRIBUTING.md` for the no-mock rule.
