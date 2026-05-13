#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
STAGE="${REPO_ROOT}/deploy/pi-gen/stage2-landfall/00-landfall"
FILES="${STAGE}/files"

required=(
  "${STAGE}/00-run.sh"
  "${FILES}/firstboot.sh"
  "${FILES}/landfall-firstboot.service"
  "${FILES}/landfall-server.service"
  "${FILES}/landfall-display.service"
  "${FILES}/landfall-splash.py"
  "${FILES}/landfall-diagnostic.py"
  "${FILES}/landfall-doctor.sh"
  "${FILES}/landfall-bug-report.sh"
  "${FILES}/landfall-display-prep.sh"
  "${FILES}/landfall-display-prep.service"
  "${FILES}/landfall-display-session.sh"
  "${FILES}/landfall-display-watchdog.sh"
  "${FILES}/landfall-display-watchdog.service"
  "${FILES}/landfall-maintenance.sh"
  "${FILES}/landfall-maintenance.service"
  "${FILES}/landfall-maintenance.timer"
  "${FILES}/landfall-repair.sh"
  "${FILES}/landfall-repair.service"
  "${FILES}/landfall-repair.timer"
  "${FILES}/landfall-db-check.sh"
  "${FILES}/landfall-update.sh"
)

for path in "${required[@]}"; do
  [[ -f "${path}" ]] || { echo "Missing required artifact: ${path}" >&2; exit 1; }
done

[[ -x "${STAGE}/00-run.sh" ]] || { echo "00-run.sh must be executable" >&2; exit 1; }
[[ -x "${FILES}/firstboot.sh" ]] || { echo "firstboot.sh must be executable" >&2; exit 1; }
[[ -x "${FILES}/landfall-splash.py" ]] || { echo "landfall-splash.py must be executable" >&2; exit 1; }
[[ -x "${FILES}/landfall-diagnostic.py" ]] || { echo "landfall-diagnostic.py must be executable" >&2; exit 1; }

# Splash must NOT use overrideredirect alongside fullscreen — the combination
# causes the splash to render at Tk's default 200x200 in the top-right corner
# on first boot.
if grep -q '^[[:space:]]*root\.overrideredirect' "${FILES}/landfall-splash.py"; then
  echo "landfall-splash.py: overrideredirect is incompatible with -fullscreen on first boot" >&2
  exit 1
fi

# Diagnostic fallback must be wired up in the openbox autostart so a repeated
# display crash escapes the black-screen-with-cursor state.
grep -q 'landfall-diagnostic.py' "${FILES}/landfall-display-session.sh"
grep -q 'consecutive_fast_crashes' "${FILES}/landfall-display-session.sh"

# SSH must be force-enabled and the rename_user banner removed in the rootfs
# so the operator can reach the device even before a wizard runs.
grep -q '/boot/firmware/ssh' "${STAGE}/00-run.sh"
grep -q 'rename_user.conf' "${STAGE}/00-run.sh"

# Static IP + SSH key/password staging must run in build.sh
grep -q 'static-ip.nmconnection' "${REPO_ROOT}/deploy/pi-gen/build.sh"
grep -q 'authorized_keys' "${REPO_ROOT}/deploy/pi-gen/build.sh"

# Operator tooling must be executable and wired up in 00-run.sh.
for tool in landfall-doctor.sh landfall-bug-report.sh \
            landfall-display-watchdog.sh landfall-maintenance.sh; do
  [[ -x "${FILES}/${tool}" ]] || { echo "${tool} must be executable" >&2; exit 1; }
done

grep -q 'landfall-doctor.sh' "${STAGE}/00-run.sh"
grep -q 'landfall-bug-report.sh' "${STAGE}/00-run.sh"
grep -q '/usr/local/bin/landfall-doctor' "${STAGE}/00-run.sh"
grep -q '/usr/local/bin/landfall-bug-report' "${STAGE}/00-run.sh"
grep -q 'systemctl enable landfall-display-prep' "${STAGE}/00-run.sh"
grep -q 'systemctl enable landfall-display-watchdog' "${STAGE}/00-run.sh"

# Display prep must run before lightdm and enforce the correct autologin user
# and remove the rpi-first-boot-wizard user that pi-gen re-creates after our
# stage. Without this the Pi boots to a black screen with mouse cursor because
# lightdm auto-logs-in the wrong user and the openbox autostart never runs.
grep -q '^Before=.*lightdm.service' "${FILES}/landfall-display-prep.service"
grep -q 'autologin-user=landfall' "${FILES}/landfall-display-prep.sh"
grep -q 'rpi-first-boot-wizard' "${FILES}/landfall-display-prep.sh"
grep -q 'piwiz.desktop' "${FILES}/landfall-display-prep.sh"
[[ -x "${FILES}/landfall-display-prep.sh" ]] \
  || { echo "landfall-display-prep.sh must be executable" >&2; exit 1; }

# Openbox sources /etc/xdg/openbox/autostart with /bin/sh (dash), so the
# autostart heredoc in 00-run.sh MUST be POSIX-compatible. The bash-only
# session logic lives in landfall-display-session.sh and is invoked from the
# stub via `bash`. Reject any reintroduction of process substitution (>(...))
# in the autostart heredoc.
grep -q '/bin/bash /opt/landfall/landfall-display-session.sh' "${STAGE}/00-run.sh"
# Process-substitution check: search the 00-run.sh AUTOSTART heredoc only.
awk '/<<.*AUTOSTART/{f=1;next} /^AUTOSTART$/{f=0} f' "${STAGE}/00-run.sh" \
  | grep -q '>(' \
  && { echo "00-run.sh autostart heredoc uses bash process substitution >(...) — must stay POSIX-shell-compatible" >&2; exit 1; } \
  || true
