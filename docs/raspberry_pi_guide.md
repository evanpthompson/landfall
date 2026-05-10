# Raspberry Pi Guide

This guide covers running Landfall on a Raspberry Pi. The all-in-one image is the beta appliance path: it produces a single `.img` file that runs the server and display on one Pi. For alpha, the most stable path is still the self-hosted Docker server plus Fire TV/Android display.

**Supported hardware:** Raspberry Pi 4 (4 GB RAM recommended) or Pi 5. Pi 3 is not supported — it lacks the memory to run the server reliably.

---

## Option A: All-in-one image (beta)

One command builds everything. Flash, boot, done.

### 1. Configure

```bash
bash deploy/pi-gen/configure.sh
```

This interactive wizard asks for:
- **WiFi SSID and password** — baked into the image; the Pi connects automatically on first boot
- **Hostname** — default `landfall` (Pi appears as `landfall.local` on your network)
- **OpenWeatherMap API key** — optional; skip to configure later

Runtime secrets such as the database password, JWT keys, API-key HMAC secret, OAuth token encryption key, and photo signing secret are not baked into the image. `landfall-firstboot.service` generates them on the Pi during first boot and writes `/home/landfall/landfall/deploy/.env`.

Answers are saved to `deploy/pi-gen/landfall-build.conf` (gitignored — contains secrets).

### 2. Build

```bash
bash deploy/pi-gen/build.sh
```

This takes roughly **1–2 hours** on first run. It does three things automatically:

1. **Builds the Flutter arm64 display binary** — runs the Flutter toolchain inside a Docker + QEMU arm64 container (~20 min). Skipped if the binary already exists.
2. **Cross-compiles the server Docker image for arm64** — Dart compiles to a native arm64 binary inside QEMU (~30–40 min). Result is saved as a tarball; skipped on subsequent builds unless you delete it.
3. **Runs pi-gen** — assembles the bootable image with binaries, optional integration credentials, and WiFi config staged in the rootfs (~20 min).

Output: `deploy/pi-gen/work/pi-gen/deploy/<date>-landfall.img`

> **macOS:** Docker Desktop must be running. The script registers QEMU binfmt handlers automatically.
>
> **Linux:** Install QEMU binfmt support first: `sudo apt-get install qemu-user-binfmt`

### 3. Flash

