#!/usr/bin/env bash
# Landfall display watchdog — kicks lightdm if the display process disappears.
#
# The openbox autostart already auto-restarts the Flutter binary in a loop.
# This watchdog covers the rarer failure modes where the loop itself dies
# (openbox crashed, lightdm session ended, X server died) and the entire
# graphical stack needs to be re-launched. Without it the operator sees a
# black screen with a working SSH session and no obvious recovery path.
#
# Runs as root via systemd. Sleeps 60s between checks. Restarts lightdm only
# after the display process has been absent for 3 consecutive checks (~3 min)
# to avoid restart-storms during firstboot or graceful reboots.

set -uo pipefail

DISPLAY_BIN="${LANDFALL_DISPLAY_BIN:-/home/landfall/landfall/display/display}"
CHECK_INTERVAL="${LANDFALL_WATCHDOG_INTERVAL:-60}"
MISS_THRESHOLD="${LANDFALL_WATCHDOG_MISS_THRESHOLD:-3}"
GRACE_BOOT_SEC="${LANDFALL_WATCHDOG_GRACE:-180}"
INITIALIZED_FLAG="${LANDFALL_INITIALIZED_FLAG:-/var/lib/landfall/.initialized}"

log() { echo "[$(date --iso-8601=seconds)] watchdog: $*"; }

log "starting (interval=${CHECK_INTERVAL}s threshold=${MISS_THRESHOLD} grace=${GRACE_BOOT_SEC}s)"

# Don't fight firstboot — wait for it to complete plus a grace window so the
# splash has time to give way to the display app.
if [[ ! -f "${INITIALIZED_FLAG}" ]]; then
  log "waiting for ${INITIALIZED_FLAG}..."
  while [[ ! -f "${INITIALIZED_FLAG}" ]]; do sleep 10; done
fi
log "initialized — waiting ${GRACE_BOOT_SEC}s grace"
sleep "${GRACE_BOOT_SEC}"

miss_count=0
restart_count=0
last_restart=0

while sleep "${CHECK_INTERVAL}"; do
  if pgrep -f "${DISPLAY_BIN}" >/dev/null 2>&1; then
    if (( miss_count > 0 )); then
      log "display process back — resetting miss counter"
    fi
    miss_count=0
    continue
  fi

  miss_count=$((miss_count + 1))
  log "display absent (${miss_count}/${MISS_THRESHOLD})"

  if (( miss_count < MISS_THRESHOLD )); then
    continue
  fi

  # Don't loop-restart lightdm faster than once every 5 minutes. The autostart
  # has its own backoff for the inner display loop; this is just the safety net.
  now=$(date +%s)
  if (( now - last_restart < 300 )); then
    log "skipping lightdm restart (last restart $((now - last_restart))s ago)"
    miss_count=0
    continue
  fi

  restart_count=$((restart_count + 1))
  last_restart=${now}
  log "restarting lightdm (cumulative restart count=${restart_count})"
  systemctl restart lightdm || log "lightdm restart command failed"
  miss_count=0
done
