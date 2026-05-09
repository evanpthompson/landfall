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
)

for path in "${required[@]}"; do
  [[ -f "${path}" ]] || { echo "Missing required artifact: ${path}" >&2; exit 1; }
done

[[ -x "${STAGE}/00-run.sh" ]] || { echo "00-run.sh must be executable" >&2; exit 1; }
[[ -x "${FILES}/firstboot.sh" ]] || { echo "firstboot.sh must be executable" >&2; exit 1; }
[[ -x "${FILES}/landfall-splash.py" ]] || { echo "landfall-splash.py must be executable" >&2; exit 1; }

grep -q '^Before=landfall-server.service' "${FILES}/landfall-firstboot.service"
grep -q '^After=.*docker.service.*landfall-firstboot.service' "${FILES}/landfall-server.service"
grep -q '^WorkingDirectory=/home/landfall/landfall/deploy' "${FILES}/landfall-server.service"
grep -q '^After=.*graphical.target.*landfall-server.service' "${FILES}/landfall-display.service"
grep -q '^ENV_FILE=.*home/landfall/landfall/deploy/.env' "${FILES}/firstboot.sh"
grep -q 'cp -r "\${STAGE_FILES}/deploy/."' "${STAGE}/00-run.sh"
grep -q '/home/landfall/landfall/display/display' "${STAGE}/00-run.sh"
