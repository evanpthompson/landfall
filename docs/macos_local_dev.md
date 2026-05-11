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
sqlite3 ~/Library/Containers/com.example.display/Data/Documents/landfall.db \
  "SELECT server_url FROM display_settings_entries;"

# If it shows a Pi IP or anything other than http://localhost:8080/, fix it:
sqlite3 ~/Library/Containers/com.example.display/Data/Documents/landfall.db \
  "UPDATE display_settings_entries SET server_url='http://localhost:8080/';"
```

**Port 8080 already in use**
A previous server process may still be running:
```bash
kill $(lsof -ti :8080)
```
Then re-run the launcher.
