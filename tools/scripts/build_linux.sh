#!/usr/bin/env bash
# Build the Landfall Linux display binary.
# Must be run on a Linux host. Flutter does not support cross-compilation.
#
# Usage:
#   bash tools/scripts/build_linux.sh              # builds for the host arch
#   bash tools/scripts/build_linux.sh --arch arm64 # warns if not on arm64 Linux
#
# To build an arm64 binary for Raspberry Pi from a non-Linux machine, see:
#   docs/raspberry_pi_guide.md — Option 1b (Docker + QEMU)

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

if ! command -v flutter > /dev/null; then
  echo "flutter not found. Install it from https://docs.flutter.dev/get-started/install/linux"
  exit 1
fi

HOST_OS="$(uname -s)"
if [[ "${HOST_OS}" != "Linux" ]]; then
  echo ""
  echo "${YELLOW}✗  flutter build linux is only supported on Linux hosts.${RESET}"
  echo ""
  echo "   You are on ${HOST_OS}. To build the Linux display binary you have three options:"
  echo ""
  echo "   Option 1 — Build directly on the Pi (recommended for one-off deploys):"
  echo "     Install Flutter on the Pi, clone the repo, then run:"
  echo "       bash tools/scripts/build_linux.sh"
  echo "     Flutter install: https://docs.flutter.dev/get-started/install/linux"
  echo ""
  echo "   Option 2 — Docker + QEMU (for arm64 from any OS with Docker):"
  echo "     docker run --rm --platform linux/arm64 \\"
  echo "       -v \"\$(pwd)\":/app -w /app/apps/display \\"
  echo "       ghcr.io/cirruslabs/flutter:stable \\"
  echo "       bash -c \"apt-get update -q && apt-get install -y cmake ninja-build clang libgtk-3-dev pkg-config libblkid-dev liblzma-dev libsecret-1-dev && flutter build linux --release\""
  echo "     Output: apps/display/build/linux/aarch64/release/bundle/"
  echo ""
  echo "   Option 3 — GitHub Actions (CI build, no local Linux needed):"
  echo "     Push your branch and let the build workflow produce the artifact."
  echo ""
  exit 1
fi

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
    warn "Requested arm64 but running on ${HOST_ARCH}."
    warn "Flutter does not support cross-compilation — building for host arch instead."
    warn "The resulting binary will NOT run on a Raspberry Pi."
    warn "To get an arm64 binary, build on an arm64 Linux machine or use Docker + QEMU."
    warn ""
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
