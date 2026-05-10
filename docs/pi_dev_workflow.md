# Pi Dev Workflow

How to iterate on the display app against the live Pi server without cutting a
full release build. Use this when you want hot reload, DevTools, or fast
code→screen feedback on real Pi hardware.

---

## Prerequisites

- Pi is reachable at `192.168.1.130` (SSH key auth as `landfall`)
- The server stack is running (`docker ps` shows `deploy-server-1` as `Up`)
- The repo at `/home/landfall/landfall-dev` is up to date (`git pull` there, or
  push from your workstation and pull on the Pi)

---

## Starting the display in dev mode

```bash
ssh landfall@192.168.1.130
cd /home/landfall/landfall-dev/apps/display
DISPLAY=:0 nohup /home/landfall/flutter/bin/flutter run -d linux \
  --dart-define=LANDFALL_DEFAULT_SERVER_URL=http://127.0.0.1:8080/ \
  --dart-define=LANDFALL_WEB_SERVER_URL=http://127.0.0.1:8082/ \
  > /tmp/flutter-display.log 2>&1 &
```

Both `--dart-define` flags are required:

| Flag | Value | Why |
|------|-------|-----|
| `LANDFALL_DEFAULT_SERVER_URL` | `http://127.0.0.1:8080/` | Serverpod API — skips setup wizard, connects directly |
| `LANDFALL_WEB_SERVER_URL` | `http://127.0.0.1:8082/` | Serverpod web server — photos, OAuth callbacks, and static routes live here |

Without `LANDFALL_WEB_SERVER_URL`, photo URLs are constructed against port `8080`
(the API server), which returns `404`. The photo card then flashes black as each
failed load auto-advances to the next photo.

---

## Watching the log

```bash
tail -f /tmp/flutter-display.log
```

Flutter prints hot-reload output and `dart:developer` log entries here. Photo
load errors appear as `[landfall.photo] Failed to load photo: ...`.

---

## Hot reloading

`flutter run` keeps a VM service open. From the same SSH session where you
started it, or from a second terminal:

```bash
# Send a hot reload:
kill -USR1 $(pgrep -f 'flutter.*run')

# Or, if you have the flutter run session in the foreground, press 'r'
```

Hot reload works for widget changes. Press `R` (capital) for a full hot restart
(clears state). Code changes to `initState`, `main`, or anything that runs once
at startup require a hot restart.

---

## Stopping the display

```bash
pkill -f 'flutter.*run'
pkill -f 'bundle/display'
```

The first command stops the `flutter run` controller; the second stops the
compiled display binary it launched.

---

## Checking server health

```bash
# API server (Serverpod)
curl -s http://127.0.0.1:8080/

# Web server (photos, OAuth)
curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8082/photos/1
# Expected: 401 (requires auth) — means the route is alive
# 404 means the web server isn't responding on 8082

# Full stack status
docker ps --format '{{.Names}}: {{.Status}}'
```

---

## Rebuilding the server image

If you change server-side Dart code, rebuild the server Docker image on the Pi
before restarting. This takes ~3 minutes on a Pi 5, ~5 minutes on a Pi 4:

```bash
ssh landfall@192.168.1.130
cd /home/landfall/landfall-dev
docker build -f server/landfall_server/Dockerfile -t landfall-server:latest .
cd /home/landfall/landfall/deploy
docker compose -f docker-compose.prod.yml up -d --force-recreate server
```

> **Architecture note:** Always build the server image on the Pi itself. Images
> built on a macOS (amd64) machine won't run on arm64 and will crash with
> `exec format error`. The pi-gen build pipeline cross-compiles via QEMU, but
> for dev iteration building natively on the Pi is faster and simpler.

---

## Production vs dev mode

| | Dev (`flutter run`) | Production (release binary) |
|---|---|---|
| Binary | Debug, JIT-compiled | Release, AOT-compiled |
| Hot reload | Yes | No |
| Build step on change | No (hot reload) | `flutter build linux --release ...` then rsync |
| Display binary path | `build/linux/arm64/debug/bundle/display` | `/home/landfall/landfall/display/display` |
| Launch mechanism | Manual `flutter run` | Openbox autostart loop in `/etc/xdg/openbox/autostart` |
| Server URL | `http://127.0.0.1:8080/` | `http://127.0.0.1:8080/` |
| Web server URL | `http://127.0.0.1:8082/` (must pass explicitly) | `http://127.0.0.1:8082/` (baked in at build time by `build-display-docker.sh`) |

To switch from dev back to production mode, stop `flutter run`, then launch the
release binary directly (Openbox autostart will do this on next login, or
manually):

```bash
pkill -f 'flutter.*run'
pkill -f 'debug/bundle/display'
DISPLAY=:0 /home/landfall/landfall/display/display &
```

---

## Common issues

### Photos not loading / card flashing black

The display app cycles rapidly through photos when every image fails. Root causes:

1. **Missing `LANDFALL_WEB_SERVER_URL`** — photos hit port 8080 instead of 8082.
   Fix: restart with both `--dart-define` flags (see above).

2. **Server container not running** — check `docker ps`. If `deploy-server-1`
   shows `Restarting`, check its architecture with
   `docker image inspect landfall-server:latest --format '{{.Architecture}}'`.
   If it shows `amd64` on a Pi (arm64), rebuild it on the Pi (see above).

3. **Auth token expired** — restart the display app to force a fresh login.

### Layout error: connection refused on port 57XXX

Serverpod client fails to connect. The server container is down or crashed.
Check `docker logs deploy-server-1 --tail 20`.

### `cannot open display:`

`DISPLAY=:0` is required when launching from SSH. Check that LightDM and
Openbox are running: `ps aux | grep -E 'lightdm|openbox'`.