Use [Raspberry Pi Imager](https://www.raspberrypi.com/software/):
1. **Choose OS** -> **Use custom** -> select the `.img` file
2. **Choose Storage** -> select your SD card
3. **Write**

If you configured WiFi in `configure.sh`, it is staged into the image. If you left WiFi blank, use ethernet for first boot and add WiFi later with `nmcli`.

Or with `dd` on macOS:
```bash
diskutil list          # find your SD card, e.g. /dev/disk4
diskutil unmountDisk /dev/disk4
sudo dd if=deploy/pi-gen/work/pi-gen/deploy/<date>-landfall.img \
     of=/dev/rdisk4 bs=4m status=progress
```

Use `/dev/rdisk4` (raw device) not `/dev/disk4` — it's significantly faster.

### 4. Boot

Plug in the SD card and power on the Pi. First boot takes about **2 minutes**:

1. The Pi connects to WiFi (or ethernet)
2. `landfall-firstboot.service` derives `LANDFALL_DOMAIN` from `/etc/hostname`, generates runtime secrets, writes `.env`, and loads the server Docker image into Docker's storage
3. `landfall-server.service` starts Postgres, Redis, Caddy, and the Landfall server
4. lightdm auto-logs in the `landfall` user and starts an Openbox session
5. Openbox autostart waits for the local server health check, then launches the Flutter Linux display binary fullscreen with `LANDFALL_DEFAULT_SERVER_URL=http://127.0.0.1:8080/`
6. The display app saves that local server URL as completed setup on first launch and connects to the server

No keyboard or manual steps required.

Before spending an hour on a full build, run the fast deployment checks:

```bash
bash deploy/tests/run_deploy_tests.sh
bash deploy/pi-gen/build.sh --stage-only
```

> **Default SSH credentials:** user `landfall`, password `landfall`. Change it after first boot with `passwd`.

### 5. Optional: add integrations after first boot

SSH in and edit `.env` to add Google Calendar, Microsoft Calendar, or other API keys:

```bash
ssh landfall@landfall.local
nano /home/landfall/landfall/deploy/.env
sudo systemctl restart landfall-server
```

To use OTP sign-in on the Pi image, configure SMTP in the same `.env` file:

```dotenv
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=your_smtp_password_or_api_key
SMTP_FROM_EMAIL=landfall@example.com
SMTP_FROM_NAME=Landfall
SMTP_SSL=false
SMTP_ALLOW_INSECURE=false
OTP_LOG_CODES=false
```

The Pi image does not log OTP codes by default. Without SMTP, email sign-in cannot deliver a code.

---

## Option B: Manual setup on existing Pi OS

Use this if you already have a Pi running Raspberry Pi OS (64-bit, Trixie/Bookworm) and don't want to reflash.

### 1. Install Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```

### 2. Clone the repo and configure

```bash
git clone https://github.com/your-org/landfall.git ~/landfall
cd ~/landfall
bash deploy/scripts/setup.sh
```

### 3. Start the server

```bash
cd ~/landfall/deploy
docker compose -f docker-compose.prod.yml up -d
```

First run builds the server image on the Pi (~15–20 min). Subsequent starts are instant.

### 4. Build and install the display binary

The display is a Flutter Linux arm64 binary. Build it directly on the Pi:

```bash
# Install Flutter first: https://docs.flutter.dev/get-started/install/linux
cd ~/landfall
bash tools/scripts/build_linux.sh
# Output: apps/display/build/linux/arm64/release/bundle/
```

Or build on another machine and rsync it over:
```bash
# On a machine with Docker:
bash deploy/pi-gen/build.sh   # builds the binary as a side effect
rsync -av apps/display/build/linux/arm64/release/bundle/ \
  landfall@<PI_IP>:/home/landfall/landfall/display/
```

For a manual all-in-one Pi display build, pass both the API server URL and the web server URL. The display app uses the web server URL (`8082`) to load photos; without it photos are served from the wrong port and fail to load.

```bash
cd apps/display
flutter build linux --release \
  --dart-define=LANDFALL_DEFAULT_SERVER_URL=http://127.0.0.1:8080/ \
  --dart-define=LANDFALL_WEB_SERVER_URL=http://127.0.0.1:8082/
```

Fire TV and general Android builds do not set these defines, so they still show the setup wizard and ask for the self-hosted server URL. If a display already has stored settings, those stored settings override the compile-time default.

> **Why two URLs?** Serverpod runs two processes: an API server on port `8080` and a web server on port `8082`. Photos, OAuth callbacks, and other web routes are served from `8082`. In reverse-proxy deployments (Caddy), a single domain resolves both, so only one URL is needed. In direct-connect mode (Pi or dev), both ports must be specified.

### 5. Configure the display to auto-start

Install a minimal desktop and configure auto-login:

```bash
sudo apt-get install -y \
  xorg openbox lightdm lightdm-autologin-greeter \
  unclutter x11-xserver-utils python3-xdg \
  libgtk-3-0t64 libgl1 libegl1 libgles2 libglx-mesa0 libgl1-mesa-dri libgbm1 \
  mesa-vulkan-drivers mesa-utils vulkan-tools dbus-x11
```

`python3-xdg` is required by Openbox's XDG autostart helper. Without it,
Openbox can start successfully but skip autostart entries, leaving the display
at a black desktop with no Flutter process.

```bash
sudo tee /etc/lightdm/lightdm.conf << 'EOF'
[Seat:*]
autologin-user=landfall
autologin-user-timeout=0
user-session=openbox
xserver-command=X -nocursor
EOF
```

Configure openbox to launch the display app:
```bash
sudo tee /etc/xdg/openbox/autostart << 'EOF'
LOG_FILE="${HOME}/.landfall-display.log"
exec >>"${LOG_FILE}" 2>&1

xset s off
xset -dpms
xset s noblank
unclutter -idle 1 &

export GDK_BACKEND=x11

while true; do
  /home/landfall/landfall/display/display
  sleep 2
done &
EOF
```

Enable and start the display manager:
```bash
sudo systemctl enable lightdm
sudo systemctl start lightdm
```

---

## Performance

| | Pi 4 (4 GB) | Pi 4 (8 GB) | Pi 5 (8 GB) |
|---|---|---|---|
| Server startup | ~25s | ~20s | ~10s |
| Display startup | ~8s | ~6s | ~4s |
| Steady-state RAM (server) | ~380 MB | ~380 MB | ~380 MB |
| Steady-state RAM (display) | ~120 MB | ~120 MB | ~120 MB |

4 GB is comfortable. 2 GB will work but leaves little headroom as the database grows.

---

## Updating

To update the server on the Pi:

```bash
ssh landfall@landfall.local
cd ~/landfall
git pull
cd deploy
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d
```

To update the display binary, rebuild on a machine with Docker and copy it over:

```bash
# On build machine:
bash deploy/pi-gen/build.sh       # rebuilds the Flutter binary
rsync -av apps/display/build/linux/arm64/release/bundle/ \
  landfall@landfall.local:/home/landfall/landfall/display/
# The display restarts automatically via the openbox autostart loop
```

---

## Troubleshooting

### What a working display boot looks like

After boot, these should all be true:

```bash
ssh landfall@landfall.local
systemctl is-active docker landfall-server lightdm
ps -ef | grep -E 'openbox|/home/landfall/landfall/display/display' | grep -v grep
curl -sS http://127.0.0.1:8080/
```

Expected:

- `docker`, `landfall-server`, and `lightdm` are `active`
- Openbox is running as user `landfall`
- The display binary is running, or the Openbox autostart loop is launching it
- The local server health check returns `OK ...`

### Display is black or no app appears

First check whether Openbox autostart ran:

```bash
ssh landfall@landfall.local
journalctl -u lightdm -n 50
tail -160 ~/.xsession-errors
tail -160 ~/.landfall-display.log
ps -ef | grep -E 'flutter|display|openbox|lightdm' | grep -v grep
```

If `~/.xsession-errors` contains this:

```text
ERROR: openbox-xdg-autostart requires PyXDG to be installed
```

install the missing package and restart LightDM:

```bash
sudo apt-get install -y python3-xdg
sudo systemctl restart lightdm
```

If the Flutter process is running but the screen is still black, capture the X
root window to distinguish "no app" from "app painted a black frame":

```bash
DISPLAY=:0 XAUTHORITY=/home/landfall/.Xauthority \
  import -window root /tmp/landfall-screen.png
file /tmp/landfall-screen.png
identify -verbose /tmp/landfall-screen.png | grep -E 'Geometry:|Colors:|mean'
```

The debug session that fixed this path showed a fullscreen Flutter window in
`xwininfo`, but a single dark color in the screenshot until Openbox autostart
was repaired and the Flutter run finished building.

### Graphics stack diagnostics

Use these to confirm the Pi exposes the expected GL/Vulkan devices:

```bash
DISPLAY=:0 XAUTHORITY=/home/landfall/.Xauthority glxinfo -B
DISPLAY=:0 XAUTHORITY=/home/landfall/.Xauthority vulkaninfo --summary
```

On a working Pi 4/5 image, `vulkaninfo --summary` should list the Broadcom V3D
GPU. If `glxinfo` or `vulkaninfo` is missing, install:

```bash
sudo apt-get install -y mesa-utils vulkan-tools mesa-vulkan-drivers
```

### Server not starting

```bash
ssh landfall@landfall.local
docker compose -f /home/landfall/landfall/deploy/docker-compose.prod.yml logs
```

### First-boot took too long / image not loaded

```bash
ssh landfall@landfall.local
journalctl -u landfall-firstboot -n 50
journalctl -u landfall-server -n 50
```

### WiFi not connecting

If you skipped WiFi in `configure.sh`, connect via ethernet then add WiFi:
```bash
sudo nmcli dev wifi connect "YourSSID" password "YourPassword"
```

### `flutter-pi` experiment

`flutter-pi` was tested as a way to bypass X11/GTK entirely. It successfully
built and started the Dart VM on the Pi, but required additional app and runtime
adaptation:

- The app must be built with `--dart-define=LANDFALL_FLUTTER_PI=true` so it
  skips desktop-only plugins such as `window_manager`.
- Drift/SQLite needs a system `libsqlite3.so` available at runtime
  (`sudo apt-get install -y libsqlite3-dev` on the test Pi).
- `flutter-pi` needs `libflutter_engine.so.*` and `icudtl.dat` from compatible
  ARM engine binaries beside the asset bundle.
- When launched over SSH, `flutter-pi` can report `drmdev is paused`; launching
  from an active virtual terminal with `openvt` avoids SSH session ownership
  problems.

For now, the production image remains on the Flutter Linux GTK embedder under
LightDM/Openbox because that is the path currently showing the display.
