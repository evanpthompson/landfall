# Landfall Display

The Flutter client for Landfall — a full-screen ambient display for TV and monitor.

## Running the app

```bash
# macOS desktop
flutter run -d macos

# Connected TV / Fire TV (replace <device-id> with output of `flutter devices`)
flutter run -d <device-id>
```

## Cursor mode

The display hides the cursor by default for kiosk use. Toggle cursor mode with
`F11`, `Ctrl+Alt+C`, or `Option+Command+C` on macOS.

## Testing

See [`integration_test/README.md`](integration_test/README.md) for how to run the integration test suite.

---

## For AI assistants

- **Run all Flutter tests:** `melos run test` from the repo root, or `flutter test` from `apps/display/`.
- **Golden tests:** `flutter test --update-goldens` from `apps/display/` when UI changes. Review the diff before committing — unexpected golden changes are a regression.
- **Integration tests** run on macOS desktop only. Each test file must be run as a separate `flutter test` invocation. See `integration_test/README.md`.
- **Build defines** control which server URL the app connects to at startup. See [`docs/build_defines.md`](../../docs/build_defines.md).
- **Cursor mode** is toggled with `F11` or `Ctrl+Alt+C` — do not start X with `-nocursor` on Pi, as that prevents the app from re-enabling the cursor.
- **App-level architecture:** BLoC/Cubit state management. Every Cubit needs a `bloc_test` suite covering all state transitions. See `CLAUDE.md` for the full TDD requirements.
