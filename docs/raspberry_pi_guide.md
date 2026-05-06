# Raspberry Pi Guide

This guide covers running Landfall on a Raspberry Pi — either using the pre-built image (simplest) or setting up manually on an existing Pi OS installation.

**Supported hardware:** Raspberry Pi 4 (4 GB RAM recommended) or Pi 5. Pi 3 is not supported — it lacks the memory to run the Serverpod server reliably.

---

## Option A: Pre-built image (recommended)

The Landfall Pi image boots straight to the display. The server stack starts automatically. No manual setup required beyond flashing and filling in your `.env`.

### 1. Build the Flutter Linux arm64 binary

Flutter cannot cross-compile to Linux arm64. The binary **must** be built on a Linux arm64 machine. You have three options:

**Option 1a — Build on the Pi itself** (simplest, no extra hardware):
```bash
# On the Pi — install Flutter first if not already installed:
# https://docs.flutter.dev/get-started/install/linux
git clone https://github.com/your-org/landfall.git
cd landfall
bash tools/scripts/build_linux.sh
# Takes ~15 minutes on a Pi 4
```

**Option 1b — Docker + QEMU** (build from any machine with Docker):
```bash
# From your development machine (macOS, Linux x86_64, etc.)
# Write a build script first to avoid shell-quoting issues:
cat > /tmp/lf-build.sh << 'EOF'
#!/bin/bash
set -e
apt-get update -q
apt-get install -y cmake ninja-build clang \
  libgtk-3-dev pkg-config \
  libblkid-dev liblzma-dev libsecret-1-dev
flutter build linux --release
EOF

docker run --rm --platform linux/arm64 \
  -v "$(pwd)":/app \
  -v /tmp/lf-build.sh:/lf-build.sh \
  -w /app/apps/display \
  ghcr.io/cirruslabs/flutter:stable \
  bash /lf-build.sh
# Output: apps/display/build/linux/aarch64/release/bundle/
# Takes ~45 minutes under QEMU emulation
```

**Option 1c — GitHub Actions** (if you have the repo on GitHub):
Push your branch and let the CI workflow produce the arm64 artifact — no local Linux required.

### 2. Build the Pi image

On a machine with Docker installed (can be macOS or Linux):

```bash
bash deploy/pi-gen/build.sh
```

This takes 20–40 minutes. Output: `deploy/pi-gen/work/landfall-<date>-lite.img.xz`

> **Note:** `deploy/pi-gen/build.sh` checks that the arm64 binary exists before starting. Build it first (Step 1) or the script will exit with a clear error.

### 3. Flash the image

Use [Raspberry Pi Imager](https://www.raspberrypi.com/software/):
1. Click **Choose OS** → **Use custom** → select the `.img.xz` file
2. Click **Choose Storage** → select your SD card
3. Click the gear icon to pre-configure Wi-Fi and SSH if needed
4. Click **Write**

Or with `dd`:
```bash
xz -d deploy/pi-gen/work/landfall-*.img.xz
sudo dd if=deploy/pi-gen/work/landfall-*.img of=/dev/sdX bs=4M status=progress
```

Replace `/dev/sdX` with your SD card device (e.g. `/dev/sdb` on Linux, `/dev/disk2` on macOS — use `diskutil list` to find it).

### 4. Configure secrets

On first boot, SSH into the Pi. The default user is `landfall` and the default password is `landfall`. Find the Pi's IP address from your router, or connect a keyboard and run `hostname -I`.

```bash
ssh landfall@<PI_IP>
cd /home/landfall/landfall/deploy
bash scripts/setup.sh
```

Then restart the server:
```bash
sudo systemctl restart landfall-server
```

### 5. Connect a display

Connect an HDMI monitor or TV to the Pi. The display app starts automatically after the server is ready (~30 seconds after boot).

---

## Option B: Manual setup on existing Pi OS

Use this if you already have a Pi running and don't want to reflash.

### Prerequisites

- Raspberry Pi OS Bookworm (64-bit)
- Pi 4 or Pi 5

### 1. Install Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

Log out and back in, then verify: `docker run hello-world`

### 2. Clone and configure

```bash
git clone https://github.com/your-org/landfall.git
cd landfall
bash deploy/scripts/setup.sh
```

### 3. Start the server

```bash
cd deploy
docker compose -f docker-compose.prod.yml up -d
```

First build takes 15–20 minutes on a Pi 4. Grab a coffee.

### 4. Install the display app

The display runs as a Flutter Linux app directly on the Pi (arm64 binary required).

**Directly on the Pi** (the simplest approach):
```bash
# Install Flutter on the Pi first:
# https://docs.flutter.dev/get-started/install/linux
cd ~/landfall
bash tools/scripts/build_linux.sh
# Takes ~15 minutes; output at apps/display/build/linux/aarch64/release/bundle/
```

**From a Linux arm64 build machine** (if you have one):
```bash
# On the build machine:
bash tools/scripts/build_linux.sh
rsync -av apps/display/build/linux/aarch64/release/bundle/ \
  landfall@<PI_IP>:/home/landfall/landfall-display/
```

Replace `<PI_IP>` with the Pi's IP address (find it with `hostname -I` on the Pi, or check your router).

### 5. Run the display

The display requires an X session. For a headless Pi connected directly to a TV, install a minimal desktop:

```bash
sudo apt-get install -y xorg openbox lightdm lightdm-autologin-greeter
```

Configure autologin:
```
# /etc/lightdm/lightdm.conf
[Seat:*]
autologin-user=landfall
autologin-user-timeout=0
user-session=openbox
```

Then install the systemd service:
```bash
sudo cp deploy/pi-gen/stage-landfall/00-landfall/files/landfall-display.service \
        /etc/systemd/system/
sudo systemctl enable --now landfall-display
```

---

## Performance notes

| | Pi 4 (4 GB) | Pi 4 (8 GB) | Pi 5 (8 GB) |
|---|---|---|---|
| Server startup | ~25s | ~20s | ~10s |
| Display startup | ~8s | ~6s | ~4s |
| Steady-state RAM (server) | ~380 MB | ~380 MB | ~380 MB |
| Steady-state RAM (display) | ~120 MB | ~120 MB | ~120 MB |
| Total at idle | ~500 MB | ~500 MB | ~500 MB |

4 GB is comfortable. 2 GB will work but leaves little headroom if Postgres grows.

---

## Updating

```bash
# On the build machine (or Pi itself):
git pull
bash tools/scripts/build_linux.sh
rsync -av apps/display/build/linux/aarch64/release/bundle/ \
  landfall@<PI_IP>:/home/landfall/landfall-display/
ssh landfall@<PI_IP> 'cd landfall/deploy && docker compose -f docker-compose.prod.yml build && docker compose -f docker-compose.prod.yml up -d && sudo systemctl restart landfall-display'
```
