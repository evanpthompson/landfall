#!/usr/bin/env bash
# Landfall doctor — single-screen health report.
# Run after SSH'ing in:    landfall-doctor
# Or, in a bug report:     landfall-doctor > /tmp/doctor.txt
#
# Each check prints PASS / WARN / FAIL with a one-liner. Exits 0 if no FAILs.

set -uo pipefail

# Colour only when stdout is a TTY so bug reports stay clean.
if [[ -t 1 ]]; then
  GREEN=$'\033[1;32m'; RED=$'\033[1;31m'; YELLOW=$'\033[1;33m'
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else
  GREEN=""; RED=""; YELLOW=""; BOLD=""; DIM=""; RESET=""
fi

ENV_FILE="${LANDFALL_ENV_FILE:-/home/landfall/landfall/deploy/.env}"
COMPOSE_FILE="${LANDFALL_COMPOSE_FILE:-/home/landfall/landfall/deploy/docker-compose.prod.yml}"
DISPLAY_BIN="${LANDFALL_DISPLAY_BIN:-/home/landfall/landfall/display/display}"
INITIALIZED_FLAG="${LANDFALL_INITIALIZED_FLAG:-/var/lib/landfall/.initialized}"

FAIL_COUNT=0
WARN_COUNT=0

pass() { printf "  %s✓%s  %s\n"            "${GREEN}"  "${RESET}" "$*"; }
warn() { printf "  %s⚠%s  %s\n"            "${YELLOW}" "${RESET}" "$*"; WARN_COUNT=$((WARN_COUNT+1)); }
fail() { printf "  %s✗%s  %s\n"            "${RED}"    "${RESET}" "$*"; FAIL_COUNT=$((FAIL_COUNT+1)); }
sect() { printf "\n%s%s%s\n"               "${BOLD}"   "$*"        "${RESET}"; }

echo ""
echo "${BOLD}Landfall doctor${RESET}  —  $(date)"
echo "${DIM}host:${RESET} $(hostname).local  ${DIM}user:${RESET} $(id -un)"

# ── Boot state ────────────────────────────────────────────────────────────────
sect "Boot state"
[[ -f "${INITIALIZED_FLAG}" ]] \
  && pass "firstboot completed (${INITIALIZED_FLAG} present)" \
  || fail "firstboot has not completed yet (${INITIALIZED_FLAG} missing)"

if systemctl is-active --quiet 2>/dev/null systemd-time-wait-sync; then
  pass "systemd-time-wait-sync active"
elif systemctl is-failed --quiet 2>/dev/null systemd-time-wait-sync; then
  fail "systemd-time-wait-sync failed — clock is unreliable"
else
  pass "systemd-time-wait-sync completed"
fi

if timedatectl show -p NTPSynchronized --value 2>/dev/null | grep -qi yes; then
  pass "NTP synchronised  ($(date '+%Y-%m-%d %H:%M:%S %Z'))"
else
  fail "NTP NOT synchronised — OAuth tokens may be rejected as 'not yet valid'"
fi

# ── Networking ────────────────────────────────────────────────────────────────
sect "Networking"
if command -v nmcli >/dev/null 2>&1; then
  active="$(nmcli -t -f NAME,STATE c show --active 2>/dev/null | head -3)"
  if [[ -n "${active}" ]]; then
    pass "NetworkManager: $(echo "${active}" | wc -l) active connection(s)"
    echo "${active}" | sed 's/^/         /'
  else
    fail "NetworkManager: no active connection"
  fi
else
  warn "nmcli not found — cannot probe NetworkManager"
fi

lan_ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
if [[ -n "${lan_ip}" ]]; then
  pass "LAN IPv4: ${lan_ip}"
else
  fail "no LAN IPv4 address"
fi

if systemctl is-active --quiet 2>/dev/null avahi-daemon; then
  pass "avahi-daemon active (mDNS — Pi reachable at $(hostname).local)"
else
  warn "avahi-daemon not active — $(hostname).local will not resolve"
fi

# ── Disk + resources ─────────────────────────────────────────────────────────
sect "Resources"
free_mb="$(df -m / | tail -1 | awk '{print $4}')"
if [[ ${free_mb} -gt 1024 ]]; then
  pass "disk free on /: ${free_mb}MB"
elif [[ ${free_mb} -gt 256 ]]; then
  warn "disk free on /: ${free_mb}MB — getting tight (weekly maintenance should reclaim space)"
else
  fail "disk free on /: ${free_mb}MB — system will go read-only soon"
fi

mem_avail_kb="$(awk '/MemAvailable/ {print $2; exit}' /proc/meminfo 2>/dev/null || echo 0)"
mem_avail_mb=$((mem_avail_kb / 1024))
if [[ ${mem_avail_mb} -gt 256 ]]; then
  pass "memory available: ${mem_avail_mb}MB"
else
  warn "memory available: ${mem_avail_mb}MB — Pi may swap heavily"
fi

