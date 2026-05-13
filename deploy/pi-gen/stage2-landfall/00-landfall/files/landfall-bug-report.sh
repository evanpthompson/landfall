#!/usr/bin/env bash
# Landfall bug-report bundler — produces a .tgz with everything we need to
# diagnose a failure remotely. Secrets are redacted before bundling.
#
# Usage:  landfall-bug-report [output_path]
# Output: /home/landfall/landfall-bug-report-<host>-<timestamp>.tgz

set -uo pipefail

DEPLOY_DIR="${LANDFALL_DEPLOY_DIR:-/home/landfall/landfall/deploy}"
ENV_FILE="${LANDFALL_ENV_FILE:-${DEPLOY_DIR}/.env}"
DOCTOR_BIN="${LANDFALL_DOCTOR_BIN:-/opt/landfall/landfall-doctor.sh}"
DISPLAY_LOG="${LANDFALL_DISPLAY_LOG:-/home/landfall/.landfall-display.log}"

ts="$(date +%Y%m%d-%H%M%S)"
host="$(hostname)"
out_path="${1:-/home/landfall/landfall-bug-report-${host}-${ts}.tgz}"

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
report="${tmp}/landfall-bug-report-${host}-${ts}"
mkdir -p "${report}"

echo "Collecting bug report — this may take 30s..."

# ── System identity ──────────────────────────────────────────────────────────
{
  echo "host:       ${host}"
  echo "timestamp:  $(date --iso-8601=seconds)"
  echo "uname:      $(uname -a)"
  echo "uptime:     $(uptime -p)"
  echo "boot time:  $(uptime -s)"
} > "${report}/0-identity.txt"

cp /etc/os-release "${report}/0-os-release.txt" 2>/dev/null || true

# Pi model (Bookworm)
[[ -r /proc/device-tree/model ]] && \
  tr -d '\0' < /proc/device-tree/model > "${report}/0-pi-model.txt" 2>/dev/null

# ── landfall-doctor ──────────────────────────────────────────────────────────
if [[ -x "${DOCTOR_BIN}" ]]; then
  "${DOCTOR_BIN}" > "${report}/1-doctor.txt" 2>&1 || true
fi

# ── systemd journals (last 500 lines per unit) ───────────────────────────────
for unit in landfall-firstboot landfall-server lightdm docker NetworkManager \
            ssh systemd-time-wait-sync; do
  journalctl -u "${unit}" -b --no-pager -n 500 \
    > "${report}/2-journal-${unit}.txt" 2>&1 || true
done

# Display tag is set by openbox autostart via systemd-cat
journalctl -t landfall-display -b --no-pager -n 1000 \
  > "${report}/2-journal-landfall-display.txt" 2>&1 || true

# Kernel messages
dmesg --no-pager 2>/dev/null | tail -500 > "${report}/2-dmesg.txt" || \
  journalctl -k -b --no-pager -n 500 > "${report}/2-dmesg.txt" 2>&1 || true

# ── Docker state ─────────────────────────────────────────────────────────────
if command -v docker >/dev/null 2>&1; then
  docker ps -a > "${report}/3-docker-ps.txt" 2>&1 || true
  docker images > "${report}/3-docker-images.txt" 2>&1 || true
  docker info > "${report}/3-docker-info.txt" 2>&1 || true
  docker system df > "${report}/3-docker-df.txt" 2>&1 || true

  if [[ -f "${DEPLOY_DIR}/docker-compose.prod.yml" ]]; then
    (cd "${DEPLOY_DIR}" && docker compose ps) \
      > "${report}/3-compose-ps.txt" 2>&1 || true
    for svc in server postgres redis caddy backup; do
      (cd "${DEPLOY_DIR}" && docker compose logs --tail=500 --no-color "${svc}") \
        > "${report}/3-compose-${svc}.log" 2>&1 || true
    done
  fi
fi

# ── Networking ───────────────────────────────────────────────────────────────
{
  echo "## ip addr"
  ip addr 2>/dev/null
  echo ""
  echo "## ip route"
  ip route 2>/dev/null
  echo ""
  echo "## nmcli connections"
  nmcli c show 2>/dev/null || true
  echo ""
  echo "## resolv.conf"
  cat /etc/resolv.conf 2>/dev/null || true
} > "${report}/4-network.txt"

# ── Disk + perms ─────────────────────────────────────────────────────────────
{
  echo "## df -h"
  df -h 2>/dev/null
  echo ""
  echo "## du -sh of key paths"
  du -sh /home/landfall /var/lib/docker /var/log /opt/landfall 2>/dev/null || true
} > "${report}/5-disk.txt"

ls -la "${DEPLOY_DIR}" > "${report}/5-deploy-listing.txt" 2>&1 || true
ls -la /home/landfall/landfall/display > "${report}/5-display-listing.txt" 2>&1 || true
ls -la /home/landfall/.local/share/landfall > "${report}/5-data-listing.txt" 2>&1 || true
ls -la /home/landfall/.ssh > "${report}/5-ssh-listing.txt" 2>&1 || true

# ── .env (redacted) ──────────────────────────────────────────────────────────
# Mask every value whose key looks like a secret while preserving the key names
# so config-shape bugs are still visible.
if [[ -r "${ENV_FILE}" ]]; then
  awk -F= '
    /^[[:space:]]*#/ {print; next}
    /^[[:space:]]*$/ {print; next}
    {
      key=$1
      sub(/[[:space:]]*$/, "", key)
      val=substr($0, length(key)+2)
      if (key ~ /PASSWORD|SECRET|KEY|TOKEN|HMAC|PEPPER/) {
        if (length(val) > 0) print key "=<redacted (" length(val) " chars)>"
        else print key "="
      } else {
        print
      }
    }
  ' "${ENV_FILE}" > "${report}/6-env-redacted.txt"
fi

# ── Display + autostart logs ─────────────────────────────────────────────────
if [[ -r "${DISPLAY_LOG}" ]]; then
  tail -c 2M "${DISPLAY_LOG}" > "${report}/7-display.log" 2>/dev/null || true
fi

cat /etc/xdg/openbox/autostart > "${report}/7-openbox-autostart.txt" 2>/dev/null || true
cat /etc/lightdm/lightdm.conf > "${report}/7-lightdm.conf" 2>/dev/null || true
ls /etc/lightdm/lightdm.conf.d/ > "${report}/7-lightdm-confd-listing.txt" 2>/dev/null || true

# ── Package versions ─────────────────────────────────────────────────────────
dpkg -l 2>/dev/null \
  | grep -Ei 'lightdm|openbox|gtk|gl1|gles|gbm|mesa|wayland|x11|avahi|networkmanager|openssh' \
  > "${report}/8-packages.txt" || true

# ── Bundle ──────────────────────────────────────────────────────────────────
tar -C "${tmp}" -czf "${out_path}" "$(basename "${report}")"
size="$(du -h "${out_path}" | cut -f1)"

echo ""
echo "✓ Bug report saved: ${out_path} (${size})"
echo ""
echo "Pull it off the Pi from your laptop:"
echo "  scp landfall@${host}.local:${out_path} ."
echo ""
echo "Then attach the .tgz to a GitHub issue at:"
echo "  https://github.com/evanpthompson/landfall/issues/new"
