#!/bin/bash
# pi-gen stage: install Docker, copy Landfall deploy files, configure systemd.
# Runs in the pi-gen build context (outside chroot). Use on_chroot for
# commands that need to run inside the target rootfs.
#
# Pi-gen variables available here:
#   SUB_STAGE_DIR  — source dir of this sub-stage (/pi-gen/stage2-landfall/00-landfall)
#   STAGE_WORK_DIR — build work dir             (/pi-gen/work/landfall/stage2-landfall)
#   ROOTFS_DIR     — target rootfs              (/pi-gen/work/landfall/stage2-landfall/rootfs)

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
# SUB_STAGE_DIR is the source dir baked into the Docker image by build.sh.
install -d "${ROOTFS_DIR}/home/landfall/landfall/deploy"
cp -r "${SUB_STAGE_DIR}/files/deploy/." \
      "${ROOTFS_DIR}/home/landfall/landfall/deploy/"

# ── Copy display binary ───────────────────────────────────────────────────
# build.sh copies the arm64 Flutter bundle into files/bundle/ before the
# Docker build so it's available inside the container here.
install -d "${ROOTFS_DIR}/home/landfall/landfall/display"
cp -r "${SUB_STAGE_DIR}/files/bundle/." \
      "${ROOTFS_DIR}/home/landfall/landfall/display/"

# ── Systemd services ──────────────────────────────────────────────────────
install -m 644 "${SUB_STAGE_DIR}/files/landfall-server.service" \
               "${ROOTFS_DIR}/etc/systemd/system/landfall-server.service"

install -m 644 "${SUB_STAGE_DIR}/files/landfall-display.service" \
               "${ROOTFS_DIR}/etc/systemd/system/landfall-display.service"

on_chroot << 'EOF'
systemctl enable landfall-server
systemctl enable landfall-display
EOF
