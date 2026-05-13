#!/bin/bash
# Enforce correct lightdm autologin and remove the rpi-first-boot-wizard user
# on every boot, before lightdm starts.
#
# Why this exists as a runtime service rather than a build-time fixup:
# upstream pi-gen stages that run after stage2-landfall re-create the
# rpi-first-boot-wizard user and overwrite /etc/lightdm/lightdm.conf to
# auto-login that user. lightdm reads /etc/lightdm/lightdm.conf last, so a
# conf.d drop-in cannot override it. A boot-time oneshot is the only place we
# can guarantee correctness regardless of what the image build did.

set -euo pipefail

log() { echo "[landfall-display-prep] $*"; }

# 1. Rewrite lightdm.conf authoritatively. Idempotent.
LIGHTDM_CONF=/etc/lightdm/lightdm.conf
EXPECTED=$(cat <<'EOF'
[Seat:*]
autologin-user=landfall
autologin-user-timeout=0
user-session=openbox
xserver-command=X
EOF
)

if ! diff -q <(printf '%s\n' "${EXPECTED}") "${LIGHTDM_CONF}" >/dev/null 2>&1; then
  log "rewriting ${LIGHTDM_CONF} (autologin-user=landfall)"
  printf '%s\n' "${EXPECTED}" > "${LIGHTDM_CONF}"
fi

# 2. Remove wizard conf.d files that may set a competing autologin user.
for f in /etc/lightdm/lightdm.conf.d/*piwiz* \
         /etc/lightdm/lightdm.conf.d/*wizard* \
         /etc/lightdm/lightdm.conf.d/lightdm-autologin-greeter.conf; do
  if [[ -e "${f}" ]]; then
    log "removing wizard conf.d file: ${f}"
    rm -f "${f}"
  fi
done

# 2b. Remove XDG autostart entries for the first-boot wizard. piwiz.desktop
# tries to exec a `piwiz` binary that we've already purged, leaving an
# `exec: piwiz: not found` error in every session.
for f in /etc/xdg/autostart/piwiz.desktop \
         /etc/xdg/autostart/*wizard*.desktop; do
  if [[ -e "${f}" ]]; then
    log "removing wizard XDG autostart: ${f}"
    rm -f "${f}"
  fi
done

# 3. Remove the rpi-first-boot-wizard user if present.
if getent passwd rpi-first-boot-wizard >/dev/null 2>&1; then
  log "removing rpi-first-boot-wizard user"
  # If a lingering user-session is holding the account open (systemd --user,
  # dbus-daemon), userdel refuses with exit 8. Terminate the session and
  # kill any remaining processes before retrying. At boot time none of this
  # will be running yet; this path matters only for manual / post-update runs.
  loginctl terminate-user rpi-first-boot-wizard 2>/dev/null || true
  pkill -KILL -u rpi-first-boot-wizard 2>/dev/null || true
  # Brief grace period for systemd to reap the user manager.
  for _ in 1 2 3 4 5; do
    pgrep -u rpi-first-boot-wizard >/dev/null 2>&1 || break
    sleep 1
  done
  # --remove-home cleans up /home/rpi-first-boot-wizard. If removal still
  # fails the system will keep booting; the autologin user is what matters
  # for the black-screen symptom.
  deluser --remove-home rpi-first-boot-wizard 2>/dev/null \
    || userdel -r rpi-first-boot-wizard 2>/dev/null \
    || userdel rpi-first-boot-wizard 2>/dev/null \
    || log "WARNING: could not remove rpi-first-boot-wizard user (still in use)"
fi

# 4. Purge the wizard package if it crept back in.
if dpkg -l userconf-pi 2>/dev/null | grep -q '^ii'; then
  log "purging userconf-pi"
  apt-get remove -y --purge userconf-pi >/dev/null 2>&1 || true
fi
if dpkg -l piwiz 2>/dev/null | grep -q '^ii'; then
  log "purging piwiz"
  apt-get remove -y --purge piwiz >/dev/null 2>&1 || true
fi

log "display prep complete"
