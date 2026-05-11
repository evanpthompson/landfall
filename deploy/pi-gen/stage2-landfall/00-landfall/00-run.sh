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
  libgtk-3-0t64 libblkid1 liblzma5 libsecret-1-0 \
  libgl1 libegl1 libgles2 libglx-mesa0 libgl1-mesa-dri libgbm1 \
  mesa-vulkan-drivers mesa-utils vulkan-tools dbus-x11 \
  xorg openbox lightdm lightdm-autologin-greeter \
  unclutter x11-xserver-utils \
  wireless-regdb avahi-daemon libnss-mdns \
  gnome-keyring \
  python3-tk python3-xdg

for group in docker video render input; do
  if getent group "${group}" >/dev/null; then
    usermod -aG "${group}" landfall
  fi
done

systemctl enable avahi-daemon

# Boot into graphical.target so lightdm starts automatically
systemctl set-default graphical.target

# Remove the Raspberry Pi "SSH may not work" banner — it's for the default
# first-boot user setup flow which we don't use.
rm -f /etc/ssh/sshd_config.d/rename_user.conf

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
xserver-command=X
LIGHTDM
cat > /etc/lightdm/lightdm.conf.d/99-landfall.conf << 'LIGHTDM'
[Seat:*]
autologin-user=landfall
autologin-user-timeout=0
user-session=openbox
xserver-command=X
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
LOG_FILE="${HOME}/.landfall-display.log"
exec >>"${LOG_FILE}" 2>&1

echo "[$(date --iso-8601=seconds)] openbox autostart starting"
echo "DISPLAY=${DISPLAY:-}"
echo "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-}"
echo "XAUTHORITY=${XAUTHORITY:-}"

xset s off
xset -dpms
xset s noblank
unclutter -idle 1 &

# Keep the Flutter GTK embedder on X11 in the Openbox session.
export GDK_BACKEND=x11
export LIBGL_DEBUG=verbose

# Start gnome-keyring secret service if available. Linux kiosk auth now uses
# file-backed tokens, so keyring startup must not block the display.
if command -v gnome-keyring-daemon >/dev/null 2>&1; then
  eval "$(gnome-keyring-daemon --daemonize --components=secrets 2>/dev/null || true)"
  export GNOME_KEYRING_CONTROL GNOME_KEYRING_PID
fi

# Show splash until the server is ready, then launch the display app
python3 /opt/landfall/landfall-splash.py || true
while true; do
  echo "[$(date --iso-8601=seconds)] launching Flutter display"
  /home/landfall/landfall/display/display
  status=$?
  echo "[$(date --iso-8601=seconds)] Flutter display exited with status ${status}"
  sleep 2
done &
AUTOSTART

# ── Fix ownership of landfall home dir ────────────────────────────────────────
# Also pre-creates the app's SQLite data directory so it is never created by
# a root process, which would lock the landfall user out of writing to it.
on_chroot << 'EOF'
chown -R landfall:landfall /home/landfall/landfall
mkdir -p /home/landfall/.local/share/landfall
chown -R landfall:landfall /home/landfall/.local
EOF
