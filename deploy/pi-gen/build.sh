#!/usr/bin/env bash
# Build the Landfall Raspberry Pi SD card image.
#
# Run configure.sh first to set WiFi, hostname, domain, and generate secrets.
# This script handles everything else automatically:
#   1. Builds the Flutter arm64 display binary (via Docker + QEMU, ~20 min)
#   2. Cross-compiles the server Docker image for arm64 (~20–40 min)
#   3. Runs pi-gen to produce a bootable .img (~20 min)
#
# The resulting image is fully self-contained — flash it, boot it, done.
#
# Usage:  bash deploy/pi-gen/build.sh
# Output: deploy/pi-gen/work/pi-gen/deploy/<date>-landfall.img

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
warn() { echo "${YELLOW}⚠  $*${RESET}"; }
die()  { echo "${RED}✗  $*${RESET}"; exit 1; }

gen_secret()     { openssl rand -base64 32 | tr -d '\n/+=' | cut -c1-43; }
gen_hex_secret() { openssl rand -hex 32; }

echo ""
echo "${CYAN}${BOLD}Landfall — Raspberry Pi image builder${RESET}"
echo ""

# ── Load build configuration ───────────────────────────────────────────────
CONF_FILE="${SCRIPT_DIR}/landfall-build.conf"
if [[ -f "${CONF_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${CONF_FILE}"
  ok "Loaded build config: ${CONF_FILE}"
else
  warn "landfall-build.conf not found — run configure.sh first for WiFi and custom settings."
  warn "Continuing with defaults (no WiFi, landfall.local, auto-generated secrets)."
fi

# Apply defaults for any unset variables
WIFI_COUNTRY="${WIFI_COUNTRY:-US}"
WIFI_SSID="${WIFI_SSID:-}"
WIFI_PASSWORD="${WIFI_PASSWORD:-}"
PI_HOSTNAME="${PI_HOSTNAME:-landfall}"
LANDFALL_DOMAIN="${LANDFALL_DOMAIN:-landfall.local}"
OWM_API_KEY="${OWM_API_KEY:-}"
DB_NAME="${DB_NAME:-landfall}"
DB_USER="${DB_USER:-landfall}"
DB_PASSWORD="${DB_PASSWORD:-$(gen_secret)}"
REDIS_PASSWORD="${REDIS_PASSWORD:-$(gen_secret)}"
SERVERPOD_SERVICE_SECRET="${SERVERPOD_SERVICE_SECRET:-$(gen_secret)}"
JWT_HMAC_KEY="${JWT_HMAC_KEY:-$(gen_secret)}"
JWT_REFRESH_PEPPER="${JWT_REFRESH_PEPPER:-$(gen_secret)}"
API_KEY_MANAGEMENT_TOKEN="${API_KEY_MANAGEMENT_TOKEN:-$(gen_secret)}"
API_KEY_HMAC_SECRET="${API_KEY_HMAC_SECRET:-$(gen_secret)}"
PHOTO_SIGNING_SECRET="${PHOTO_SIGNING_SECRET:-$(gen_secret)}"
OAUTH_TOKEN_ENCRYPTION_KEY="${OAUTH_TOKEN_ENCRYPTION_KEY:-$(gen_hex_secret)}"
GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-}"
GOOGLE_CLIENT_SECRET="${GOOGLE_CLIENT_SECRET:-}"
GOOGLE_REDIRECT_URI="${GOOGLE_REDIRECT_URI:-}"
GOOGLE_DRIVE_FOLDER_ID="${GOOGLE_DRIVE_FOLDER_ID:-}"
MICROSOFT_CLIENT_ID="${MICROSOFT_CLIENT_ID:-}"
MICROSOFT_CLIENT_SECRET="${MICROSOFT_CLIENT_SECRET:-}"
MICROSOFT_REDIRECT_URI="${MICROSOFT_REDIRECT_URI:-}"
STRIPE_WEBHOOK_SECRET="${STRIPE_WEBHOOK_SECRET:-}"

# ── Preflight ─────────────────────────────────────────────────────────────────
command -v docker > /dev/null || die "Docker is not installed"

HOST_OS="$(uname -s)"
if [[ "${HOST_OS}" == "Linux" ]]; then
  command -v qemu-arm > /dev/null 2>&1 \
    || die "qemu-arm not found — install with: sudo apt-get install qemu-user-binfmt"
else
  info "Registering QEMU ARM binfmt handlers in Docker Desktop VM..."
  docker run --privileged --rm tonistiigi/binfmt --install arm > /dev/null 2>&1 \
    && ok "QEMU ARM binfmt registered" \
    || die "Failed to register QEMU binfmt handlers. Is Docker running?"
fi

# ── Step 1: Flutter arm64 display binary ─────────────────────────────────────
LINUX_BUNDLE="${REPO_ROOT}/apps/display/build/linux/arm64/release/bundle"
if [[ -d "${LINUX_BUNDLE}" ]]; then
  ok "Flutter arm64 binary found: ${LINUX_BUNDLE}"
else
  echo ""
  info "Flutter arm64 binary not found — building via Docker + QEMU (~20 min)..."
  info "This runs the arm64 Flutter toolchain under QEMU emulation."
  echo ""

  cat > /tmp/lf-display-build.sh << 'BUILDSCRIPT'
apt-get update -q && apt-get install -y --no-install-recommends \
  cmake ninja-build clang libgtk-3-dev pkg-config \
  libblkid-dev liblzma-dev libsecret-1-dev lld
flutter build linux --release
BUILDSCRIPT

  docker run --rm --platform linux/arm64 \
    -v "${REPO_ROOT}":/app \
    -v /tmp/lf-display-build.sh:/lf-build.sh \
    -w /app/apps/display \
    ghcr.io/cirruslabs/flutter:stable \
    bash /lf-build.sh

  [[ -d "${LINUX_BUNDLE}" ]] \
    || die "Flutter build finished but bundle not found at ${LINUX_BUNDLE}"
  ok "Flutter arm64 binary built"
fi

# ── Fix permissions from previous Docker run ──────────────────────────────────
if [[ -d "${WORK_DIR}" ]]; then
  sudo chown -R "$(whoami)" "${WORK_DIR}" 2>/dev/null || true
fi

# ── Clone or update pi-gen (arm64 branch) ────────────────────────────────────
PI_GEN_DIR="${WORK_DIR}/pi-gen"
if [[ -d "${PI_GEN_DIR}" ]]; then
  CURRENT_BRANCH="$(git -C "${PI_GEN_DIR}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
  if [[ "${CURRENT_BRANCH}" != "arm64" ]]; then
    info "Switching pi-gen clone to arm64 branch..."
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

# ── Copy Landfall stage into pi-gen ───────────────────────────────────────────
cp "${SCRIPT_DIR}/config" "${PI_GEN_DIR}/config"
# Inject hostname and WiFi country into pi-gen config
sed -i '' "s/^TARGET_HOSTNAME=.*/TARGET_HOSTNAME=\"${PI_HOSTNAME}\"/" "${PI_GEN_DIR}/config"
if grep -q "^WPA_COUNTRY=" "${PI_GEN_DIR}/config"; then
  sed -i '' "s/^WPA_COUNTRY=.*/WPA_COUNTRY=\"${WIFI_COUNTRY}\"/" "${PI_GEN_DIR}/config"
else
  echo "WPA_COUNTRY=\"${WIFI_COUNTRY}\"" >> "${PI_GEN_DIR}/config"
fi

rm -rf "${PI_GEN_DIR}/stage2-landfall"
cp -r "${SCRIPT_DIR}/stage2-landfall" "${PI_GEN_DIR}/stage2-landfall"

STAGE_FILES="${PI_GEN_DIR}/stage2-landfall/00-landfall/files"

# ── Stage: deploy directory ───────────────────────────────────────────────────
DEPLOY_DEST="${STAGE_FILES}/deploy"
mkdir -p "${DEPLOY_DEST}"
rsync -a --exclude='pi-gen/' "${REPO_ROOT}/deploy/" "${DEPLOY_DEST}/"

# ── Stage: .env ───────────────────────────────────────────────────────────────
cat > "${STAGE_FILES}/.env" << ENVFILE
LANDFALL_DOMAIN=${LANDFALL_DOMAIN}
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
REDIS_PASSWORD=${REDIS_PASSWORD}
SERVERPOD_SERVICE_SECRET=${SERVERPOD_SERVICE_SECRET}
JWT_HMAC_KEY=${JWT_HMAC_KEY}
JWT_REFRESH_PEPPER=${JWT_REFRESH_PEPPER}
API_KEY_MANAGEMENT_TOKEN=${API_KEY_MANAGEMENT_TOKEN}
API_KEY_HMAC_SECRET=${API_KEY_HMAC_SECRET}
PHOTO_SIGNING_SECRET=${PHOTO_SIGNING_SECRET}
OAUTH_TOKEN_ENCRYPTION_KEY=${OAUTH_TOKEN_ENCRYPTION_KEY}
OWM_API_KEY=${OWM_API_KEY}
GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}
GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}
GOOGLE_REDIRECT_URI=${GOOGLE_REDIRECT_URI}
GOOGLE_DRIVE_FOLDER_ID=${GOOGLE_DRIVE_FOLDER_ID}
MICROSOFT_CLIENT_ID=${MICROSOFT_CLIENT_ID}
MICROSOFT_CLIENT_SECRET=${MICROSOFT_CLIENT_SECRET}
MICROSOFT_REDIRECT_URI=${MICROSOFT_REDIRECT_URI}
STRIPE_WEBHOOK_SECRET=${STRIPE_WEBHOOK_SECRET}
ENVFILE
info ".env staged for domain: ${LANDFALL_DOMAIN}"

