# Contributing to Landfall

Thanks for considering a contribution. Landfall is in alpha — feedback,
bug reports, and small focused PRs are the most valuable contributions
right now.

## Before you open a PR

- **Open an issue first** for any change beyond a typo or one-file fix.
  This avoids work on something that conflicts with in-flight refactors.
- For new card types, integration packs, or themes, check the relevant
  docs in [`docs/`](docs/) — there are dedicated guides for each.

## Development workflow

Landfall is a Dart/Flutter monorepo managed with Melos.

```bash
# One-time setup
dart pub global activate melos
melos bootstrap

# Run analysis and tests across all packages
melos run analyze
melos run test
```

See [`docs/macos_local_dev.md`](docs/macos_local_dev.md) for the full
local development setup, including running the Serverpod backend.

## TDD is required

Per `CLAUDE.md`: every change follows Red → Green → Refactor.

- Every `Cubit` / `Bloc` needs a `bloc_test` suite covering all state
  transitions
- Every public widget needs a widget test plus a golden test at 1920×1080
- Every Serverpod endpoint needs an integration test
- Every use case needs unit tests covering success, failure, and edge
  cases

PRs without tests will be asked to add them before review.

## Commit discipline

- One logical change per commit
- Commit messages describe the **why**, not the what
- No AI attribution lines (no `Co-Authored-By: Claude …` etc.)
- Follow conventional capitalisation and imperative mood
  (`Add foo` / `Fix bar`, not `Added` / `Fixes`)

## Code style

- `melos run analyze` must be clean before opening a PR
- Run `dart format .` on changed files
- Prefer editing existing files over adding new ones
- Avoid speculative abstractions and backwards-compat shims unless the
  surface is already public

## Reporting bugs

Open an issue with:

- What you expected to happen
- What actually happened
- Steps to reproduce
- Platform: macOS / Raspberry Pi / Fire TV (Android)
- Commit SHA you tested against

Logs from `~/.landfall-display.log` (Pi) or `flutter run` console output
are extremely helpful.

## Security issues

Please **do not** open a public issue for security vulnerabilities. See
[`SECURITY.md`](SECURITY.md) for the private disclosure process.

## License

By contributing, you agree that your contributions will be licensed
under the project's [MIT License](LICENSE).
