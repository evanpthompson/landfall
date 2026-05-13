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
# Remove ALL conf.d files that could set an unintended autologin user before
# writing zz-landfall.conf (zz sorts after lightdm-*, so ours always wins).
rm -f /etc/lightdm/lightdm.conf.d/*piwiz* \
      /etc/lightdm/lightdm.conf.d/*wizard* \
      /etc/lightdm/lightdm.conf.d/lightdm-autologin-greeter.conf \
      /etc/lightdm/lightdm.conf.d/99-landfall.conf \
      2>/dev/null || true
userdel rpi-first-boot-wizard 2>/dev/null || true

# ── lightdm: auto-login the landfall user into an openbox session ─────────
# Best-effort build-time write. Upstream pi-gen stages run after this stage
# and re-create rpi-first-boot-wizard plus rewrite /etc/lightdm/lightdm.conf
# to auto-login that user. lightdm loads /etc/lightdm/lightdm.conf *after*
# conf.d/*.conf, so a drop-in cannot override it. The authoritative fix is
# landfall-display-prep.service, installed below, which re-enforces the
# correct state on every boot before lightdm starts.
cat > /etc/lightdm/lightdm.conf << 'LIGHTDM'
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

# ── KMS GL driver enforcement ────────────────────────────────────────────────
# Flutter falls back to llvmpipe software rendering if vc4-kms-v3d isn't
# enabled, making the display unusably slow on Pi. Bookworm pi-gen normally
# enables this by default, but older base images or custom config.txt
# variants may not — make absolutely sure it's there.
for cfg in "${ROOTFS_DIR}/boot/firmware/config.txt" "${ROOTFS_DIR}/boot/config.txt"; do
  if [[ -f "${cfg}" ]]; then
    if ! grep -q 'dtoverlay=vc4-kms-v3d' "${cfg}"; then
      {
        echo ""
        echo "# Landfall: KMS GL required for accelerated Flutter rendering."
        echo "# Without this the display falls back to llvmpipe (software) — unusably slow."
        echo "dtoverlay=vc4-kms-v3d"
      } >> "${cfg}"
    fi
    # Also need enough VRAM allocation for the desktop display. Default
    # gpu_mem=76 on Pi 4 is fine for KMS, but call out the setting so
    # operators investigating SW rendering see why it matters.
    if ! grep -q '^max_framebuffers=' "${cfg}"; then
      echo "max_framebuffers=2" >> "${cfg}"
    fi
  fi
done

# ── Timezone ─────────────────────────────────────────────────────────────────
# Without an explicit timezone the kiosk clock shows UTC on first boot until
# the user notices. Bake the configured zone into the image and seed
# /etc/timezone so the displayed time matches the wall clock immediately.
PI_TIMEZONE="$(cat "${STAGE_FILES}/timezone" 2>/dev/null || echo Etc/UTC)"
if [[ -f "${ROOTFS_DIR}/usr/share/zoneinfo/${PI_TIMEZONE}" ]]; then
  echo "${PI_TIMEZONE}" > "${ROOTFS_DIR}/etc/timezone"
  ln -sf "/usr/share/zoneinfo/${PI_TIMEZONE}" "${ROOTFS_DIR}/etc/localtime"
else
  echo "WARNING: timezone ${PI_TIMEZONE} not found in zoneinfo; defaulting to UTC"
  echo "Etc/UTC" > "${ROOTFS_DIR}/etc/timezone"
  ln -sf "/usr/share/zoneinfo/Etc/UTC" "${ROOTFS_DIR}/etc/localtime"
fi

# ── WiFi NetworkManager connection ───────────────────────────────────────────
if [[ -f "${STAGE_FILES}/wifi.nmconnection" ]]; then
  install -d "${ROOTFS_DIR}/etc/NetworkManager/system-connections"
  install -m 600 "${STAGE_FILES}/wifi.nmconnection" \
    "${ROOTFS_DIR}/etc/NetworkManager/system-connections/landfall-wifi.nmconnection"
fi

# ── Static IP NetworkManager connection (ethernet) ───────────────────────────
if [[ -f "${STAGE_FILES}/static-ip.nmconnection" ]]; then
  install -d "${ROOTFS_DIR}/etc/NetworkManager/system-connections"
  install -m 600 "${STAGE_FILES}/static-ip.nmconnection" \
    "${ROOTFS_DIR}/etc/NetworkManager/system-connections/landfall-static-ip.nmconnection"
fi

# ── SSH access ───────────────────────────────────────────────────────────────
# Without explicit auth config the landfall user has no password and no
# authorized_keys, leaving the device unreachable over the network. We:
#   1. Force-enable SSH on boot via /boot/firmware/ssh
#   2. Install authorized_keys if staged
#   3. Set landfall password if staged
#   4. Remove the "SSH may not work until a valid user has been set up" banner
#   5. Disable the rpi-first-boot-wizard package fully (re-attempted from above)
install -d "${ROOTFS_DIR}/boot/firmware"
touch "${ROOTFS_DIR}/boot/firmware/ssh"

if [[ -f "${STAGE_FILES}/authorized_keys" ]]; then
  install -d -m 700 "${ROOTFS_DIR}/home/landfall/.ssh"
  install -m 600 "${STAGE_FILES}/authorized_keys" \
    "${ROOTFS_DIR}/home/landfall/.ssh/authorized_keys"
fi

if [[ -f "${STAGE_FILES}/ssh-password" ]]; then
  # Copy temporarily into chroot, apply, then remove. Never persists.
  cp "${STAGE_FILES}/ssh-password" "${ROOTFS_DIR}/tmp/.landfall-ssh-pass"
  on_chroot << 'PWEOF'
  pw="$(cat /tmp/.landfall-ssh-pass)"
  echo "landfall:${pw}" | chpasswd
  rm -f /tmp/.landfall-ssh-pass
  # Make sure landfall account is not locked
  passwd -u landfall 2>/dev/null || true
PWEOF
fi

# Wipe the Pi OS first-boot user banner and any remaining wizard configs that
# were re-installed by later pi-gen stages.
on_chroot << 'BANNEREOF'
rm -f /etc/ssh/sshd_config.d/rename_user.conf
# Some pi-gen branches install userconf-pi which re-adds the banner.
apt-get remove -y --purge userconf-pi 2>/dev/null || true
# Ensure sshd is enabled and pulled in early
systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
BANNEREOF

# ── Integration credentials for firstboot.sh ─────────────────────────────────
# firstboot.sh generates all secrets and writes .env on first boot.
# This file only contains optional API credentials from configure.sh.
install -d "${ROOTFS_DIR}/opt/landfall"
install -m 640 "${STAGE_FILES}/integrations.env" \
               "${ROOTFS_DIR}/opt/landfall/integrations.env"

# ── Flutter display binary ────────────────────────────────────────────────────
install -d "${ROOTFS_DIR}/home/landfall/landfall/display"
cp -rp "${STAGE_FILES}/bundle/." \
       "${ROOTFS_DIR}/home/landfall/landfall/display/"
chmod +x "${ROOTFS_DIR}/home/landfall/landfall/display/display"

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

# ── Boot splash + diagnostic fallback ─────────────────────────────────────────
install -m 755 "${STAGE_FILES}/landfall-splash.py" \
               "${ROOTFS_DIR}/opt/landfall/landfall-splash.py"
install -m 755 "${STAGE_FILES}/landfall-diagnostic.py" \
               "${ROOTFS_DIR}/opt/landfall/landfall-diagnostic.py"

# ── Operator tooling: doctor + bug-report + watchdog + maintenance + repair ──
install -m 755 "${STAGE_FILES}/landfall-doctor.sh" \
               "${ROOTFS_DIR}/opt/landfall/landfall-doctor.sh"
install -m 755 "${STAGE_FILES}/landfall-bug-report.sh" \
               "${ROOTFS_DIR}/opt/landfall/landfall-bug-report.sh"
install -m 755 "${STAGE_FILES}/landfall-display-prep.sh" \
               "${ROOTFS_DIR}/opt/landfall/landfall-display-prep.sh"
install -m 755 "${STAGE_FILES}/landfall-display-watchdog.sh" \
               "${ROOTFS_DIR}/opt/landfall/landfall-display-watchdog.sh"
install -m 755 "${STAGE_FILES}/landfall-maintenance.sh" \
               "${ROOTFS_DIR}/opt/landfall/landfall-maintenance.sh"
install -m 755 "${STAGE_FILES}/landfall-repair.sh" \
               "${ROOTFS_DIR}/opt/landfall/landfall-repair.sh"
install -m 755 "${STAGE_FILES}/landfall-db-check.sh" \
               "${ROOTFS_DIR}/opt/landfall/landfall-db-check.sh"
install -m 755 "${STAGE_FILES}/landfall-update.sh" \
               "${ROOTFS_DIR}/opt/landfall/landfall-update.sh"

# Symlink the operator CLIs into /usr/local/bin so they're on PATH for ssh.
ln -sf /opt/landfall/landfall-doctor.sh     "${ROOTFS_DIR}/usr/local/bin/landfall-doctor"
ln -sf /opt/landfall/landfall-bug-report.sh "${ROOTFS_DIR}/usr/local/bin/landfall-bug-report"
ln -sf /opt/landfall/landfall-update.sh     "${ROOTFS_DIR}/usr/local/bin/landfall-update"

# Install the runtime helpers the operator tooling depends on. Failures here
# must not break the image build — apt resolves on the Pi at first boot if
# needed, but baking them in saves a network round-trip.
on_chroot << 'EOF'
apt-get install -y --no-install-recommends \
  curl jq sqlite3 wmctrl mesa-utils 2>/dev/null || true
EOF

# ── Systemd services ──────────────────────────────────────────────────────────
install -m 644 "${STAGE_FILES}/landfall-firstboot.service" \
               "${ROOTFS_DIR}/etc/systemd/system/landfall-firstboot.service"

install -m 644 "${STAGE_FILES}/landfall-server.service" \
               "${ROOTFS_DIR}/etc/systemd/system/landfall-server.service"

install -m 644 "${STAGE_FILES}/landfall-display-prep.service" \
               "${ROOTFS_DIR}/etc/systemd/system/landfall-display-prep.service"

install -m 644 "${STAGE_FILES}/landfall-display-watchdog.service" \
               "${ROOTFS_DIR}/etc/systemd/system/landfall-display-watchdog.service"

install -m 644 "${STAGE_FILES}/landfall-maintenance.service" \
               "${ROOTFS_DIR}/etc/systemd/system/landfall-maintenance.service"
install -m 644 "${STAGE_FILES}/landfall-maintenance.timer" \
               "${ROOTFS_DIR}/etc/systemd/system/landfall-maintenance.timer"

install -m 644 "${STAGE_FILES}/landfall-repair.service" \
               "${ROOTFS_DIR}/etc/systemd/system/landfall-repair.service"
install -m 644 "${STAGE_FILES}/landfall-repair.timer" \
               "${ROOTFS_DIR}/etc/systemd/system/landfall-repair.timer"

on_chroot << 'EOF'
systemctl enable landfall-firstboot
systemctl enable landfall-server
systemctl enable landfall-display-prep
systemctl enable landfall-display-watchdog
systemctl enable landfall-maintenance.timer
systemctl enable landfall-repair.timer
# Block boot until clock is synced — landfall-firstboot waits on this and
# Pi hardware has no RTC, so without it the first boot writes a .env with
# a date set to the kernel build time.
systemctl enable systemd-time-wait-sync.service
EOF

# ── Openbox autostart: hand off to the bash session script ────────────────────
# Debian's openbox-autostart sources this file with /bin/sh (dash), so the
# autostart MUST stay POSIX-shell-compatible. The real session logic lives in
# landfall-display-session.sh (bash) so we can use process substitution for
# tee → log file + journald. Running it in the background lets openbox finish
# its own autostart and become responsive.
install -d "${ROOTFS_DIR}/etc/xdg/openbox"
cat > "${ROOTFS_DIR}/etc/xdg/openbox/autostart" << 'AUTOSTART'
# POSIX-shell-only — sourced by /bin/sh from openbox-autostart.
/bin/bash /opt/landfall/landfall-display-session.sh &
AUTOSTART

install -m 755 "${STAGE_FILES}/landfall-display-session.sh" \
               "${ROOTFS_DIR}/opt/landfall/landfall-display-session.sh"

# ── Fix ownership of landfall home dir ────────────────────────────────────────
# Also pre-creates the app's SQLite data directory so it is never created by
# a root process, which would lock the landfall user out of writing to it.
on_chroot << 'EOF'
chown -R landfall:landfall /home/landfall/landfall
mkdir -p /home/landfall/.local/share/landfall
chown -R landfall:landfall /home/landfall/.local
if [[ -d /home/landfall/.ssh ]]; then
  chown -R landfall:landfall /home/landfall/.ssh
  chmod 700 /home/landfall/.ssh
  chmod 600 /home/landfall/.ssh/authorized_keys 2>/dev/null || true
fi
EOF