# ── Stage: WiFi country ───────────────────────────────────────────────────────
echo "${WIFI_COUNTRY}" > "${STAGE_FILES}/wifi-country"
ok "WiFi country staged: ${WIFI_COUNTRY}"

# ── Stage: WiFi config ────────────────────────────────────────────────────────
if [[ -n "${WIFI_SSID}" ]]; then
  cat > "${STAGE_FILES}/wifi.nmconnection" << WIFICONF
[connection]
id=landfall-wifi
type=wifi
autoconnect=true
autoconnect-priority=600

[wifi]
mode=infrastructure
ssid=${WIFI_SSID}

[wifi-security]
auth-alg=open
key-mgmt=wpa-psk
psk=${WIFI_PASSWORD}

[ipv4]
method=auto

[ipv6]
method=auto
addr-gen-mode=default
WIFICONF
  ok "WiFi config staged for: ${WIFI_SSID}"
else
  rm -f "${STAGE_FILES}/wifi.nmconnection"
  info "No WiFi configured — connect via ethernet or configure after first boot"
fi

# ── Stage: Flutter display bundle ─────────────────────────────────────────────
BUNDLE_DEST="${STAGE_FILES}/bundle"
rm -rf "${BUNDLE_DEST}"
cp -r "${LINUX_BUNDLE}/." "${BUNDLE_DEST}/"
ok "Display bundle staged ($(du -sh "${BUNDLE_DEST}" | cut -f1))"

