#!/usr/bin/env bash
# Landfall auto-repair — bounded, idempotent recovery for the failure modes
# we've actually seen in the field.
#
# Runs every 5 minutes via landfall-repair.timer. Each check is:
#   1. detect the problem
#   2. count today's attempts against a per-day cap
#   3. take ONE targeted action — never restart-storm
#
# State lives at /var/lib/landfall/repair-state. Rolling 7-day window so the
# log doesn't grow unbounded.
#
# Manual run:  sudo /opt/landfall/landfall-repair.sh

set -uo pipefail

STATE_DIR="${LANDFALL_STATE_DIR:-/var/lib/landfall}"
STATE_FILE="${LANDFALL_REPAIR_STATE_FILE:-${STATE_DIR}/repair-state}"
INITIALIZED_FLAG="${LANDFALL_INITIALIZED_FLAG:-${STATE_DIR}/.initialized}"
DEPLOY_DIR="${LANDFALL_DEPLOY_DIR:-/home/landfall/landfall/deploy}"
ENV_FILE="${LANDFALL_ENV_FILE:-${DEPLOY_DIR}/.env}"
COMPOSE_FILE="${LANDFALL_COMPOSE_FILE:-${DEPLOY_DIR}/docker-compose.prod.yml}"
DISPLAY_LOG="${LANDFALL_DISPLAY_LOG:-/home/landfall/.landfall-display.log}"

# Daily caps. Past these, the repair logs a FATAL message and stops — better
# to leave the broken state visible than to mask it with an infinite restart
# loop that burns CPU and writes thousands of journal entries.
MAX_DOCKER_RESTART_PER_DAY="${LANDFALL_MAX_DOCKER_RESTART:-6}"
MAX_COMPOSE_UP_PER_DAY="${LANDFALL_MAX_COMPOSE_UP:-12}"
MAX_LIGHTDM_RESTART_PER_DAY="${LANDFALL_MAX_LIGHTDM_RESTART:-4}"
CRASH_FLOOR_FOR_LIGHTDM_RESTART="${LANDFALL_LIGHTDM_CRASH_FLOOR:-30}"

log() { echo "[$(date --iso-8601=seconds)] repair: $*"; }

today="$(date +%Y-%m-%d)"
mkdir -p "${STATE_DIR}"
touch "${STATE_FILE}"

# Read the count for today for a given condition. Returns 0 if no entry.
get_count() {
  local condition="$1"
  local line
  line="$(grep "^${today} ${condition}=" "${STATE_FILE}" 2>/dev/null | tail -1 || true)"
  echo "${line#*=}"
}

# Increment the count for today + prune entries older than 7 days.
inc_count() {
  local condition="$1"
  local current
  current="$(get_count "${condition}")"
  current="${current:-0}"
  local next=$((current + 1))
  local cutoff
  cutoff="$(date -d '7 days ago' +%Y-%m-%d 2>/dev/null || echo '')"

  local tmp
  tmp="$(mktemp)"
  if [[ -n "${cutoff}" ]]; then
    awk -v c="${cutoff}" -v today="${today}" -v cond="${condition}" -v n="${next}" '
      $1 >= c && !($1 == today && $2 == cond"="$3 ? 0 : ($1 == today && index($2, cond"=") == 1))
    ' "${STATE_FILE}" > "${tmp}" 2>/dev/null || true
    # Simpler: just rewrite without the matching today+condition line, then append.
    grep -v "^${today} ${condition}=" "${STATE_FILE}" 2>/dev/null \
      | awk -v c="${cutoff}" '$1 >= c' > "${tmp}" 2>/dev/null || true
  else
    grep -v "^${today} ${condition}=" "${STATE_FILE}" > "${tmp}" 2>/dev/null || true
  fi
  echo "${today} ${condition}=${next}" >> "${tmp}"
  mv "${tmp}" "${STATE_FILE}"
}

# Don't repair anything until firstboot has completed. Repairing pre-firstboot
# state would race with the firstboot service.
if [[ ! -f "${INITIALIZED_FLAG}" ]]; then
  log "firstboot not complete (${INITIALIZED_FLAG} missing) — skipping repair cycle"
  exit 0
fi

actions_taken=0
fatal_count=0

# ── 1. Docker daemon up? ─────────────────────────────────────────────────────
if ! systemctl is-active --quiet docker 2>/dev/null; then
  count="$(get_count docker_restart)"
  count="${count:-0}"
  if (( count >= MAX_DOCKER_RESTART_PER_DAY )); then
    log "FATAL: docker daemon down — daily restart cap (${count}/${MAX_DOCKER_RESTART_PER_DAY}) reached"
    fatal_count=$((fatal_count + 1))
  else
    log "ACTION: docker daemon down — restarting (attempt ${count}/${MAX_DOCKER_RESTART_PER_DAY})"
    inc_count docker_restart
    systemctl restart docker 2>&1 | sed 's/^/  /' || log "  docker restart command exited non-zero"
    sleep 5
    actions_taken=$((actions_taken + 1))
  fi
