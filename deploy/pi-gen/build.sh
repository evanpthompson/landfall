#!/usr/bin/env bash
# Build the Landfall Raspberry Pi image using pi-gen via Docker.
#
# Works on Linux and macOS (Docker Desktop).
# pi-gen requires QEMU ARM binfmt handlers to be registered. On Linux install
# qemu-user-binfmt; on macOS this script registers them automatically via
# tonistiigi/binfmt before starting the build.
#
# Prerequisites:
#   - Docker installed
#   - Linux display binary built first (see docs/raspberry_pi_guide.md)
#
# Usage:  bash deploy/pi-gen/build.sh
#
# Output: deploy/pi-gen/work/landfall-<date>-lite.img.xz

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WORK_DIR="${SCRIPT_DIR}/work"

BOLD=$'\033[1m'
GREEN=$'\033[1;32m'
CYAN=$'\033[1;36m'
YELLOW=$'\033[1;33m'
RED=$'\033[1;31m'
RESET=$'\033[0m'

ok()   { echo "${GREEN}✓  $*${RESET}"; }
info() { echo "   $*"; }
die()  { echo "${RED}✗  $*${RESET}"; exit 1; }

echo ""
echo "${CYAN}${BOLD}Landfall — Raspberry Pi image builder${RESET}"
echo ""

# ── Preflight ─────────────────────────────────────────────────────────────
command -v docker > /dev/null || die "Docker is not installed"

# pi-gen needs QEMU ARM binfmt handlers registered so its chroot can execute
# ARM binaries. On Linux, install qemu-user-binfmt. On macOS Docker Desktop,
# tonistiigi/binfmt registers the same handlers in the Docker VM.
HOST_OS="$(uname -s)"
if [[ "${HOST_OS}" == "Linux" ]]; then
  if ! command -v qemu-arm > /dev/null 2>&1; then
    die "qemu-arm not found. Install it with: sudo apt-get install qemu-user-binfmt"
  fi
else
  info "Registering QEMU ARM binfmt handlers in Docker Desktop VM..."
  docker run --privileged --rm tonistiigi/binfmt --install arm > /dev/null 2>&1 \
    && ok "QEMU ARM binfmt registered" \
    || die "Failed to register QEMU binfmt handlers. Is Docker running?"
fi

LINUX_BUNDLE="${REPO_ROOT}/apps/display/build/linux/arm64/release/bundle"
if [[ ! -d "${LINUX_BUNDLE}" ]]; then
  echo "${YELLOW}⚠  Linux arm64 display binary not found at:${RESET}"
  info "   ${LINUX_BUNDLE}"
  echo ""
  info "Build it first. Flutter cannot cross-compile, so you need one of:"
  info ""
  info "  Option 1 — Build directly on a Pi (takes ~15 min):"
  info "    Install Flutter on the Pi, clone the repo, then run:"
  info "      bash tools/scripts/build_linux.sh"
  info "    Flutter install: https://docs.flutter.dev/get-started/install/linux"
  info ""
  info "  Option 2 — Docker + QEMU (from any machine with Docker):"
  info "    cat > /tmp/lf-build.sh << 'EOF'"
  info "    apt-get update -q && apt-get install -y cmake ninja-build clang \\"
  info "      libgtk-3-dev pkg-config libblkid-dev liblzma-dev libsecret-1-dev lld"
  info "    flutter build linux --release"
  info "    EOF"
  info "    docker run --rm --platform linux/arm64 \\"
  info "      -v \"\$(pwd)\":/app -v /tmp/lf-build.sh:/lf-build.sh \\"
  info "      -w /app/apps/display ghcr.io/cirruslabs/flutter:stable bash /lf-build.sh"
  echo ""
  die "Missing display binary — see instructions above"
fi
ok "Display binary found: ${LINUX_BUNDLE}"

# ── Clone or update pi-gen ────────────────────────────────────────────────
PI_GEN_DIR="${WORK_DIR}/pi-gen"
if [[ -d "${PI_GEN_DIR}" ]]; then
  info "Updating pi-gen..."
  git -C "${PI_GEN_DIR}" pull --quiet
else
  info "Cloning pi-gen..."
  mkdir -p "${WORK_DIR}"
  git clone --quiet --depth=1 https://github.com/RPi-Distro/pi-gen.git "${PI_GEN_DIR}"
fi
ok "pi-gen ready"

# ── Patch pi-gen Dockerfile ───────────────────────────────────────────────
# pi-gen's base image (i386/debian) doesn't include qemu-user-static.
# Without it the ARM chroot has no interpreter binary, even if binfmt_misc
# is registered on the host. Append it to the apt-get install layer.
if ! grep -q "qemu-user-static" "${PI_GEN_DIR}/Dockerfile"; then
  echo 'RUN apt-get install -y qemu-user-static' >> "${PI_GEN_DIR}/Dockerfile"
  info "Patched pi-gen Dockerfile: added qemu-user-static"
fi

# ── Copy Landfall stage into pi-gen ──────────────────────────────────────
cp "${SCRIPT_DIR}/config"                          "${PI_GEN_DIR}/config"
cp -r "${SCRIPT_DIR}/stage-landfall"               "${PI_GEN_DIR}/stage-landfall"
cp -r "${REPO_ROOT}/deploy"                        "${PI_GEN_DIR}/stage-landfall/00-landfall/files/deploy"

# Skip heavy/unnecessary stages: we only need stage0 (base), stage1, stage2 (lite), stage-landfall
touch "${PI_GEN_DIR}/stage3/SKIP"
touch "${PI_GEN_DIR}/stage4/SKIP"
touch "${PI_GEN_DIR}/stage5/SKIP"

# ── Build ─────────────────────────────────────────────────────────────────
echo ""
info "Starting pi-gen Docker build — this takes 20–40 minutes..."
echo ""

cd "${PI_GEN_DIR}"
bash build-docker.sh

# ── Copy output ───────────────────────────────────────────────────────────
IMAGE="$(ls "${PI_GEN_DIR}/deploy"/landfall-*.img.xz 2>/dev/null | sort | tail -1)"
if [[ -n "${IMAGE}" ]]; then
  cp "${IMAGE}" "${WORK_DIR}/"
  echo ""
  ok "Image ready: ${WORK_DIR}/$(basename "${IMAGE}")"
  info ""
  info "Flash with Raspberry Pi Imager (\"Use custom image\") or:"
  info "  xz -d ${WORK_DIR}/$(basename "${IMAGE}")"
  info "  sudo dd if=${WORK_DIR}/landfall-*.img of=/dev/sdX bs=4M status=progress"
else
  die "Build succeeded but no image file found in ${PI_GEN_DIR}/deploy/"
fi
