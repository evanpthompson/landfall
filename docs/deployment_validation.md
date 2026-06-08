# Deployment Validation

Use cheap checks before starting long Pi image or release builds.

## Every PR

```bash
bash deploy/tests/run_deploy_tests.sh
```

This runner performs:

- shell syntax checks for deployment scripts
- existing `deploy/scripts/test_setup.sh` secret-generation checks
- `firstboot.sh` tests with redirected paths and stubbed Docker
- `configure.sh` scripted-input and quoting tests
- `build.sh --stage-only` rootfs staging tests
- pi-gen stage artifact contract checks
- Fire TV Android manifest checks
- Pi display default-server build define checks
- first-boot SMTP/OTP defaults

CI runs the same command in `.github/workflows/ci.yml`.

## Before a Pi Image Build

```bash
bash deploy/tests/run_deploy_tests.sh
bash deploy/pi-gen/preflight.sh
bash deploy/pi-gen/build.sh --stage-only
```

`--stage-only` requires an existing arm64 display bundle and a server tarball source when used outside the normal build cache. Tests pass those paths through environment variables:

```bash
LANDFALL_PI_GEN_DIR=/tmp/pi-gen \
LANDFALL_LINUX_BUNDLE=/tmp/display-bundle \
LANDFALL_SERVER_TARBALL_SOURCE=/tmp/landfall-server.tar.gz \
  bash deploy/pi-gen/build.sh --stage-only
```

## Nightly Or Release Candidate

Run these only after the cheap checks pass:

- host-architecture Docker Compose config and server smoke test
- ARM64 server image build through Docker buildx
- full pi-gen image build
- QEMU boot smoke test when available
- physical Pi 4, Pi 5, and Fire TV validation per
  [`manual_smoke_test.md`](manual_smoke_test.md) — the user-visible
  end-to-end pass

## CSP Egress Contract

The companion web app served from the Pi may only reach hosts the Caddyfile
`Content-Security-Policy` `connect-src` allows. `deploy/pi-gen/check-csp-egress.sh`
enforces this: it greps the compiled `main.dart.js` for absolute `http(s)`/`ws(s)`
hosts and fails if any is neither in `connect-src` nor on the string-literal
allowlist.

```bash
bash deploy/pi-gen/check-csp-egress.sh \
  --main-js apps/display/build/web/main.dart.js \
  --caddyfile deploy/Caddyfile \
  --expected deploy/pi-gen/expected-components.yaml
```

The same script runs in two places, so the contract can't drift:

- **`ci.yml` (`companion_web` job)** — against the fresh `flutter build web`
  output, so a reintroduced fetchable URL fails the PR.
- **`verify-artifact.sh` (section 8)** — against the staged image artifact, the
  final gate on what ships.

Common cause of a failure: an absolute URL placed in user-facing Dart strings
(e.g. a `TextField` hint like `https://example.com/photo.jpg`) gets compiled
into `main.dart.js` and is read as a fetchable host. Fix it at the source — use
a non-URL placeholder — rather than widening `connect-src`. The widget tests
`web_display_tab_test.dart` and `photo_sources_screen_test.dart` guard the URL
hints against regressing.

Inert hosts that only ever appear as string literals (framework error messages,
package-metadata constants) go in `caddy.csp_connect_src_string_literal_hosts`
in `expected-components.yaml` — but only after confirming in browser dev tools
that no CSP violation is logged for them.

## Release Checklist

- server starts through `deploy/docker-compose.prod.yml`
- `landfall-firstboot.service` generates `.env` on the Pi
- SMTP is configured or OTP sign-in is intentionally disabled for the target release
- no general runtime secrets are staged into the image
- display bundle exists at `/home/landfall/landfall/display/display`
- Pi display build receives `LANDFALL_DEFAULT_SERVER_URL=http://127.0.0.1:8080/`
- Fire TV APK exists and has Android TV manifest metadata
- docs commands match scripts and artifact paths

---

## For AI assistants

Key facts for helping users run deployment validation:

- **Fast checks (run before anything):** `bash deploy/tests/run_deploy_tests.sh`. Covers shell syntax, secret generation, firstboot, configure, build staging, pi-gen contracts, Fire TV manifest, and first-boot defaults. CI runs the same command.
- **Pi image preflight** (before a full build): `bash deploy/pi-gen/preflight.sh` then `bash deploy/pi-gen/build.sh --stage-only`. The `--stage-only` flag requires env vars pointing to an existing display bundle and server tarball — see the file for the exact variables.
- **Full Pi image build and QEMU boot smoke test** are the "nightly or RC" tier — only after the fast checks are clean. Plan 1–2 hours.
- **Physical hardware validation** (the user-visible pass) is in [`manual_smoke_test.md`](manual_smoke_test.md). Run it before any public release.
- **CI workflow:** `.github/workflows/ci.yml` — runs `run_deploy_tests.sh` automatically on every PR.
- **CSP egress:** `deploy/pi-gen/check-csp-egress.sh` asserts the Caddyfile `connect-src` covers every absolute host in the compiled `main.dart.js`. Runs in CI (`companion_web` job) and in `verify-artifact.sh`. A failure usually means an absolute URL leaked into a user-facing Dart string — fix the source, don't widen the CSP.