# ── Docker stack ──────────────────────────────────────────────────────────────
sect "Docker stack"
if systemctl is-active --quiet 2>/dev/null docker; then
  pass "docker daemon active"
  if [[ -f "${COMPOSE_FILE}" ]]; then
    # Each service should be Up and healthy where healthchecks exist.
    while IFS= read -r line; do
      svc="$(echo "${line}" | awk '{print $1}')"
      state="$(echo "${line}" | awk '{print $2}')"
      health="$(echo "${line}" | awk '{print $3}')"
      [[ -z "${svc}" ]] && continue
      if [[ "${state}" == "running" ]]; then
        case "${health}" in
          healthy)  pass "${svc}: running + healthy" ;;
          starting) warn "${svc}: running, healthcheck still starting" ;;
          unhealthy) fail "${svc}: running but UNHEALTHY" ;;
          ""|"-")   pass "${svc}: running (no healthcheck)" ;;
          *)        warn "${svc}: running, health=${health}" ;;
        esac
      elif [[ -z "${state}" ]]; then
        fail "${svc}: not running"
      else
        fail "${svc}: state=${state}"
      fi
    done < <(
      cd "$(dirname "${COMPOSE_FILE}")" 2>/dev/null && \
      docker compose -f "${COMPOSE_FILE}" ps --format '{{.Service}} {{.State}} {{.Health}}' 2>/dev/null
    )
  else
    fail "compose file missing: ${COMPOSE_FILE}"
  fi
else
  fail "docker daemon not active"
fi

# ── Server reachability ──────────────────────────────────────────────────────
sect "Server reachability"
for port_test in "8080:API" "8082:web"; do
  port="${port_test%%:*}"
  label="${port_test##*:}"
  if curl -fsS -m 5 -o /dev/null "http://127.0.0.1:${port}/" 2>/dev/null; then
    pass "${label} port ${port}: responding"
  else
    fail "${label} port ${port}: no response (curl http://127.0.0.1:${port}/ failed)"
  fi
done

# ── Environment file ─────────────────────────────────────────────────────────
sect "Environment file"
if [[ -f "${ENV_FILE}" ]]; then
  pass ".env exists: ${ENV_FILE}"
  required_keys=(
    LANDFALL_DOMAIN DB_PASSWORD REDIS_PASSWORD SERVERPOD_SERVICE_SECRET
    JWT_HMAC_KEY API_KEY_MANAGEMENT_TOKEN API_KEY_HMAC_SECRET
    PHOTO_SIGNING_SECRET OAUTH_TOKEN_ENCRYPTION_KEY
  )
  missing=()
  for key in "${required_keys[@]}"; do
    if ! grep -Eq "^${key}=.+" "${ENV_FILE}"; then
      missing+=("${key}")
    fi
  done
  if [[ ${#missing[@]} -eq 0 ]]; then
    pass "all required keys present"
  else
    fail "missing/empty keys in .env: ${missing[*]}"
  fi
else
  fail ".env missing: ${ENV_FILE} (firstboot may have failed)"
fi

# ── Display app ──────────────────────────────────────────────────────────────
sect "Display app"
if [[ -x "${DISPLAY_BIN}" ]]; then
  pass "display binary: ${DISPLAY_BIN}"
else
  fail "display binary missing or not executable: ${DISPLAY_BIN}"
fi

if pgrep -f "${DISPLAY_BIN}" >/dev/null 2>&1; then
  pass "display process running (pid=$(pgrep -f "${DISPLAY_BIN}" | head -1))"
else
  fail "display process not running"
fi

if systemctl is-active --quiet 2>/dev/null lightdm; then
  pass "lightdm active (autologin landfall → openbox)"
else
  fail "lightdm not active — no graphical session for the display"
fi

# Crash count today
crash_log="/home/landfall/.landfall-display.log"
if [[ -f "${crash_log}" ]]; then
  today="$(date +%Y-%m-%d)"
  todays_crashes=$(grep -c "${today}.*Flutter display exited" "${crash_log}" 2>/dev/null || echo 0)
  if [[ ${todays_crashes} -eq 0 ]]; then
    pass "display crash log clean today"
  elif [[ ${todays_crashes} -lt 5 ]]; then
    warn "display has exited ${todays_crashes}x today (see ${crash_log})"
  else
    fail "display has exited ${todays_crashes}x today — likely crash-loop (see ${crash_log})"
  fi
fi

# ── Graphics ─────────────────────────────────────────────────────────────────
sect "Graphics"
if command -v glxinfo >/dev/null 2>&1; then
  renderer="$(DISPLAY=:0 glxinfo 2>/dev/null | awk -F': ' '/OpenGL renderer/ {print $2; exit}')"
  if [[ -z "${renderer}" ]]; then
    warn "glxinfo: cannot query renderer (display not initialised?)"
  elif echo "${renderer}" | grep -Eqi 'llvmpipe|swrast|software'; then
    fail "GL renderer is SOFTWARE: ${renderer} — Flutter will be unusably slow"
    echo "         Add 'dtoverlay=vc4-kms-v3d' to /boot/firmware/config.txt and reboot"
  else
    pass "GL renderer: ${renderer}"
  fi
else
  warn "glxinfo not installed — cannot probe GL renderer"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "${BOLD}Summary${RESET}"
if [[ ${FAIL_COUNT} -eq 0 && ${WARN_COUNT} -eq 0 ]]; then
  echo "  ${GREEN}all green${RESET}  —  Pi is healthy"
  exit 0
elif [[ ${FAIL_COUNT} -eq 0 ]]; then
  echo "  ${YELLOW}${WARN_COUNT} warning(s)${RESET}, 0 failures"
  exit 0
else
  echo "  ${RED}${FAIL_COUNT} failure(s)${RESET}, ${YELLOW}${WARN_COUNT} warning(s)${RESET}"
  echo ""
  echo "  Bundle a full bug report:  landfall-bug-report"
  exit 1
fi
