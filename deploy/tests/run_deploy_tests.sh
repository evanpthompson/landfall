#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

run() {
  echo "==> $*"
  "$@"
}

syntax_check() {
  local script="$1"
  run bash -n "${REPO_ROOT}/${script}"
}

syntax_check deploy/scripts/setup.sh
syntax_check deploy/scripts/backup.sh
syntax_check deploy/pi-gen/configure.sh
syntax_check deploy/pi-gen/preflight.sh
syntax_check deploy/pi-gen/build.sh
syntax_check deploy/pi-gen/build-display-docker.sh
syntax_check deploy/pi-gen/stage2-landfall/00-landfall/00-run.sh
syntax_check deploy/pi-gen/stage2-landfall/00-landfall/files/firstboot.sh
syntax_check deploy/pi-gen/stage2-landfall/00-landfall/files/landfall-doctor.sh
syntax_check deploy/pi-gen/stage2-landfall/00-landfall/files/landfall-bug-report.sh
syntax_check deploy/pi-gen/stage2-landfall/00-landfall/files/landfall-display-watchdog.sh
syntax_check deploy/pi-gen/stage2-landfall/00-landfall/files/landfall-maintenance.sh
syntax_check deploy/pi-gen/stage2-landfall/00-landfall/files/landfall-repair.sh
syntax_check deploy/pi-gen/stage2-landfall/00-landfall/files/landfall-db-check.sh
syntax_check deploy/pi-gen/stage2-landfall/00-landfall/files/landfall-update.sh
syntax_check tools/scripts/build_apk.sh
syntax_check tools/scripts/build_linux.sh
syntax_check tools/scripts/mint_api_key.sh

run python3 -m py_compile "${REPO_ROOT}/deploy/pi-gen/stage2-landfall/00-landfall/files/landfall-splash.py"
run python3 -m py_compile "${REPO_ROOT}/deploy/pi-gen/stage2-landfall/00-landfall/files/landfall-diagnostic.py"

run bash "${REPO_ROOT}/deploy/scripts/test_setup.sh"
run bash "${SCRIPT_DIR}/test_firstboot.sh"
run bash "${SCRIPT_DIR}/test_configure.sh"
run bash "${SCRIPT_DIR}/test_configure_yaml_drift.sh"
run bash "${SCRIPT_DIR}/test_build_stage_only.sh"
run bash "${SCRIPT_DIR}/test_artifact_contract.sh"
run bash "${SCRIPT_DIR}/test_fire_tv_android.sh"

echo "Deployment tests passed."
