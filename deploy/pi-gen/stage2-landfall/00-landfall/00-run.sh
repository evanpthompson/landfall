#!/bin/bash
# pi-gen stage: install Docker, copy Landfall deploy files, configure systemd.
# Runs inside the pi-gen chroot environment.

set -euo pipefail

on_chroot << 'EOF'
# ── Docker ────────────────────────────────────────────────────────────────
apt-get update -qq
apt-get install -y --no-install-recommends ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -qq
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Allow the landfall user to run Docker without sudo
usermod -aG docker landfall

# Enable Docker on boot
systemctl enable docker

# ── Display dependencies (for Flutter Linux) ──────────────────────────────
apt-get install -y --no-install-recommends \
  libgtk-3-0 libblkid1 liblzma5 \
  xorg openbox lightdm lightdm-autologin-greeter \
  libgles2 libgbm1

# Auto-login to the landfall user at startup
cat > /etc/lightdm/lightdm.conf << 'LIGHTDM'
[Seat:*]
autologin-user=landfall
autologin-user-timeout=0
user-session=openbox
LIGHTDM

EOF

# ── Copy deploy files ─────────────────────────────────────────────────────
install -d "${ROOTFS_DIR}/home/landfall/landfall/deploy"
cp -r "${STAGE_WORK_DIR}/00-landfall/files/deploy/." \
      "${ROOTFS_DIR}/home/landfall/landfall/deploy/"

# ── Copy display binary (built separately by build_linux.sh) ─────────────
LINUX_BUILD="${SCRIPT_DIR}/../../apps/display/build/linux/arm64/release/bundle"
if [[ -d "${LINUX_BUILD}" ]]; then
  install -d "${ROOTFS_DIR}/home/landfall/landfall/display"
  cp -r "${LINUX_BUILD}/." "${ROOTFS_DIR}/home/landfall/landfall/display/"
  echo "Display binary included in image"
else
  echo "WARNING: Linux display binary not found at ${LINUX_BUILD}"
  echo "Run tools/scripts/build_linux.sh --arch arm64 before building the Pi image."
fi

# ── Systemd services ──────────────────────────────────────────────────────
install -m 644 "${STAGE_WORK_DIR}/00-landfall/files/landfall-server.service" \
               "${ROOTFS_DIR}/etc/systemd/system/landfall-server.service"

install -m 644 "${STAGE_WORK_DIR}/00-landfall/files/landfall-display.service" \
               "${ROOTFS_DIR}/etc/systemd/system/landfall-display.service"

on_chroot << 'EOF'
systemctl enable landfall-server
systemctl enable landfall-display
EOF
