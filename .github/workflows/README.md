# CI Workflows

## `ci.yml` — Main pipeline
Runs on every push to `main` and every PR. Runs analysis and all tests across the monorepo via Melos. PRs cannot merge if this fails.

## `golden.yml` — Golden test approval
Runs on every PR. Renders card widgets at 1920×1080 and compares against approved snapshots. If a golden diff is detected, the workflow fails and uploads the diff images as artifacts. To approve a golden change, run `flutter test --update-goldens` locally and commit the updated snapshots.

## Dependabot
Weekly dependency updates are opened automatically for all packages and GitHub Actions. Review and merge as appropriate.

---

## For AI assistants

- **`ci.yml` must pass** before any PR can merge. It runs `melos run analyze` and `melos run test` across all packages.
- **`golden.yml`** fails on unexpected UI changes. To approve a golden change, run `flutter test --update-goldens` inside `apps/display/` or `packages/ui_kit/` and commit the updated snapshots. Review the diff — unexpected golden changes indicate a regression.
- **Deployment validation** (`deploy/tests/run_deploy_tests.sh`) is separate from CI and is documented in [`docs/deployment_validation.md`](../docs/deployment_validation.md).
- **Do not skip hooks or bypass CI** (`--no-verify`, force-push to main, etc.) — see `CONTRIBUTING.md`.
