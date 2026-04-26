# Raspberry Pi Guide

This guide covers running Landfall on a Raspberry Pi — either using the pre-built image (simplest) or setting up manually on an existing Pi OS installation.

**Supported hardware:** Raspberry Pi 4 (4 GB RAM recommended) or Pi 5. Pi 3 is not supported — it lacks the memory to run the Serverpod server reliably.

---

## Option A: Pre-built image (recommended)

The Landfall Pi image boots straight to the display. The server stack starts automatically. No manual setup required beyond flashing and filling in your `.env`.

### 1. Build the image

On a machine with Docker installed:

```bash
# Build the Flutter Linux arm64 binary first
bash tools/scripts/build_linux.sh --arch arm64

# Build the Pi image (~30–40 minutes)
bash deploy/pi-gen/build.sh
```

Output: `deploy/pi-gen/work/landfall-<date>-lite.img.xz`

### 2. Flash the image

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

### 3. Configure secrets

On first boot, SSH into the Pi (default user: `landfall`, password: `landfall`) and run:

```bash
cd /home/landfall/landfall/deploy
bash scripts/setup.sh
```

Then restart the server:
```bash
sudo systemctl restart landfall-server
```

### 4. Connect a display

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

Log out and back in.

### 2. Clone and configure

```bash
git clone https://github.com/yourusername/landfall.git
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

The display runs as a Flutter Linux app directly on the Pi.

**On a faster build machine** (recommended):
```bash
bash tools/scripts/build_linux.sh --arch arm64
rsync -av apps/display/build/linux/aarch64/release/bundle/ \
  landfall@<PI_IP>:/home/landfall/landfall-display/
```

**Directly on the Pi** (slower, ~15 min):
```bash
# Install Flutter on the Pi first: flutter.dev/docs/get-started/install/linux
bash tools/scripts/build_linux.sh
```

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
cd landfall
git pull
bash tools/scripts/build_linux.sh --arch arm64
rsync -av apps/display/build/linux/aarch64/release/bundle/ \
  landfall@<PI_IP>:/home/landfall/landfall-display/
ssh landfall@<PI_IP> 'cd landfall/deploy && docker compose -f docker-compose.prod.yml build && docker compose -f docker-compose.prod.yml up -d && sudo systemctl restart landfall-display'
```
