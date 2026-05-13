#!/usr/bin/env bash
# Landfall display DB integrity check — runs before each Flutter binary launch.
#
# If the SQLite database is corrupted (e.g. abrupt power loss mid-write),
# rename it so the app creates a fresh one at launch. Settings will re-sync
# from the server on next connection. Without this check, a single corrupted
# DB puts the display into a permanent crash loop on every boot.
#
# Designed to be called from the openbox autostart loop. Fast — typically
# completes in <100ms. Always exits 0 so a check failure can never block
# the display launch (worst case is we miss a corrupted DB and the app
# crashes anyway, which is the pre-existing behaviour).

set -uo pipefail

DB_PATH="${LANDFALL_DB_PATH:-/home/landfall/.local/share/landfall/landfall.db}"

log() { echo "[$(date --iso-8601=seconds)] db-check: $*"; }

if [[ ! -f "${DB_PATH}" ]]; then
  # No DB yet — first launch creates it. Nothing to check.
  exit 0
fi

if ! command -v sqlite3 >/dev/null 2>&1; then
  log "sqlite3 not installed — cannot verify ${DB_PATH}"
  exit 0
fi

# PRAGMA integrity_check returns "ok" on a healthy DB, otherwise a list of
# the corruption findings. Cap output at 4KB so we never blow up the journal
# on a wildly corrupted file.
result="$(timeout 15 sqlite3 "${DB_PATH}" 'PRAGMA integrity_check;' 2>&1 | head -c 4096)"

if [[ "${result}" == "ok" ]]; then
  exit 0
fi

ts="$(date +%Y%m%d-%H%M%S)"
log "CORRUPTED — moving aside (will be recreated on next launch)"
log "  pragma integrity_check returned: ${result}"

# Move the DB and any auxiliary files (WAL, shared memory, rollback journal).
for ext in "" "-wal" "-shm" "-journal"; do
  src="${DB_PATH}${ext}"
  if [[ -f "${src}" ]]; then
    mv "${src}" "${src}.corrupted-${ts}" \
      && log "  moved ${src} → ${src}.corrupted-${ts}" \
      || log "  failed to move ${src} (continuing)"
  fi
done

# Hint for the operator. The file timestamp is also picked up by
# landfall-repair.sh which surfaces "DB moved aside in last 24h" in its log.
exit 0
