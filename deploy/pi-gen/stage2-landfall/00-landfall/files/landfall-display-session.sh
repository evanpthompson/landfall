#!/bin/bash
# Landfall display session — invoked from /etc/xdg/openbox/autostart.
# This file is bash so we can use process substitution for journald + log-file
# tee-ing. /etc/xdg/openbox/autostart itself must stay dash-compatible because
# Debian's openbox-autostart sources it with /bin/sh.

LOG_FILE="${HOME}/.landfall-display.log"
# Tee to log file AND journald so logs are visible without GUI access.
exec > >(tee -a "${LOG_FILE}" | systemd-cat -t landfall-display) 2>&1

log() { echo "[$(date --iso-8601=seconds)] $*"; }

log "openbox autostart starting"
log "DISPLAY=${DISPLAY:-} XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-} XAUTHORITY=${XAUTHORITY:-}"
log "user=$(id -un) uid=$(id -u) groups=$(id -Gn)"

# Screen blanking + cursor hiding for kiosk
xset s off
xset -dpms
xset s noblank
unclutter -idle 1 &

# Keep the Flutter GTK embedder on X11 in the Openbox session.
export GDK_BACKEND=x11
# Verbose Mesa logging is opt-in. Left on by default it wrote 8.8 million
# "export failed" lines into a 138 MB log on a Pi under CMA pressure — the
# signal that mattered ("Failed to export gem bo N to dmabuf") was buried in
# its own repetition, and the writes cost SD-card I/O the display needed.
# Touch the flag file to turn it back on for a debugging session.
if [[ -e /etc/landfall/gl-debug ]]; then
  export LIBGL_DEBUG=verbose
  log "LIBGL_DEBUG=verbose (flag file present)"
fi

# Start gnome-keyring secret service if available. Linux kiosk auth now uses
# file-backed tokens, so keyring startup must not block the display.
if command -v gnome-keyring-daemon >/dev/null 2>&1; then
  eval "$(gnome-keyring-daemon --daemonize --components=secrets 2>/dev/null || true)"
  export GNOME_KEYRING_CONTROL GNOME_KEYRING_PID
fi

# Show splash until the server is ready, then launch the display app.
log "launching boot splash"
python3 /opt/landfall/landfall-splash.py || log "splash exited non-zero (continuing)"

# Raise the descriptor ceiling for the display and everything it launches.
# This is where it has to happen: the display is started by this session, not
# by landfall-display.service, so LimitNOFILE in that unit never applies on a
# running Pi. The soft limit is raised toward the inherited hard limit, which
# an unprivileged process is allowed to do.
#
# A backstop, not a fix — a descriptor leak exhausts any ceiling. The leak
# itself was a client timeout shorter than the long poll it wrapped, fixed in
# apps/display/lib/src/app/poll_timeouts.dart.
ulimit -n 8192 2>/dev/null || log "could not raise the descriptor limit (continuing)"
log "descriptor limit: $(ulimit -n)"

# Restart loop. If the display exits successfully (>0s uptime) we reset the
# crash counter; back-to-back fast crashes trip the diagnostic fallback so the
# operator sees ssh instructions instead of a black screen with a cursor.
consecutive_fast_crashes=0
while true; do
  # Validate the display SQLite DB before each launch. A corrupted DB is
  # one of the few crash causes that recurs forever — moving it aside lets
  # the app create a fresh one and resync from server.
  /opt/landfall/landfall-db-check.sh || log "db-check exited non-zero (continuing)"

  log "launching Flutter display"
  start_ts=$(date +%s)
  /home/landfall/landfall/display/display
  status=$?
  end_ts=$(date +%s)
  uptime=$((end_ts - start_ts))
  log "Flutter display exited status=${status} uptime=${uptime}s"

  if [[ ${uptime} -lt 5 ]]; then
    consecutive_fast_crashes=$((consecutive_fast_crashes + 1))
    log "fast crash count=${consecutive_fast_crashes}"
  else
    consecutive_fast_crashes=0
  fi

  if [[ ${consecutive_fast_crashes} -ge 3 ]]; then
    log "display crashed ${consecutive_fast_crashes}x — showing diagnostic screen"
    # Dev-build-only telemetry: when the operator built this image with a
    # telemetry endpoint baked into .env, fire a crash_loop event so the
    # self-hosted telemetry server sees the incident. Reads endpoint from
    # the runtime .env to avoid baking a URL into the image.
    if [[ -f /home/landfall/landfall/deploy/.env ]]; then
      tel_url="$(grep -E '^LANDFALL_TELEMETRY_ENDPOINT=' /home/landfall/landfall/deploy/.env 2>/dev/null | head -1 | cut -d= -f2-)"
      tel_key="$(grep -E '^LANDFALL_TELEMETRY_API_KEY=' /home/landfall/landfall/deploy/.env 2>/dev/null | head -1 | cut -d= -f2-)"
      if [[ -n "${tel_url}" ]]; then
        curl -sS -m 5 -X POST "${tel_url}" \
          -H "Content-Type: application/json" \
          ${tel_key:+-H "Authorization: Bearer ${tel_key}"} \
          -d "{\"event\":\"display_crash_loop\",\"platform\":\"linux\",\"app_version\":\"pi-image\",\"timestamp\":\"$(date --iso-8601=seconds)\",\"props\":{\"consecutive_fast_crashes\":${consecutive_fast_crashes},\"last_status\":${status},\"hostname\":\"$(hostname)\"}}" \
          > /dev/null 2>&1 \
          && log "telemetry: posted display_crash_loop event" \
          || log "telemetry: post failed (continuing)"
      fi
    fi
    python3 /opt/landfall/landfall-diagnostic.py || true
    # Reset counter and retry — operator may have fixed something via ssh.
    consecutive_fast_crashes=0
  fi
  sleep 2
done
