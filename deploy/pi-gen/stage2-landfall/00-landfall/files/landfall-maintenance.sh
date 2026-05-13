#!/usr/bin/env bash
# Landfall weekly maintenance — prevents the Pi from going read-only over time.
#
# Run weekly by landfall-maintenance.timer at 03:30 Sun (randomised +30min).
# Manual run:  sudo /opt/landfall/landfall-maintenance.sh

set -uo pipefail

DEPLOY_DIR="${LANDFALL_DEPLOY_DIR:-/home/landfall/landfall/deploy}"
DISPLAY_LOG="${LANDFALL_DISPLAY_LOG:-/home/landfall/.landfall-display.log}"
SQLITE_DB="${LANDFALL_SQLITE_DB:-/home/landfall/.local/share/landfall/landfall.db}"

DOCKER_LOG_MAX=$((100 * 1024 * 1024))   # 100 MB
DISPLAY_LOG_MAX=$((50 * 1024 * 1024))   #  50 MB
JOURNAL_VACUUM_SIZE="${LANDFALL_JOURNAL_VACUUM_SIZE:-200M}"

log() { echo "[$(date --iso-8601=seconds)] maintenance: $*"; }

log "starting weekly maintenance"
df_before="$(df -m / | tail -1 | awk '{print $4}')"
log "disk free before: ${df_before}MB"

# ── Docker container logs ────────────────────────────────────────────────────
# Docker JSON logs at /var/lib/docker/containers/<id>/<id>-json.log grow
# unbounded by default. Truncate anything past the cap; docker still keeps
# logging into the same file.
if command -v docker >/dev/null 2>&1; then
  log "checking docker container logs"
  for container in $(docker ps -aq 2>/dev/null); do
    logfile="/var/lib/docker/containers/${container}/${container}-json.log"
    if [[ -f "${logfile}" ]]; then
      size=$(stat -c%s "${logfile}" 2>/dev/null || echo 0)
      if (( size > DOCKER_LOG_MAX )); then
        log "  truncating $(docker inspect --format '{{.Name}}' "${container}" 2>/dev/null) log (${size} bytes)"
        : > "${logfile}"
      fi
    fi
  done

  # Reclaim space from dangling images, unused networks, build cache.
  # Volumes left alone — they hold Postgres/Redis data we must keep.
  log "docker system prune (preserves volumes)"
  docker system prune -af --volumes=false 2>&1 | tail -3 | sed 's/^/  /'
fi

# ── systemd journal ──────────────────────────────────────────────────────────
log "vacuuming journal to ${JOURNAL_VACUUM_SIZE}"
journalctl --vacuum-size="${JOURNAL_VACUUM_SIZE}" 2>&1 \
  | tail -3 | sed 's/^/  /' || true

# ── Display log ──────────────────────────────────────────────────────────────
if [[ -f "${DISPLAY_LOG}" ]]; then
  size=$(stat -c%s "${DISPLAY_LOG}" 2>/dev/null || echo 0)
  if (( size > DISPLAY_LOG_MAX )); then
    log "truncating display log (${size} bytes)"
    : > "${DISPLAY_LOG}"
  fi
fi

# ── Display app SQLite vacuum ────────────────────────────────────────────────
# Reclaims pages from deleted rows so the file size matches the row count.
# Run as the landfall user so file ownership stays correct.
if command -v sqlite3 >/dev/null 2>&1 && [[ -f "${SQLITE_DB}" ]]; then
  log "vacuuming ${SQLITE_DB}"
  sudo -u landfall sqlite3 "${SQLITE_DB}" 'VACUUM;' 2>&1 | sed 's/^/  /' || true
fi

# ── APT cache cleanup ────────────────────────────────────────────────────────
if command -v apt-get >/dev/null 2>&1; then
  log "apt-get clean"
  apt-get clean 2>&1 | tail -3 | sed 's/^/  /' || true
fi

df_after="$(df -m / | tail -1 | awk '{print $4}')"
log "disk free after: ${df_after}MB  (reclaimed: $((df_after - df_before))MB)"
log "maintenance complete"