fi

# ── 2. .env present? ─────────────────────────────────────────────────────────
# If firstboot ran but .env is missing, something deleted it. We can't safely
# regenerate (would reset all secrets and break encrypted OAuth tokens in DB).
# Just log loudly so operator notices.
if [[ ! -f "${ENV_FILE}" ]]; then
  log "FATAL: ${ENV_FILE} missing but firstboot flag present — operator action required"
  log "  This usually means someone deleted .env. To recover:"
  log "    1. SSH in and re-run firstboot:  sudo rm ${INITIALIZED_FLAG} && sudo reboot"
  log "    2. NOTE: regenerated secrets invalidate stored OAuth tokens — accounts will need re-linking"
  fatal_count=$((fatal_count + 1))
fi

# ── 3. landfall-server compose stack up? ─────────────────────────────────────
if systemctl is-active --quiet docker 2>/dev/null && [[ -f "${ENV_FILE}" && -f "${COMPOSE_FILE}" ]]; then
  server_state="$(
    cd "${DEPLOY_DIR}" 2>/dev/null && \
    docker compose -f "${COMPOSE_FILE}" ps --format '{{.Service}} {{.State}}' 2>/dev/null \
      | awk '$1 == "server" {print $2; exit}'
  )"
  if [[ "${server_state}" != "running" ]]; then
    count="$(get_count compose_up)"
    count="${count:-0}"
    if (( count >= MAX_COMPOSE_UP_PER_DAY )); then
      log "FATAL: server container not running (state=${server_state:-absent}) — daily cap reached"
      fatal_count=$((fatal_count + 1))
    else
      log "ACTION: server container state=${server_state:-absent} — docker compose up -d (attempt ${count}/${MAX_COMPOSE_UP_PER_DAY})"
      inc_count compose_up
      (cd "${DEPLOY_DIR}" && docker compose -f "${COMPOSE_FILE}" up -d 2>&1 | tail -5 | sed 's/^/  /') || true
      actions_taken=$((actions_taken + 1))
    fi
  fi
fi

# ── 4. Display crash-looping? ────────────────────────────────────────────────
# The openbox autostart and landfall-display-watchdog cover the
# process-disappeared case. This catches the rarer pathology where the
# display process keeps spawning but exits within a few seconds — a real
# log will show many "Flutter display exited" lines. If we cross the
# threshold, restart lightdm to force a fresh X session.
if [[ -f "${DISPLAY_LOG}" ]]; then
  todays_crashes=$(grep -c "${today}.*Flutter display exited" "${DISPLAY_LOG}" 2>/dev/null || echo 0)
  if (( todays_crashes >= CRASH_FLOOR_FOR_LIGHTDM_RESTART )); then
    count="$(get_count lightdm_restart)"
    count="${count:-0}"
    if (( count >= MAX_LIGHTDM_RESTART_PER_DAY )); then
      log "FATAL: display has crashed ${todays_crashes}x today + lightdm restart cap reached (${count}/${MAX_LIGHTDM_RESTART_PER_DAY})"
      log "  The Flutter binary is broken — bundle a bug report:  landfall-bug-report"
      fatal_count=$((fatal_count + 1))
    else
      log "ACTION: display crashed ${todays_crashes}x today — restarting lightdm (attempt ${count}/${MAX_LIGHTDM_RESTART_PER_DAY})"
      inc_count lightdm_restart
      systemctl restart lightdm 2>&1 | sed 's/^/  /' || true
      # Reset the crash counter baseline so the next cycle doesn't immediately
      # trip again from the same backlog of crash lines.
      : > "${DISPLAY_LOG}"
      actions_taken=$((actions_taken + 1))
    fi
  fi
fi

# ── 5. Display database integrity ────────────────────────────────────────────
# Cheap check — the heavy lift happens at display launch via
# landfall-db-check.sh. Here we just record whether a corrupted DB was
# moved aside recently so the doctor can surface it.
DB_PATH="${LANDFALL_DB_PATH:-/home/landfall/.local/share/landfall/landfall.db}"
recent_corruption="$(find "$(dirname "${DB_PATH}")" -maxdepth 1 -name "$(basename "${DB_PATH}").corrupted-*" -mtime -1 2>/dev/null | head -1)"
if [[ -n "${recent_corruption}" ]]; then
  log "NOTE: display DB was moved aside in the last 24h: ${recent_corruption}"
  log "  A fresh DB will be created at next display launch. Settings re-sync from server."
fi

if (( actions_taken == 0 && fatal_count == 0 )); then
  log "no issues found (system healthy)"
else
  log "cycle complete: ${actions_taken} action(s), ${fatal_count} fatal(s)"
fi
