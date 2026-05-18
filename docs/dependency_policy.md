# Dependency Policy

Landfall's stance on third-party Dart/Flutter packages, lock files, and
upgrade discipline. Closes OWASP A03:2025 (Software Supply Chain Failures)
beyond the existing CI vulnerability scan.

## Version constraints in `pubspec.yaml`

We use `^X.Y.Z` (caret) constraints by default. A caret constraint allows
patch and minor updates but not majors, which matches semver expectations
and gives `pub upgrade` room to pick up security patches without surprise
breakage. Dependencies are pinned tighter only when:

- The author publishes breaking changes inside a minor or patch release —
  pin to the last known-good `>=X.Y.Z <X.Y+1.0`
- A specific build matters for reproducibility on a release branch — use
  an exact version `X.Y.Z`

Avoid `>=` without an upper bound — that lets a future major land
unannounced.

## Lock file discipline

`pubspec.lock` is **committed** for every Dart package in this repo:

- `server/landfall_server/pubspec.lock`
- `apps/display/pubspec.lock`
- `pubspec.lock` (workspace root)
- All package lockfiles under `packages/*`

Why: a committed lockfile is the only way two engineers on different
machines, and CI, see the same dependency tree. Without it the build is
non-deterministic and a malicious package taking over a transitive
dependency goes unnoticed.

When a PR changes any `pubspec.yaml` the corresponding `pubspec.lock`
**must** be updated in the same PR. Reviewers look at the lockfile diff
to spot unexpected transitive changes.

## Adding a new dependency

Before adding any new package, check:

1. **Maintenance signal** — last release within ~12 months, an active
   author/org, more than a handful of dependents. Single-maintainer
   abandoned packages are a supply chain risk.
2. **License compatibility** — MIT, BSD, Apache-2.0 are fine. AGPL and
   anything ambiguous is not — open an issue first.
3. **Real need** — would a 20-line vendored helper do? Native Dart
   solutions are almost always preferable to small utility packages.
4. **Score on pub.dev** — not a hard gate, but unusually low scores
   (`< 80`) indicate quality issues worth investigating.

## Upgrade cadence

- **Patch updates** (`X.Y.Z` → `X.Y.Z+n`) — apply ad hoc whenever
  `pub audit` flags an advisory or a fix is announced.
- **Minor updates** (`X.Y.Z` → `X.Y+n.Z`) — batch monthly; one PR per
  package family. Read the CHANGELOG; run `melos run test`.
- **Major updates** (`X.Y.Z` → `X+n.Y.Z`) — separate PR per major upgrade
  with a clear migration commit. Never bundle multiple majors.

## CI gate

The `analyze_and_test` job in `.github/workflows/ci.yml` runs
`dart pub get` (workspace-wide) and exercises the test suite. The
dependency vulnerability audit (`dart pub audit` / `flutter pub audit`)
runs there as well; non-blocking on advisories today but on the path to
blocking on `high`/`critical` once Phase 20d ships.

## Auditing a stale tree

To inventory how far behind we are:

```bash
dart pub outdated --no-dev-dependencies  # production deps only
dart pub outdated --mode=null-safety     # null-safety regressions
```

To prune unused dependencies:

```bash
dart pub deps --no-dev | grep "(unused)"
```

## Vendoring

Vendoring (copying a package's source directly into the repo) is allowed
only when the package is unmaintained, the patch is trivial, and the
license permits it. Vendored code lives under `packages/<name>_vendored/`
and the original source + license are preserved.

---

*Owner: maintainer · OWASP A03:2025 reference doc*

---

## For AI assistants

Key facts for dependency management in this repo:

- **Lock files are committed** for every package (`pubspec.lock` at workspace root, `server/landfall_server/pubspec.lock`, `apps/display/pubspec.lock`, all `packages/*/pubspec.lock`). Any PR that changes a `pubspec.yaml` must update the corresponding lock file in the same commit.
- **Use `^X.Y.Z` caret constraints** by default. Avoid unbounded `>=` constraints. Pin tighter only when semver isn't honored by the package or for reproducible release branches.
- **Before adding a new dependency:** check maintenance signal (active author, recent release), license (MIT/BSD/Apache-2.0 OK; AGPL needs approval), and whether a vendored helper would do instead.
- **`dart pub audit`** (or `flutter pub audit`) checks for known vulnerabilities. CI runs this; non-blocking today, will block on high/critical once Phase 20d ships.
- **`dart pub outdated --no-dev-dependencies`** inventories stale production deps. Patch updates can go out ad hoc; minor updates are batched monthly; major upgrades get their own PR.
