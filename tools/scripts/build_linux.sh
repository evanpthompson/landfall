#!/usr/bin/env bash
# Build the Landfall Linux display binary.
# On a Mac/x86 host, pass --arch arm64 to cross-compile for Raspberry Pi.
#
# Usage:
#   bash tools/scripts/build_linux.sh              # native (host arch)
#   bash tools/scripts/build_linux.sh --arch arm64 # cross-compile for Pi

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DISPLAY_DIR="${REPO_ROOT}/apps/display"

BOLD=$'\033[1m'
GREEN=$'\033[1;32m'
CYAN=$'\033[1;36m'
YELLOW=$'\033[1;33m'
RESET=$'\033[0m'

ok()   { echo "${GREEN}✓  $*${RESET}"; }
info() { echo "   $*"; }
warn() { echo "${YELLOW}⚠  $*${RESET}"; }

TARGET_ARCH=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --arch) TARGET_ARCH="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo ""
echo "${CYAN}${BOLD}Landfall — Linux display build${RESET}"
echo ""

command -v flutter > /dev/null || { echo "flutter not found"; exit 1; }

cd "${DISPLAY_DIR}"

# Ensure Linux platform files are present
if [[ ! -f "linux/CMakeLists.txt" ]]; then
  info "Adding Linux platform..."
  flutter create --platforms=linux .
  ok "Linux platform added"
fi

if [[ "${TARGET_ARCH}" == "arm64" ]]; then
  HOST_ARCH="$(uname -m)"
  if [[ "${HOST_ARCH}" != "aarch64" && "${HOST_ARCH}" != "arm64" ]]; then
    warn "Cross-compiling arm64 on ${HOST_ARCH}."
    warn "Flutter does not support cross-compilation natively."
    warn "For a Pi 4 binary, build directly on a Pi 4 or use a Pi 4 as a build machine."
    warn ""
    warn "To build on a Pi 4:"
    warn "  1. Install Flutter on the Pi:  flutter.dev/docs/get-started/install/linux"
    warn "  2. Clone the repo and run:     bash tools/scripts/build_linux.sh"
    warn ""
    warn "Falling back to native build (host arch: ${HOST_ARCH})..."
  fi
fi

info "Building release binary..."
flutter build linux --release

BUNDLE="${DISPLAY_DIR}/build/linux/$(uname -m | sed 's/x86_64/x64/')/release/bundle"
ok "Binary ready: ${BUNDLE}"
info ""
info "Run locally:  ${BUNDLE}/display"
info ""
info "To deploy to a Pi manually:"
info "  rsync -av ${BUNDLE}/ landfall@<PI_IP>:/home/landfall/landfall/display/"
info "  ssh landfall@<PI_IP> 'sudo systemctl restart landfall-display'"
echo ""
