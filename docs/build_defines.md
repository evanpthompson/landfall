# Build-time `--dart-define` Values

The Landfall display reads several configuration values at compile time
via `String.fromEnvironment` (`lib/src/app/app_config.dart`). They are
passed to `flutter build` / `flutter run` with `--dart-define`. This
doc is the single source of truth for which defines matter per
platform — keep it in sync when adding new ones.

## Defined values

| Define | Purpose | Default | Source of truth at runtime |
|--------|---------|---------|---------------------------|
| `LANDFALL_DEFAULT_SERVER_URL` | The API server URL. When non-empty the setup wizard is skipped. | empty | `apps/display/lib/src/app/app_config.dart` |
| `LANDFALL_WEB_SERVER_URL` | Override for the Serverpod web server (port 8082) when not behind a reverse proxy. Falls back to `LANDFALL_DEFAULT_SERVER_URL`. | empty | same |
| `LANDFALL_TELEMETRY_ENDPOINT` | **Dev builds only.** Self-hosted telemetry URL. For a self-contained debug Pi, set to `http://127.0.0.1:8080/api/v1/telemetry/event` (the Pi's own server). Empty in every production build — `Telemetry` is a compile-time no-op. | empty | same |
| `LANDFALL_TELEMETRY_API_KEY` | API key for non-loopback telemetry endpoints (fleet aggregators). **Not required** when the endpoint resolves to `127.0.0.1` / `::1` — the server route bypasses auth for loopback requests. | empty | same |
| `INTEGRATION_TEST_SERVER_URL` | Test-only — bypasses the wizard for integration runs. | empty | same |
| `INTEGRATION_TEST_WIZARD_MODE` | Test-only — runs the wizard against an in-memory DB. | `false` | same |

The companion QR base URL is **not** a build define — it is resolved at
runtime by the server via `CompanionEndpoint.getCompanionBaseUrl`. See
`docs/companion_card_design.md` and the implementation in
`server/landfall_server/lib/src/companion/companion_endpoint.dart`.

## Per-platform invocations

### macOS (local dev)

The dev pattern is direct-to-Serverpod (no Caddy). Both API and web
URLs point at localhost:

```bash
flutter run -d macos \
  --dart-define=LANDFALL_DEFAULT_SERVER_URL=http://127.0.0.1:8080/ \
  --dart-define=LANDFALL_WEB_SERVER_URL=http://127.0.0.1:8082/
```

If you skip the defines you'll see the setup wizard on launch — that
is the same path a self-hosted user takes.

### Raspberry Pi (alpha appliance image)

`deploy/pi-gen/build-display-docker.sh` already passes both defines.
Defaults are loopback because the display and server live on the same
device:

```bash
flutter build linux --release \
  --dart-define=LANDFALL_DEFAULT_SERVER_URL=http://127.0.0.1:8080/ \
  --dart-define=LANDFALL_WEB_SERVER_URL=http://127.0.0.1:8082/
```

Caddy on `:443` proxies inbound traffic to both ports, but the display
binary inside the box talks loopback directly. The companion QR
resolves to `https://<hostname>.local/c/<uuid>` via the runtime call
described above — not from these defines.

### Fire TV / Android sideload

The APK is built **without** server URL defines so users enter their
self-hosted server URL via the setup wizard on first launch:

```bash
flutter build apk --release
```

To bake a fixed server in (kiosk fleets, dev test builds), add the
defines the same way as macOS — point them at your reachable Landfall
server (Pi hostname, VPS domain, etc.).

## Dev-build-only telemetry

Production builds (the shipping Pi appliance image, public Fire TV APK, public
macOS dmg) must **not** be built with `LANDFALL_TELEMETRY_ENDPOINT` set.
Leaving it empty makes the `Telemetry` class a no-op that emits zero network
traffic — see `apps/display/lib/src/app/telemetry.dart`.

For dev / self-hosted instrumentation, point it at your own Landfall server:

```bash
# Local dev — server running on the same Mac
flutter run -d macos \
  --dart-define=LANDFALL_DEFAULT_SERVER_URL=http://127.0.0.1:8080/ \
  --dart-define=LANDFALL_TELEMETRY_ENDPOINT=http://127.0.0.1:8080/api/v1/telemetry/event \
  --dart-define=LANDFALL_TELEMETRY_API_KEY=lf_dev_xxxxx

# Pi dev image — set in configure.sh's landfall-build.conf:
#   LANDFALL_TELEMETRY_ENDPOINT=http://your-dev-server:8080/api/v1/telemetry/event
#   LANDFALL_TELEMETRY_API_KEY=lf_dev_xxxxx
# These get baked into /home/landfall/landfall/deploy/.env at firstboot, NOT
# into the binary itself — so a dev Pi image can be re-pointed without rebuilding.
```

The server route logs each event as a single-line `[LANDFALL_TELEMETRY]`
marker; `landfall-doctor` and ad-hoc `grep` consume them without parsing JSON.

## Platform divergences worth remembering

Two intentional differences between platforms that are easy to forget:

- **Window initialisation.** macOS, Windows, and non-image Linux go
  through `window_manager` in `lib/main.dart`. The pi-gen image's
  Linux build sets fullscreen in native C++
  (`linux/runner/my_application.cc`) so the Dart-side calls become
  redundant. Either path produces a fullscreen window; don't be
  surprised when `window_manager` events fire on macOS but not on Pi.
- **Auth token storage.** macOS and Android use
  `SecureStorageAuthKeyProvider` (keychain / Android Keystore). Pi
  uses `FileAuthKeyProvider` because libsecret-backed storage requires
  a running keyring agent and isn't worth the kiosk-mode complexity.
  The token file is `chmod 600` and lives under the kiosk user's
  home — single-user appliance threat model.

Add new divergences to this list as they appear.