# ── Step 2: Server Docker image for arm64 ────────────────────────────────────
SERVER_TARBALL="${STAGE_FILES}/landfall-server.tar.gz"
if [[ -f "${SERVER_TARBALL}" ]]; then
  ok "Server image already staged ($(du -sh "${SERVER_TARBALL}" | cut -f1)) — delete to rebuild"
else
  echo ""
  info "Cross-compiling server Docker image for arm64 (~20–40 min)..."
  info "This compiles the Dart server to a native arm64 binary under QEMU."
  echo ""

  # Ensure a buildx builder that supports arm64 exists
  if ! docker buildx inspect landfall-builder > /dev/null 2>&1; then
    docker buildx create --name landfall-builder \
      --platform linux/arm64,linux/amd64 --use > /dev/null
  else
    docker buildx use landfall-builder
  fi

  docker buildx build \
    --platform linux/arm64 \
    --load \
    -t landfall-server:latest \
    -f "${REPO_ROOT}/server/landfall_server/Dockerfile" \
    "${REPO_ROOT}"

  docker save landfall-server:latest | gzip > "${SERVER_TARBALL}"
  ok "Server image built and staged ($(du -sh "${SERVER_TARBALL}" | cut -f1))"
fi

# ── Patch pi-gen Dockerfile: weekly cache-buster ──────────────────────────────
CACHE_WEEK="$(date +%Y-W%V)"
if ! grep -q "LANDFALL_CACHE_WEEK" "${PI_GEN_DIR}/Dockerfile"; then
  python3 -c "