grep -q 'systemctl enable landfall-maintenance.timer' "${STAGE}/00-run.sh"

# Bug-report must redact secret-shaped values.
grep -q 'PASSWORD|SECRET|KEY|TOKEN|HMAC|PEPPER' "${FILES}/landfall-bug-report.sh"

# Maintenance preserves Docker volumes (Postgres/Redis data must not be wiped).
grep -q 'volumes=false' "${FILES}/landfall-maintenance.sh"

# Watchdog must wait for firstboot and rate-limit its lightdm restarts.
grep -q 'INITIALIZED_FLAG' "${FILES}/landfall-display-watchdog.sh"
grep -q 'last_restart' "${FILES}/landfall-display-watchdog.sh"

# Tier 2: auto-repair must be wired up and bounded.
for tool in landfall-repair.sh landfall-db-check.sh; do
  [[ -x "${FILES}/${tool}" ]] || { echo "${tool} must be executable" >&2; exit 1; }
done

grep -q 'systemctl enable landfall-repair.timer' "${STAGE}/00-run.sh"
grep -q 'landfall-db-check.sh' "${STAGE}/00-run.sh"

# Repair must have per-day caps so it can't restart-storm.
grep -q 'MAX_DOCKER_RESTART_PER_DAY' "${FILES}/landfall-repair.sh"
grep -q 'MAX_COMPOSE_UP_PER_DAY' "${FILES}/landfall-repair.sh"
grep -q 'MAX_LIGHTDM_RESTART_PER_DAY' "${FILES}/landfall-repair.sh"

# Repair must skip if firstboot hasn't completed (avoid racing the bootstrap).
grep -q 'INITIALIZED_FLAG' "${FILES}/landfall-repair.sh"

# DB check must move corrupted DBs aside, not delete them.
grep -q 'corrupted-' "${FILES}/landfall-db-check.sh"
grep -Eq 'PRAGMA integrity_check|integrity_check' "${FILES}/landfall-db-check.sh"
# Must never exit non-zero — a check failure must not block the display launch.
grep -q 'exit 0' "${FILES}/landfall-db-check.sh"

# config.txt KMS overlay must be enforced at image build time.
grep -q 'dtoverlay=vc4-kms-v3d' "${STAGE}/00-run.sh"

# Server emits the structured marker the doctor parses for re-link prompts.
grep -q 'LANDFALL_CREDENTIAL_REFRESH_FAILED' \
  "${REPO_ROOT}/server/landfall_server/lib/src/calendar/calendar_refresh_call.dart"
grep -q 'LANDFALL_CREDENTIAL_REFRESH_FAILED' "${FILES}/landfall-doctor.sh"

# Tier 3:
# - Telemetry must be a compile-time no-op (build constants empty by default).
# - Server route must require auth (same authenticateRequest as cards).
# - OTA stub must reference docs/updating.md.
grep -q "defaultValue: ''" \
  "${REPO_ROOT}/apps/display/lib/src/app/app_config.dart"
grep -q 'kLandfallTelemetryEndpoint' \
  "${REPO_ROOT}/apps/display/lib/src/app/telemetry.dart"
grep -q 'authenticateRequest' \
  "${REPO_ROOT}/server/landfall_server/lib/src/web/routes/rest/telemetry_route.dart"
grep -q 'TelemetryRoute()' "${REPO_ROOT}/server/landfall_server/lib/server.dart"
grep -q 'docs/updating.md' "${FILES}/landfall-update.sh"

# Telemetry passthrough from configure → build → firstboot → runtime .env.
grep -q 'LANDFALL_TELEMETRY_ENDPOINT' "${REPO_ROOT}/deploy/pi-gen/configure.sh"
grep -q 'LANDFALL_TELEMETRY_ENDPOINT' "${REPO_ROOT}/deploy/pi-gen/build.sh"
grep -q 'LANDFALL_TELEMETRY_ENDPOINT' "${FILES}/firstboot.sh"

grep -q '^Before=landfall-server.service' "${FILES}/landfall-firstboot.service"
grep -q '^After=.*docker.service.*landfall-firstboot.service' "${FILES}/landfall-server.service"
grep -q '^WorkingDirectory=/home/landfall/landfall/deploy' "${FILES}/landfall-server.service"
grep -q '^After=.*graphical.target.*landfall-server.service' "${FILES}/landfall-display.service"
grep -q '^ENV_FILE=.*home/landfall/landfall/deploy/.env' "${FILES}/firstboot.sh"
grep -q 'cp -r "\${STAGE_FILES}/deploy/."' "${STAGE}/00-run.sh"
grep -q '/home/landfall/landfall/display/display' "${STAGE}/00-run.sh"
grep -q 'LANDFALL_DEFAULT_SERVER_URL' "${REPO_ROOT}/deploy/pi-gen/build-display-docker.sh"
grep -q 'http://127.0.0.1:8080/' "${REPO_ROOT}/deploy/pi-gen/build-display-docker.sh"
