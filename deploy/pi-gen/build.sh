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

# ── Fix permissions from previous Docker run ─────────────────────────────
# Docker containers run as root, leaving root-owned files in the work dir.
# Fix them before doing anything so subsequent cp/rsync steps don't fail.
if [[ -d "${WORK_DIR}" ]]; then
  sudo chown -R "$(whoami)" "${WORK_DIR}" 2>/dev/null || true
fi

# ── Clone or update pi-gen (arm64 branch) ────────────────────────────────
# The master branch builds 32-bit Raspbian (armhf) from raspbian.raspberrypi.com
# using SHA1-signed keys — rejected by modern GnuPG. The arm64 branch builds
# 64-bit Raspberry Pi OS from archive.raspberrypi.com with proper modern keys.
# We need arm64 for our Flutter arm64 display binary anyway.
PI_GEN_DIR="${WORK_DIR}/pi-gen"
if [[ -d "${PI_GEN_DIR}" ]]; then
  CURRENT_BRANCH="$(git -C "${PI_GEN_DIR}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
  if [[ "${CURRENT_BRANCH}" != "arm64" ]]; then
    info "Switching pi-gen to arm64 branch..."
    rm -rf "${PI_GEN_DIR}"
  fi
fi
if [[ -d "${PI_GEN_DIR}" ]]; then
  info "Updating pi-gen..."
  git -C "${PI_GEN_DIR}" pull --quiet
else
  info "Cloning pi-gen (arm64 branch)..."
  mkdir -p "${WORK_DIR}"
  git clone --quiet --depth=1 --branch arm64 https://github.com/RPi-Distro/pi-gen.git "${PI_GEN_DIR}"
fi
ok "pi-gen ready (arm64)"

# ── Patch pi-gen Dockerfile ───────────────────────────────────────────────
# Insert a weekly cache-buster ARG before the apt-get install layer so the
# keyring (debian-archive-keyring) gets refreshed at least once per week.
# Stale keyrings cause "E: Invalid Release signature" in debootstrap.
CACHE_WEEK="$(date +%Y-W%V)"
if ! grep -q "LANDFALL_CACHE_WEEK" "${PI_GEN_DIR}/Dockerfile"; then
  # Insert ARG line before the RUN apt-get line using Python (macOS sed doesn't
  # support \n in replacement strings)
  python3 -c "
import sys
txt = open('${PI_GEN_DIR}/Dockerfile').read()
txt = txt.replace(
  'ENV DEBIAN_FRONTEND=noninteractive\n\nRUN apt-get',
  'ENV DEBIAN_FRONTEND=noninteractive\n\nARG LANDFALL_CACHE_WEEK=${CACHE_WEEK}\nRUN apt-get'
)
open('${PI_GEN_DIR}/Dockerfile', 'w').write(txt)
"
  info "Patched pi-gen Dockerfile: added weekly cache-buster (${CACHE_WEEK})"
else
  sed -i '' "s/ARG LANDFALL_CACHE_WEEK=.*/ARG LANDFALL_CACHE_WEEK=${CACHE_WEEK}/" \
    "${PI_GEN_DIR}/Dockerfile"
fi

# Pass the cache week to docker build so the ARG actually invalidates the layer.
# build-docker.sh hard-codes the --build-arg list, so patch it each run.
if grep -q "LANDFALL_CACHE_WEEK" "${PI_GEN_DIR}/build-docker.sh"; then
  sed -i '' "s/LANDFALL_CACHE_WEEK=[^ ]*/LANDFALL_CACHE_WEEK=${CACHE_WEEK}/" \
    "${PI_GEN_DIR}/build-docker.sh"
else
  sed -i '' "s|--build-arg BASE_IMAGE=\${BASE_IMAGE}|--build-arg BASE_IMAGE=\${BASE_IMAGE} --build-arg LANDFALL_CACHE_WEEK=${CACHE_WEEK}|" \
    "${PI_GEN_DIR}/build-docker.sh"
fi

# Remove the cached pi-gen Docker image whenever the week changes so apt-get
# re-runs and fetches a fresh debian-archive-keyring. Without this, stale
# keyrings cause "E: Invalid Release signature" in debootstrap.
LAST_WEEK_FILE="${WORK_DIR}/.last_cache_week"
LAST_WEEK="$(cat "${LAST_WEEK_FILE}" 2>/dev/null || echo "")"
if [[ "${LAST_WEEK}" != "${CACHE_WEEK}" ]]; then
  info "Cache week changed (${LAST_WEEK:-none} → ${CACHE_WEEK}), removing stale Docker image..."
  docker rmi pi-gen > /dev/null 2>&1 || true
  mkdir -p "${WORK_DIR}"
  echo "${CACHE_WEEK}" > "${LAST_WEEK_FILE}"
fi

# pi-gen's base image (i386/debian) doesn't include qemu-user-static.
# Without it the ARM chroot has no interpreter binary, even if binfmt_misc
# is registered on the host. Append it to the apt-get install layer.
if ! grep -q "qemu-user-static" "${PI_GEN_DIR}/Dockerfile"; then
  echo 'RUN apt-get install -y qemu-user-static' >> "${PI_GEN_DIR}/Dockerfile"
  info "Patched pi-gen Dockerfile: added qemu-user-static"
fi

# ── Patch pi-gen build-docker.sh (macOS only) ────────────────────────────
# pi-gen's build-docker.sh checks for `qemu-arm` on the HOST before starting
# Docker. On macOS this binary doesn't exist — binfmt is already registered
# in Docker Desktop's Linux VM by the tonistiigi/binfmt step above. Patch
# the script to skip the host-side check entirely on non-Linux hosts.
if [[ "${HOST_OS}" != "Linux" ]]; then
  if ! grep -q "# Landfall: macOS binfmt skip" "${PI_GEN_DIR}/build-docker.sh"; then
    sed -i '' '/^binfmt_misc_required=1$/s/=1/=0 # Landfall: macOS binfmt skip/' \
      "${PI_GEN_DIR}/build-docker.sh"
    info "Patched build-docker.sh: disabled host binfmt check (handled by Docker Desktop)"
  fi
fi

# ── Copy Landfall stage into pi-gen ──────────────────────────────────────
cp "${SCRIPT_DIR}/config"                          "${PI_GEN_DIR}/config"
rm -rf "${PI_GEN_DIR}/stage2-landfall"
cp -r "${SCRIPT_DIR}/stage2-landfall"              "${PI_GEN_DIR}/stage2-landfall"

# Copy only the runtime deploy files — not deploy/pi-gen/ (build tooling).
# Using rsync --exclude avoids the recursive-copy-into-itself problem that
# occurs because PI_GEN_DIR lives inside the deploy/ tree.
DEPLOY_DEST="${PI_GEN_DIR}/stage2-landfall/00-landfall/files/deploy"
mkdir -p "${DEPLOY_DEST}"
rsync -a --exclude='pi-gen/' "${REPO_ROOT}/deploy/" "${DEPLOY_DEST}/"

# Skip heavy/unnecessary stages: we only need stage0 (base), stage1, stage2 (lite), stage2-landfall
touch "${PI_GEN_DIR}/stage3/SKIP"
touch "${PI_GEN_DIR}/stage4/SKIP"
touch "${PI_GEN_DIR}/stage5/SKIP"

# ── Build ─────────────────────────────────────────────────────────────────
# Remove any stale container from a previous failed run so build-docker.sh
# doesn't abort asking the user to set CONTINUE=1.
docker rm -v pigen_work > /dev/null 2>&1 || true

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