txt = open('${PI_GEN_DIR}/Dockerfile').read()
txt = txt.replace(
  'ENV DEBIAN_FRONTEND=noninteractive\n\nRUN apt-get',
  'ENV DEBIAN_FRONTEND=noninteractive\n\nARG LANDFALL_CACHE_WEEK=${CACHE_WEEK}\nRUN apt-get'
)
open('${PI_GEN_DIR}/Dockerfile', 'w').write(txt)
"
else
  sed -i '' "s/ARG LANDFALL_CACHE_WEEK=.*/ARG LANDFALL_CACHE_WEEK=${CACHE_WEEK}/" \
    "${PI_GEN_DIR}/Dockerfile"
fi

if grep -q "LANDFALL_CACHE_WEEK" "${PI_GEN_DIR}/build-docker.sh"; then
  sed -i '' "s/LANDFALL_CACHE_WEEK=[^ ]*/LANDFALL_CACHE_WEEK=${CACHE_WEEK}/" \
    "${PI_GEN_DIR}/build-docker.sh"
else
  sed -i '' "s|--build-arg BASE_IMAGE=\${BASE_IMAGE}|--build-arg BASE_IMAGE=\${BASE_IMAGE} --build-arg LANDFALL_CACHE_WEEK=${CACHE_WEEK}|" \
    "${PI_GEN_DIR}/build-docker.sh"
fi

LAST_WEEK_FILE="${WORK_DIR}/.last_cache_week"
LAST_WEEK="$(cat "${LAST_WEEK_FILE}" 2>/dev/null || echo "")"
if [[ "${LAST_WEEK}" != "${CACHE_WEEK}" ]]; then
  info "Cache week changed — removing stale Docker image to refresh keyring..."
  docker rmi pi-gen > /dev/null 2>&1 || true
  mkdir -p "${WORK_DIR}"
  echo "${CACHE_WEEK}" > "${LAST_WEEK_FILE}"
fi

# ── Patch pi-gen build-docker.sh (macOS only) ────────────────────────────────
if [[ "${HOST_OS}" != "Linux" ]]; then
  if ! grep -q "# Landfall: macOS binfmt skip" "${PI_GEN_DIR}/build-docker.sh"; then
    sed -i '' '/^binfmt_misc_required=1$/s/=1/=0 # Landfall: macOS binfmt skip/' \
      "${PI_GEN_DIR}/build-docker.sh"
  fi
fi

# ── Stage skips ───────────────────────────────────────────────────────────────
touch "${PI_GEN_DIR}/stage2/SKIP_IMAGES"
touch "${PI_GEN_DIR}/stage3/SKIP" "${PI_GEN_DIR}/stage3/SKIP_IMAGES"
touch "${PI_GEN_DIR}/stage4/SKIP" "${PI_GEN_DIR}/stage4/SKIP_IMAGES"
touch "${PI_GEN_DIR}/stage5/SKIP" "${PI_GEN_DIR}/stage5/SKIP_IMAGES"

# ── Step 3: Run pi-gen ────────────────────────────────────────────────────────
docker rm -v pigen_work > /dev/null 2>&1 || true

echo ""
info "Running pi-gen — this takes 20–40 minutes..."
echo ""

cd "${PI_GEN_DIR}"
bash build-docker.sh

# ── Done ─────────────────────────────────────────────────────────────────────
IMAGE="$(ls "${PI_GEN_DIR}/deploy/"*.img 2>/dev/null | sort | tail -1)"
if [[ -n "${IMAGE}" ]]; then
  echo ""
  ok "Image ready: ${IMAGE}"
  info ""
  info "Flash with Raspberry Pi Imager (\"Use custom image\") or:"
  info "  sudo dd if=${IMAGE} of=/dev/rdiskN bs=4m status=progress"
  info ""
  info "First boot takes ~2 minutes while Docker images load."
  info "The display starts automatically after the server is ready."
else
  die "Build finished but no .img found in ${PI_GEN_DIR}/deploy/"
fi
