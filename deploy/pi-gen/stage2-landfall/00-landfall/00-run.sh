#!/bin/bash
# pi-gen stage: configure Landfall on the Pi rootfs.
# Executed as a subprocess by pi-gen. Only exported pi-gen variables are
# available: STAGE_DIR, STAGE_WORK_DIR, ROOTFS_DIR.

set -euo pipefail

STAGE_FILES="${STAGE_DIR}/00-landfall/files"

# ── System packages ───────────────────────────────────────────────────────────
on_chroot << 'EOF'
apt-get update -qq

# ── Docker ────────────────────────────────────────────────────────────────
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

usermod -aG docker landfall
systemctl enable docker

# ── Display dependencies (Flutter Linux arm64) ────────────────────────────
apt-get install -y --no-install-recommends \
  libgtk-3-0t64 libblkid1 liblzma5 libgles2 libgbm1 libsecret-1-0 \
  xorg openbox lightdm lightdm-autologin-greeter \
  unclutter x11-xserver-utils \
  wireless-regdb avahi-daemon libnss-mdns \
  gnome-keyring \
  python3-tk

systemctl enable avahi-daemon

# Boot into graphical.target so lightdm starts automatically
systemctl set-default graphical.target

# Remove the first-run setup wizard fully — package, leftover lightdm configs,
# and the rpi-first-boot-wizard system user that would hijack autologin.
systemctl disable piwiz 2>/dev/null || true
apt-get remove -y --purge piwiz 2>/dev/null || true
# Remove ALL conf.d files that could set an unintended autologin user.
# lightdm-autologin-greeter.conf ships with lightdm-autologin-greeter and
# sets autologin-user=AUTOLOGIN-USER-NOT-CONFIGURED, which sorts after
# 99-landfall.conf alphabetically and therefore overrides it, causing
# rpi-first-boot-wizard to get the session instead of landfall.
rm -f /etc/lightdm/lightdm.conf.d/*piwiz* \
      /etc/lightdm/lightdm.conf.d/*wizard* \
      /etc/lightdm/lightdm.conf.d/lightdm-autologin-greeter.conf \
      2>/dev/null || true
userdel rpi-first-boot-wizard 2>/dev/null || true

# ── lightdm: auto-login the landfall user into an openbox session ─────────
# Overwrite both lightdm.conf and a conf.d drop-in — the ARM64 pi-gen build
# writes rpi-first-boot-wizard into lightdm.conf after our stage, so we need
# both to ensure the correct user wins regardless of load order.
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf << 'LIGHTDM'
[Seat:*]
autologin-user=landfall
autologin-user-timeout=0
user-session=openbox
xserver-command=X -nocursor
LIGHTDM
cat > /etc/lightdm/lightdm.conf.d/99-landfall.conf << 'LIGHTDM'
[Seat:*]
autologin-user=landfall
autologin-user-timeout=0
user-session=openbox
xserver-command=X -nocursor
LIGHTDM

EOF

# ── Landfall deploy files ─────────────────────────────────────────────────────
install -d "${ROOTFS_DIR}/home/landfall/landfall/deploy"
cp -r "${STAGE_FILES}/deploy/." \
      "${ROOTFS_DIR}/home/landfall/landfall/deploy/"

# ── WiFi regulatory domain ───────────────────────────────────────────────────
# Without a country code the kernel blocks the WiFi radio entirely.
WIFI_COUNTRY="$(cat "${STAGE_FILES}/wifi-country" 2>/dev/null || echo US)"
echo "REGDOMAIN=${WIFI_COUNTRY}" > "${ROOTFS_DIR}/etc/default/crda"

# ── WiFi NetworkManager connection ───────────────────────────────────────────
if [[ -f "${STAGE_FILES}/wifi.nmconnection" ]]; then
  install -d "${ROOTFS_DIR}/etc/NetworkManager/system-connections"
  install -m 600 "${STAGE_FILES}/wifi.nmconnection" \
    "${ROOTFS_DIR}/etc/NetworkManager/system-connections/landfall-wifi.nmconnection"
fi

# ── Integration credentials for firstboot.sh ─────────────────────────────────
# firstboot.sh generates all secrets and writes .env on first boot.
# This file only contains optional API credentials from configure.sh.
install -d "${ROOTFS_DIR}/opt/landfall"
install -m 640 "${STAGE_FILES}/integrations.env" \
               "${ROOTFS_DIR}/opt/landfall/integrations.env"

# ── Flutter display binary ────────────────────────────────────────────────────
install -d "${ROOTFS_DIR}/home/landfall/landfall/display"
cp -r "${STAGE_FILES}/bundle/." \
      "${ROOTFS_DIR}/home/landfall/landfall/display/"

# ── Server Docker image tarball ───────────────────────────────────────────────
# Pre-built for arm64 by build.sh. firstboot.sh loads it into Docker on first
# boot then deletes the tarball to reclaim space.
if [[ -f "${STAGE_FILES}/landfall-server.tar.gz" ]]; then
  install -d "${ROOTFS_DIR}/opt/landfall"
  cp "${STAGE_FILES}/landfall-server.tar.gz" \
     "${ROOTFS_DIR}/opt/landfall/landfall-server.tar.gz"
fi

# ── firstboot script ──────────────────────────────────────────────────────────
install -d "${ROOTFS_DIR}/opt/landfall"
install -m 755 "${STAGE_FILES}/firstboot.sh" \
               "${ROOTFS_DIR}/opt/landfall/firstboot.sh"

# ── Boot splash ───────────────────────────────────────────────────────────────
install -m 755 "${STAGE_FILES}/landfall-splash.py" \
               "${ROOTFS_DIR}/opt/landfall/landfall-splash.py"

# ── Systemd services ──────────────────────────────────────────────────────────
install -m 644 "${STAGE_FILES}/landfall-firstboot.service" \
               "${ROOTFS_DIR}/etc/systemd/system/landfall-firstboot.service"

install -m 644 "${STAGE_FILES}/landfall-server.service" \
               "${ROOTFS_DIR}/etc/systemd/system/landfall-server.service"

on_chroot << 'EOF'
systemctl enable landfall-firstboot
systemctl enable landfall-server
EOF

# ── Openbox autostart: launch and auto-restart the display app ────────────────
install -d "${ROOTFS_DIR}/etc/xdg/openbox"
cat > "${ROOTFS_DIR}/etc/xdg/openbox/autostart" << 'AUTOSTART'
xset s off
xset -dpms
xset s noblank
unclutter -idle 1 &

# Start gnome-keyring secret service so flutter_secure_storage can persist tokens
eval $(gnome-keyring-daemon --daemonize --components=secrets)
export GNOME_KEYRING_CONTROL GNOME_KEYRING_PID

# Show splash until the server is ready, then launch the display app
python3 /opt/landfall/landfall-splash.py
while true; do
  /home/landfall/landfall/display/display
  sleep 2
done &
AUTOSTART

# ── Fix ownership of landfall home dir ────────────────────────────────────────
on_chroot << 'EOF'
chown -R landfall:landfall /home/landfall/landfall
EOF
