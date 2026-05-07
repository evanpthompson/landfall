# Raspberry Pi Guide

This guide covers running Landfall on a Raspberry Pi. The recommended path is the pre-built image — it produces a single `.img` file that boots straight to the display with no manual setup on the Pi.

**Supported hardware:** Raspberry Pi 4 (4 GB RAM recommended) or Pi 5. Pi 3 is not supported — it lacks the memory to run the server reliably.

---

## Option A: Pre-built image (recommended)

One command builds everything. Flash, boot, done.

### 1. Configure

```bash
bash deploy/pi-gen/configure.sh
```

This interactive wizard asks for:
- **WiFi SSID and password** — baked into the image; the Pi connects automatically on first boot
- **Hostname** — default `landfall` (Pi appears as `landfall.local` on your network)
- **Server domain/IP** — default `landfall.local`; use a real domain if you want Caddy to auto-fetch TLS
- **OpenWeatherMap API key** — optional; skip to configure later

All secrets (database password, JWT keys, etc.) are auto-generated and baked in. You do not need to run `setup.sh` on the Pi.

Answers are saved to `deploy/pi-gen/landfall-build.conf` (gitignored — contains secrets).

### 2. Build

```bash
bash deploy/pi-gen/build.sh
```

This takes roughly **1–2 hours** on first run. It does three things automatically:

1. **Builds the Flutter arm64 display binary** — runs the Flutter toolchain inside a Docker + QEMU arm64 container (~20 min). Skipped if the binary already exists.
2. **Cross-compiles the server Docker image for arm64** — Dart compiles to a native arm64 binary inside QEMU (~30–40 min). Result is saved as a tarball; skipped on subsequent builds unless you delete it.
3. **Runs pi-gen** — assembles the bootable image with all binaries, secrets, and WiFi config baked in (~20 min).

Output: `deploy/pi-gen/work/pi-gen/deploy/<date>-landfall.img`

> **macOS:** Docker Desktop must be running. The script registers QEMU binfmt handlers automatically.
>
> **Linux:** Install QEMU binfmt support first: `sudo apt-get install qemu-user-binfmt`

### 3. Flash

Use [Raspberry Pi Imager](https://www.raspberrypi.com/software/):
1. **Choose OS** → **Use custom** → select the `.img` file
2. **Choose Storage** → select your SD card
3. **Write** — no need to configure anything in the imager; WiFi is already in the image

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
2. `landfall-firstboot.service` loads the server Docker image into Docker's storage
3. `landfall-server.service` starts Postgres, Redis, Caddy, and the Landfall server
4. lightdm auto-logs in the `landfall` user and starts an Openbox session
5. The display app launches fullscreen and connects to the server

No keyboard or manual steps required.

> **Default SSH credentials:** user `landfall`, password `landfall`. Change it after first boot with `passwd`.

### 5. Optional: add integrations after first boot

SSH in and edit `.env` to add Google Calendar, Microsoft Calendar, or other API keys:

```bash
ssh landfall@landfall.local
nano /home/landfall/landfall/deploy/.env
sudo systemctl restart landfall-server
```

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

### 5. Configure the display to auto-start

Install a minimal desktop and configure auto-login:

```bash
sudo apt-get install -y xorg openbox lightdm lightdm-autologin-greeter unclutter x11-xserver-utils
```

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
xset s off
xset -dpms
xset s noblank
unclutter -idle 1 &
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

**Display app doesn't appear:**
```bash
ssh landfall@landfall.local
journalctl -u lightdm -n 50
```

**Server not starting:**
```bash
ssh landfall@landfall.local
docker compose -f /home/landfall/landfall/deploy/docker-compose.prod.yml logs
```

**First-boot took too long / image not loaded:**
```bash
ssh landfall@landfall.local
journalctl -u landfall-firstboot -n 50
journalctl -u landfall-server -n 50
```

**WiFi not connecting:**
If you skipped WiFi in `configure.sh`, connect via ethernet then add WiFi:
```bash
sudo nmcli dev wifi connect "YourSSID" password "YourPassword"
```
