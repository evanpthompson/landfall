# Self-Hosting Guide

Landfall runs entirely on your own hardware. Nothing leaves your network unless you explicitly connect an external API (weather, Google Calendar, etc.). This guide walks from zero to a running display.

---

## What you need

- A machine to run the server: Raspberry Pi 4 (4 GB+), an old PC, a VPS, or anything that runs Linux and Docker
- A display: Fire TV Stick, Raspberry Pi with HDMI, or any Android device
- Docker and Docker Compose installed on the server machine

If you want a single-device setup (one Pi running both the server and the display), see the [Raspberry Pi Guide](raspberry_pi_guide.md) — a pre-built image handles everything.

---

## 1. Install Docker

On the server machine:

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Log out and back in, then verify:
docker run hello-world
```

---

## 2. Clone the repo

```bash
git clone https://github.com/your-org/landfall.git
cd landfall
```

Replace `your-org` with the GitHub org or username where the repo lives.

---

## 3. Run setup

```bash
bash deploy/scripts/setup.sh
```

This script:
- Asks for your hostname or IP address
- Generates all required secrets (DB password, JWT keys, etc.)
- Writes a `deploy/.env` file ready for Docker Compose

---

## 4. Add optional integrations

Open `deploy/.env` in a text editor. The file has comments explaining each field.

**Weather** — free API key from [openweathermap.org/api](https://openweathermap.org/api):
```
OWM_API_KEY=your_key_here
```

**Google Calendar + Drive** — create an OAuth 2.0 client at [console.cloud.google.com](https://console.cloud.google.com). Before creating the client, enable both the **Google Calendar API** and the **Google Drive API** under "APIs & Services → Library" (without this step the OAuth consent will succeed but syncing will return permission errors). Set the redirect URI to `https://<your-domain>/calendar/oauth/callback`:
```
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GOOGLE_REDIRECT_URI=https://landfall.local/calendar/oauth/callback
```

**Microsoft Calendar** — register an app at [portal.azure.com](https://portal.azure.com), add the `Calendars.Read` delegated permission under "API permissions" and click **Grant admin consent** (without the consent grant the permission is registered but not active). Set the redirect URI to `https://<your-domain>/calendar/microsoft/oauth/callback`:
```
MICROSOFT_CLIENT_ID=...
MICROSOFT_CLIENT_SECRET=...
MICROSOFT_REDIRECT_URI=https://landfall.local/calendar/microsoft/oauth/callback
```

---

## 5. Start the server

```bash
cd deploy
docker compose -f docker-compose.prod.yml up -d
```

First run will build the server image (~5 minutes). Subsequent starts are instant.

Check that it's running:
```bash
docker compose -f docker-compose.prod.yml ps
curl http://localhost:8080/card/getCards -X POST -H 'Content-Type: application/json' -d '{}'
# Should return: []
```

---

## 6. Connect a display

### Fire TV Stick

Build the APK on your development machine:
```bash
bash tools/scripts/build_apk.sh
```

Then follow the printed sideload instructions (`adb connect` → `adb install`).

### Raspberry Pi (separate display device)

The Pi requires a Linux arm64 binary. Flutter cannot cross-compile, so the binary must be built on a Linux arm64 machine. The simplest approach is to build directly on the Pi:

```bash
# On the Pi — install Flutter first if not already installed:
# https://docs.flutter.dev/get-started/install/linux
bash tools/scripts/build_linux.sh
# Takes ~15 minutes; output at apps/display/build/linux/arm64/release/bundle/
```

Or use Docker + QEMU to build from any machine with Docker:
```bash
cat > /tmp/lf-build.sh << 'EOF'
#!/bin/bash
set -e
apt-get update -q
apt-get install -y cmake ninja-build clang \
  libgtk-3-dev pkg-config \
  libblkid-dev liblzma-dev libsecret-1-dev lld
flutter build linux --release
EOF

docker run --rm --platform linux/arm64 \
  -v "$(pwd)":/app \
  -v /tmp/lf-build.sh:/lf-build.sh \
  -w /app/apps/display \
  ghcr.io/cirruslabs/flutter:stable \
  bash /lf-build.sh
```

Then copy the bundle to the Pi (replace `<PI_IP>` with the Pi's IP address — run `hostname -I` on the Pi to find it):
```bash
rsync -av apps/display/build/linux/arm64/release/bundle/ \
  pi@<PI_IP>:/home/pi/landfall-display/
```

Run it (requires a desktop session):
```bash
DISPLAY=:0 /home/pi/landfall-display/display
```

For auto-start on boot, see the systemd service in `deploy/pi-gen/stage-landfall/00-landfall/files/landfall-display.service`.

### Any Android device

Install via `adb install` the same APK used for Fire TV.

---

## 7. Open the display app

On first launch, the app will ask for your server address. Enter:
- `http://<SERVER_IP>:8080` for local network — replace `<SERVER_IP>` with the server machine's IP address (run `hostname -I` on it to find it)
- `https://<your-domain>` if you have a domain with SSL via Caddy

---

## 8. Connect calendar and photo accounts

Open the display, tap anywhere to reveal the gear icon (bottom-right), then tap it to open Settings → Accounts.

The Accounts tab shows copyable OAuth URLs. Open the URL on your phone or laptop — it takes you through the standard Google or Microsoft consent flow. The display updates automatically once you authorize.

---

## Backups

The `backup` container runs `pg_dump` at 2 AM daily and keeps the last 7 dumps in a Docker volume. To access them:

```bash
docker run --rm \
  -v landfall_backup_data:/backups \
  -v $(pwd):/out \
  alpine cp -r /backups /out/
```

---

## Updates

```bash
git pull
cd deploy
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d
```

Serverpod applies any new migrations automatically on startup.

---

## Health monitoring

The server exposes a health endpoint at `http://<server>:8081`. You can point a free [UptimeRobot](https://uptimerobot.com) monitor at it to get notified if the server goes down.

---

## Troubleshooting

**Server won't start:**
```bash
docker compose -f docker-compose.prod.yml logs server
```

**Database connection errors:**
Ensure `DB_HOST=postgres` in your `.env` — the Postgres container is reachable at that hostname within the Docker network.

**Calendar not syncing:**
Check that your OAuth redirect URI in the `.env` exactly matches what you registered in the Google Cloud or Azure console, including the scheme (`https://` vs `http://`).
