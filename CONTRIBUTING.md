# Contributing to Landfall

Landfall is in alpha. Bug reports and small focused PRs are the most useful contributions right now.

## Before you open a PR

Open an issue first for anything beyond a typo or single-file fix. This keeps you from building something that conflicts with in-progress work.

For new card types or themes, check the relevant docs in [`docs/`](docs/) before starting.

## Development setup

Landfall is a Dart/Flutter monorepo managed with Melos.

```bash
# One-time setup
dart pub global activate melos
melos bootstrap

# Analysis and tests across all packages
melos run analyze
melos run test
```

See [`docs/macos_local_dev.md`](docs/macos_local_dev.md) for the full local setup, including running the Serverpod backend.

## TDD is required

Every change follows Red → Green → Refactor. Write the failing test first, then the minimum code to make it pass.

- Every `Cubit` / `Bloc` needs a `bloc_test` suite covering all state transitions
- Every public widget needs a widget test and a golden test at 1920×1080
- Every Serverpod endpoint needs an integration test
- Every use case needs unit tests for success, failure, and edge cases

PRs without tests don't get merged.

## Commit discipline

- One logical change per commit
- Commit messages describe the why, not the what
- No AI attribution lines (`Co-Authored-By: Claude …`)
- Imperative mood: `Add foo` / `Fix bar`, not `Added` / `Fixes`

## Code style

- `melos run analyze` must be clean before opening a PR
- Run `dart format .` on changed files
- Prefer editing existing files over adding new ones
- Skip speculative abstractions and backwards-compat shims unless the surface is already public

## Reporting bugs

Open an issue with:

- What you expected vs. what happened
- Steps to reproduce
- Platform: macOS / Raspberry Pi / Fire TV
- Commit SHA

Server logs (`docker compose logs landfall_server`) and display logs (`journalctl -u landfall-display` on Pi, or `flutter run` console on macOS) are useful to include.

## Security issues

Do not open a public issue for security vulnerabilities. See [`SECURITY.md`](SECURITY.md).

## License

By contributing, you agree your changes will be licensed under the project's [MIT License](LICENSE).

## For AI assistants

If you're an AI helping someone contribute to Landfall:

- **Test commands:** `melos run test` (all Flutter packages), `cd server/landfall_server && dart test` (server unit + integration tests). Run both before declaring work done.
- **Single test:** `flutter test test/path/to/test.dart` inside the relevant package directory, or `dart test test/path/to/test.dart` inside `server/landfall_server/`.
- **Serverpod schema:** Any new endpoint requires a matching entry in `server/landfall_server/lib/src/generated/protocol.yaml` and regeneration of `server/landfall_client/`. Schema mismatches cause a fatal `ExitException(1)` on server startup — not a runtime error.
- **No database mocks in tests:** Serverpod tests hit a real local test database (`landfall_test`). Do not mock the database layer.
- **Golden tests:** Run `flutter test --update-goldens` inside `apps/display/` or `packages/ui_kit/` if UI changed. Review the diff before committing.
- **Commit messages:** No `Co-Authored-By` or AI attribution lines.
