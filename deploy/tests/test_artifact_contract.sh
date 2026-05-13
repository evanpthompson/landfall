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
grep -q 'landfall-diagnostic.py' "${STAGE}/00-run.sh"
grep -q 'consecutive_fast_crashes' "${STAGE}/00-run.sh"

# SSH must be force-enabled and the rename_user banner removed in the rootfs
# so the operator can reach the device even before a wizard runs.
grep -q '/boot/firmware/ssh' "${STAGE}/00-run.sh"
grep -q 'rename_user.conf' "${STAGE}/00-run.sh"

# Static IP + SSH key/password staging must run in build.sh
grep -q 'static-ip.nmconnection' "${REPO_ROOT}/deploy/pi-gen/build.sh"
grep -q 'authorized_keys' "${REPO_ROOT}/deploy/pi-gen/build.sh"

grep -q '^Before=landfall-server.service' "${FILES}/landfall-firstboot.service"
grep -q '^After=.*docker.service.*landfall-firstboot.service' "${FILES}/landfall-server.service"
grep -q '^WorkingDirectory=/home/landfall/landfall/deploy' "${FILES}/landfall-server.service"
grep -q '^After=.*graphical.target.*landfall-server.service' "${FILES}/landfall-display.service"
grep -q '^ENV_FILE=.*home/landfall/landfall/deploy/.env' "${FILES}/firstboot.sh"
grep -q 'cp -r "\${STAGE_FILES}/deploy/."' "${STAGE}/00-run.sh"
grep -q '/home/landfall/landfall/display/display' "${STAGE}/00-run.sh"
grep -q 'LANDFALL_DEFAULT_SERVER_URL' "${REPO_ROOT}/deploy/pi-gen/build-display-docker.sh"
grep -q 'http://127.0.0.1:8080/' "${REPO_ROOT}/deploy/pi-gen/build-display-docker.sh"
