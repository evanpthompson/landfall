#!/usr/bin/env bash
# Landfall nightly display restart — interim mitigation for the display leak.
#
# The Flutter display leaks roughly 11.8 MB/hour. Measured 2026-09-21 by a
# restart A/B on the live Pi: 793,016 kB RSS at 46.3h uptime against 235,556 kB
# fresh, so 544 MB over 46.3 hours. On a 1.8 GB Pi that drives swap to 1.3 Gi
# within about two days, and the swap-in stalls are what shows up as the
# dashboard freezing. See COLON-107 for the leak itself; this is the stopgap.
#
# Kills the display binary only. The openbox session loop in
# landfall-display-session.sh relaunches it after ~2s, so X, lightdm and
# openbox stay up and the screen is dark for seconds rather than a minute.
# The exit is clean with uptime far above the session script's 5s fast-crash
# floor, so the crash counter resets rather than trips.
#
# landfall-display-watchdog.sh needs 3 consecutive 60s misses before it kicks
# lightdm, so a respawn this fast never reaches it and there is no double
# restart.
#
# Logs RSS either side of the restart so the journal answers "is the leak still
# there, and how fast" without anyone having to be logged in when it happens.

set -uo pipefail

DISPLAY_BIN="${LANDFALL_DISPLAY_BIN:-/home/landfall/landfall/display/display}"
WAIT_SECONDS="${LANDFALL_RESTART_WAIT:-45}"
SETTLE_SECONDS="${LANDFALL_RESTART_SETTLE:-10}"

log() { echo "[$(date --iso-8601=seconds)] display-restart: $*"; }

pid_of() { pgrep -f "${DISPLAY_BIN}" 2>/dev/null | head -1; }
rss_of() { ps -o rss= -p "$1" 2>/dev/null | tr -d ' '; }

before_pid="$(pid_of)"
if [[ -z "${before_pid}" ]]; then
  # Not running is the watchdog's problem, not ours. Killing nothing and
  # reporting success would be a lie, but so would failing the unit for a
  # condition this script is not responsible for.
  log "display not running — nothing to restart, leaving recovery to the watchdog"
  exit 0
fi

before_rss="$(rss_of "${before_pid}")"
log "before: pid=${before_pid} rss=${before_rss:-unknown}kB"
log "before: $(free -m | awk '/^Mem:/ {print "used="$3"MB available="$7"MB"}')"

if ! pkill -f "${DISPLAY_BIN}"; then
  log "pkill found no matching process to signal — aborting"
  exit 1
fi

# Wait for the session loop to bring it back under a different pid.
deadline=$(( $(date +%s) + WAIT_SECONDS ))
new_pid=""
while (( $(date +%s) < deadline )); do
  sleep 3
  candidate="$(pid_of)"
  if [[ -n "${candidate}" && "${candidate}" != "${before_pid}" ]]; then
    new_pid="${candidate}"
    break
  fi
done

if [[ -z "${new_pid}" ]]; then
  # The cheap path did not work, so the session loop itself is gone. Escalate
  # to the expensive one and exit non-zero: a restart that needed escalation
  # is not a silent success, and systemd marking this failed is the only way
  # anyone finds out.
  log "display did not return within ${WAIT_SECONDS}s — escalating to lightdm restart"
  systemctl restart lightdm || log "lightdm restart command failed"
  exit 1
fi

sleep "${SETTLE_SECONDS}"
after_rss="$(rss_of "${new_pid}")"
log "after: pid=${new_pid} rss=${after_rss:-unknown}kB (was ${before_rss:-unknown}kB)"
log "after: $(free -m | awk '/^Mem:/ {print "used="$3"MB available="$7"MB"}')"
