# Running Landfall Locally on macOS

This guide covers running the full Landfall stack (backend + display) on macOS without a Raspberry Pi.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- [Flutter](https://docs.flutter.dev/get-started/install/macos) installed (`flutter doctor` should report no critical issues)
- Repo cloned at any path (the script is self-locating)

## Quick start

From the repo root:

```bash
bash tools/scripts/start_mac.sh
```

This does three things:
1. Starts the Postgres and Redis dev containers (via `docker compose`) if they aren't already running
2. Starts the Serverpod backend on `http://localhost:8080`
3. Opens the macOS display app

## First run

On first run there is no built app yet. Pass `--build` to compile it:

```bash
bash tools/scripts/start_mac.sh --build
```

The release `.app` is written to:
```
apps/display/build/macos/Build/Products/Release/display.app
```

Subsequent runs without `--build` will open the existing build. Re-run with `--build` any time you change Flutter code.

## Options

| Flag | Effect |
|------|--------|
| *(none)* | Start backend + open existing app (debug build if no release exists) |
| `--build` | Rebuild the macOS app with `flutter build macos --release`, then launch |
| `--reset` | Clear profile data, rebuild app, fresh start (see below) |
| `--server` | Start backend only, skip launching the app |

### How `--reset` works

`--reset` truncates only the `dashboard_profiles` table and clears the app's local settings, then rebuilds and launches. When the app connects and calls `loadProfiles()` against an empty table, the client automatically seeds the three default profiles (Weekday, Weekend, Night) using the current `DashboardLayout` definitions in `landfall_shared`. No hardcoded JSON — the Dart code is always the source of truth for layout defaults.

Use `--reset` any time layouts have changed in code and you want the DB to reflect them, or any time you want a clean slate.

## Backend only

If you want to work on the Flutter app in `flutter run` mode (hot-reload, error output in terminal), start just the backend first:

```bash
bash tools/scripts/start_mac.sh --server
```

Then in a separate terminal:

```bash
cd apps/display
flutter run -d macos
```

## Logs

Server logs are written to `/tmp/landfall-server.log`:

```bash
tail -f /tmp/landfall-server.log
```

## Stopping the stack

```bash
# Stop the server
kill $(lsof -ti :8080)

# Stop Docker containers (optional — they can stay running across restarts)
cd server/landfall_server
docker compose stop postgres redis
```

## After a machine reboot

Docker containers do not auto-restart. Run the launcher script and it will bring them back up automatically.

## Sign-in

On first launch the app shows a sign-in screen. Enter your email, tap **Send code**, and retrieve the OTP from the server log:

```bash
grep -i otp /tmp/landfall-server.log | tail -5
```

## Troubleshooting

**Server did not start within 15s**
Check the log for a Dart or database error:
```bash
cat /tmp/landfall-server.log
```
Most commonly the Docker containers aren't ready yet — wait a few seconds and re-run.

**App shows a blank screen / connection refused**
The server URL stored in the app's local database should be `http://localhost:8080/`. Verify and correct it:
```bash
sqlite3 ~/Library/Containers/io.landfall.display/Data/Documents/landfall.db \
  "SELECT server_url FROM display_settings_entries;"

# If it shows a Pi IP or anything other than http://localhost:8080/, fix it:
sqlite3 ~/Library/Containers/io.landfall.display/Data/Documents/landfall.db \
  "UPDATE display_settings_entries SET server_url='http://localhost:8080/';"
```

**Port 8080 already in use**
A previous server process may still be running:
```bash
kill $(lsof -ti :8080)
```
Then re-run the launcher.

## Testing the Companion QR from your phone

The Companion QR encodes a URL the server resolves at runtime: if
`LANDFALL_DOMAIN` is set in the environment the server returns
`https://$LANDFALL_DOMAIN`; otherwise it picks the first RFC1918 IPv4
address on the host (typically `192.168.x.x` on home WiFi) and serves
on `:8082`.

For local dev that usually means the QR points at
`http://<your-mac-lan-ip>:8082/c/<uuid>`. To make this reachable from a
phone on the same WiFi:

1. Confirm the Serverpod web server is bound to the LAN, not just
   loopback. The dev compose file binds `:8082` to all interfaces by
   default.
2. macOS firewall: System Settings → Network → Firewall → allow
   incoming connections to `dart`, or temporarily turn the firewall
   off while testing.
3. Scan the QR — your phone should load the companion page directly.

If the QR ends up pointing at `127.0.0.1`, the server could not find a
LAN address; set `LANDFALL_DOMAIN=<your-mac-lan-ip>` in the server's
environment as a workaround.

## Dev-build self-hosted telemetry

The display includes a compile-time-gated `Telemetry` class
(`apps/display/lib/src/app/telemetry.dart`). Production builds leave the
endpoint constant empty, so the class is a no-op that emits zero network
traffic. Dev builds can opt in by passing `--dart-define` flags pointing at
your local server.

```bash
# Loopback bypass — no API key needed when posting to 127.0.0.1.
flutter run -d macos \
  --dart-define=LANDFALL_DEFAULT_SERVER_URL=http://127.0.0.1:8080/ \
  --dart-define=LANDFALL_WEB_SERVER_URL=http://127.0.0.1:8082/ \
  --dart-define=LANDFALL_TELEMETRY_ENDPOINT=http://127.0.0.1:8080/api/v1/telemetry/event
```

(For non-loopback telemetry endpoints — fleet aggregators, telemetry from
the Mac to a different host — mint an API key via
`tools/scripts/mint_api_key.sh` and add `--dart-define=LANDFALL_TELEMETRY_API_KEY=...`.)

Verify events are arriving:

```bash
tail -f /tmp/landfall-server.log | grep LANDFALL_TELEMETRY
```

You should see `[LANDFALL_TELEMETRY] event=app_launched ...` on every
launch. Events fire fire-and-forget — failures only `debugPrint` to the
Flutter terminal and never block UI work.

See [`docs/build_defines.md`](build_defines.md) for the full list of
build-time constants and [`docs/roadmap.md`](roadmap.md) for what telemetry
work is still ahead (crash-bundle auto-ship, event aggregation).

---

## For AI assistants

Key facts for helping users run Landfall locally on macOS:

- **Quick start:** `bash tools/scripts/start_mac.sh` (existing build) or `bash tools/scripts/start_mac.sh --build` (first run or after Flutter changes).
- **`--reset`** truncates only `dashboard_profiles` and clears local settings — safe way to get a clean slate without wiping Postgres entirely.
- **OTP sign-in on dev:** SMTP is not required. OTP codes appear in the server log when `OTP_LOG_CODES=true` is set in the server env, or use: `grep -i otp /tmp/landfall-server.log | tail -5`.
- **Server logs:** `/tmp/landfall-server.log`. Tail it to watch startup, OTP codes, and telemetry events.
- **Display app SQLite DB:** `~/Library/Containers/io.landfall.display/Data/Documents/landfall.db`. If the stored server URL is wrong, update it with `sqlite3 ... "UPDATE display_settings_entries SET server_url='http://localhost:8080/';"`.
- **Two Serverpod ports:** API on `:8080`, web server (photos, OAuth, companion) on `:8082`. Both must be reachable. `flutter run` mode passes them via `--dart-define`.
- **Companion QR from a phone:** the server resolves to the Mac's LAN IP. If it shows `127.0.0.1`, set `LANDFALL_DOMAIN=<mac-lan-ip>` in the server's environment.
- **Hot reload** works in `flutter run -d macos` mode. For production-like testing, use `--build` which compiles a release `.app`.
