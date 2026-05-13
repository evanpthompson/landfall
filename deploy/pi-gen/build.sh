#!/usr/bin/env bash
# Build the Landfall Raspberry Pi SD card image.
#
# Produces a generic image that is configured via Raspberry Pi Imager when
# flashing (WiFi, hostname, SSH). All secrets are generated on the Pi at
# first boot — nothing sensitive is baked into the image.
#
# Optionally run configure.sh first to bake in API integration credentials
# (Google Calendar, Microsoft Calendar, weather, Stripe).
#
# Steps:
#   1. Build the Flutter arm64 display binary (Docker + QEMU, ~20 min)
#   2. Cross-compile the server Docker image for arm64 (~20–40 min)
#   3. Run pi-gen to assemble the bootable .img (~20 min)
#
# Usage:  bash deploy/pi-gen/build.sh
# Output: deploy/pi-gen/work/pi-gen/deploy/<date>-landfall.img

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${LANDFALL_REPO_ROOT:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
WORK_DIR="${LANDFALL_WORK_DIR:-${SCRIPT_DIR}/work}"
PI_GEN_DIR="${LANDFALL_PI_GEN_DIR:-${WORK_DIR}/pi-gen}"
STAGE_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stage-only|--dry-run)
      STAGE_ONLY=1
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

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
sed_in_place() {
  local expr="$1"
  local file="$2"
  if sed --version > /dev/null 2>&1; then
    sed -i "${expr}" "${file}"
  else
    sed -i '' "${expr}" "${file}"
  fi
}

echo ""
echo "${CYAN}${BOLD}Landfall — Raspberry Pi image builder${RESET}"
echo ""

# ── Load build configuration ──────────────────────────────────────────────────
CONF_FILE="${SCRIPT_DIR}/landfall-build.conf"
LANDFALL_BUILD_TYPE="production"
LANDFALL_TELEMETRY_ENDPOINT=""
LANDFALL_TELEMETRY_API_KEY=""
WIFI_COUNTRY="US"
WIFI_SSID=""
WIFI_PASSWORD=""
PI_HOSTNAME="landfall"
PI_TIMEZONE="Etc/UTC"
SSH_AUTHORIZED_KEY=""
SSH_PASSWORD=""
STATIC_IP_CIDR=""
STATIC_GATEWAY=""
STATIC_DNS=""
STATIC_INTERFACE="eth0"
SMTP_HOST=""
SMTP_PORT="587"
SMTP_USERNAME=""
SMTP_PASSWORD=""
SMTP_FROM_EMAIL=""
SMTP_FROM_NAME="Landfall"
SMTP_SSL="false"
SMTP_ALLOW_INSECURE="false"
OWM_API_KEY=""
WEATHER_LATITUDE=""
WEATHER_LONGITUDE=""
WEATHER_LOCATION_NAME=""
GOOGLE_CLIENT_ID=""
GOOGLE_CLIENT_SECRET=""
GOOGLE_DRIVE_FOLDER_ID=""
MICROSOFT_CLIENT_ID=""
MICROSOFT_CLIENT_SECRET=""
STRIPE_WEBHOOK_SECRET=""

if [[ -f "${CONF_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${CONF_FILE}"
  ok "Loaded build config: ${CONF_FILE}"
else
  warn "landfall-build.conf not found — run configure.sh first to set WiFi and hostname."
  warn "Continuing with defaults: no WiFi, hostname=landfall."
fi

# Debug builds default to local-loopback telemetry on the Pi's own server.
# Operator can still override with an explicit endpoint in the conf for fleet
# telemetry. Production builds leave the endpoint empty — display Telemetry
# class compiles to a no-op (see apps/display/lib/src/app/telemetry.dart).
if [[ "${LANDFALL_BUILD_TYPE}" == "debug" && -z "${LANDFALL_TELEMETRY_ENDPOINT}" ]]; then
  LANDFALL_TELEMETRY_ENDPOINT="http://127.0.0.1:8080/api/v1/telemetry/event"
  info "Debug build: telemetry will post to local loopback (no API key required)"
fi
export LANDFALL_TELEMETRY_ENDPOINT LANDFALL_TELEMETRY_API_KEY

# ── Preflight ─────────────────────────────────────────────────────────────────
if (( STAGE_ONLY == 0 )); then
  command -v docker > /dev/null || die "Docker is not installed"
fi

HOST_OS="$(uname -s)"
if (( STAGE_ONLY == 0 )); then
  if [[ "${HOST_OS}" == "Linux" ]]; then
    if ! command -v qemu-aarch64 > /dev/null 2>&1 && \
       [[ ! -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ]]; then
      die "qemu-aarch64 not found — install with: sudo apt-get install qemu-user-binfmt"
    fi
  else
    info "Registering QEMU ARM64 binfmt handlers in Docker Desktop VM..."
    docker run --privileged --rm tonistiigi/binfmt --install arm64 > /dev/null 2>&1 \
      && ok "QEMU ARM64 binfmt registered" \
      || die "Failed to register QEMU binfmt handlers. Is Docker running?"
  fi
fi

# ── Step 1: Flutter arm64 display binary ─────────────────────────────────────
LINUX_BUNDLE="${LANDFALL_LINUX_BUNDLE:-${REPO_ROOT}/apps/display/build/linux/arm64/release/bundle}"
if [[ -d "${LINUX_BUNDLE}" ]]; then
  ok "Flutter arm64 binary found: ${LINUX_BUNDLE}"
elif (( STAGE_ONLY == 1 )); then
  die "Flutter arm64 binary not found at ${LINUX_BUNDLE}"
else
  echo ""
  info "Flutter arm64 binary not found — building via Docker + QEMU (~20 min)..."
  echo ""

  docker run --rm --platform linux/arm64 \
    -v "${REPO_ROOT}":/app \
    -v "${SCRIPT_DIR}/build-display-docker.sh":/lf-build.sh \
    -e LANDFALL_DEFAULT_SERVER_URL \
    -e LANDFALL_WEB_SERVER_URL \
    -e LANDFALL_TELEMETRY_ENDPOINT \
    -e LANDFALL_TELEMETRY_API_KEY \
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
if [[ -d "${PI_GEN_DIR}" ]]; then
  CURRENT_BRANCH="$(git -C "${PI_GEN_DIR}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
  if [[ "${CURRENT_BRANCH}" != "arm64" && -d "${PI_GEN_DIR}/.git" ]]; then
    info "Switching pi-gen clone to arm64 branch..."
    rm -rf "${PI_GEN_DIR}"
  fi
fi
if [[ -d "${PI_GEN_DIR}" ]]; then
  if (( STAGE_ONLY == 1 )); then
    info "Using existing pi-gen directory for stage-only build: ${PI_GEN_DIR}"
  else
    info "Updating pi-gen..."
    git -C "${PI_GEN_DIR}" pull --quiet
  fi
elif (( STAGE_ONLY == 1 )); then
  die "pi-gen directory not found for stage-only build: ${PI_GEN_DIR}"
else
  info "Cloning pi-gen (arm64 branch)..."
  mkdir -p "${WORK_DIR}"
  git clone --quiet --depth=1 --branch arm64 https://github.com/RPi-Distro/pi-gen.git "${PI_GEN_DIR}"
fi
ok "pi-gen ready (arm64)"

# ── Copy Landfall stage into pi-gen ───────────────────────────────────────────
cp "${SCRIPT_DIR}/config" "${PI_GEN_DIR}/config"
# Inject hostname and WiFi country into pi-gen config
sed_in_place "s/^TARGET_HOSTNAME=.*/TARGET_HOSTNAME=\"${PI_HOSTNAME}\"/" "${PI_GEN_DIR}/config"
if grep -q "^WPA_COUNTRY=" "${PI_GEN_DIR}/config"; then
  sed_in_place "s/^WPA_COUNTRY=.*/WPA_COUNTRY=\"${WIFI_COUNTRY}\"/" "${PI_GEN_DIR}/config"
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

# ── Stage: integration credentials for firstboot.sh ──────────────────────────
# Secrets (DB password, JWT keys, etc.) are NOT staged here — firstboot.sh
# generates them on the Pi so they are unique per device.
{
  printf "SMTP_HOST=%q\n"           "${SMTP_HOST}"
  printf "SMTP_PORT=%q\n"           "${SMTP_PORT}"
  printf "SMTP_USERNAME=%q\n"       "${SMTP_USERNAME}"
  printf "SMTP_PASSWORD=%q\n"       "${SMTP_PASSWORD}"
  printf "SMTP_FROM_EMAIL=%q\n"     "${SMTP_FROM_EMAIL}"
  printf "SMTP_FROM_NAME=%q\n"      "${SMTP_FROM_NAME}"
  printf "SMTP_SSL=%q\n"            "${SMTP_SSL}"
  printf "SMTP_ALLOW_INSECURE=%q\n" "${SMTP_ALLOW_INSECURE}"
  printf "OWM_API_KEY=%q\n"              "${OWM_API_KEY}"
  printf "WEATHER_LATITUDE=%q\n"         "${WEATHER_LATITUDE}"
  printf "WEATHER_LONGITUDE=%q\n"        "${WEATHER_LONGITUDE}"
  printf "WEATHER_LOCATION_NAME=%q\n"    "${WEATHER_LOCATION_NAME}"
  printf "GOOGLE_CLIENT_ID=%q\n"         "${GOOGLE_CLIENT_ID}"
  printf "GOOGLE_CLIENT_SECRET=%q\n"     "${GOOGLE_CLIENT_SECRET}"
  printf "GOOGLE_DRIVE_FOLDER_ID=%q\n"   "${GOOGLE_DRIVE_FOLDER_ID}"
  printf "MICROSOFT_CLIENT_ID=%q\n"      "${MICROSOFT_CLIENT_ID}"
  printf "MICROSOFT_CLIENT_SECRET=%q\n"  "${MICROSOFT_CLIENT_SECRET}"
  printf "STRIPE_WEBHOOK_SECRET=%q\n"    "${STRIPE_WEBHOOK_SECRET}"
  # Dev-only telemetry passthrough. Blank in production builds.
  printf "LANDFALL_TELEMETRY_ENDPOINT=%q\n" "${LANDFALL_TELEMETRY_ENDPOINT:-}"
  printf "LANDFALL_TELEMETRY_API_KEY=%q\n"  "${LANDFALL_TELEMETRY_API_KEY:-}"
} > "${STAGE_FILES}/integrations.env"
ok "Integration credentials staged"

# ── Stage: WiFi country (for /etc/default/crda in rootfs) ────────────────────
echo "${WIFI_COUNTRY}" > "${STAGE_FILES}/wifi-country"

# ── Stage: timezone (consumed by 00-run.sh to seed /etc/timezone) ────────────
echo "${PI_TIMEZONE}" > "${STAGE_FILES}/timezone"

# ── Stage: SSH authorized_keys for landfall user ─────────────────────────────
if [[ -n "${SSH_AUTHORIZED_KEY}" ]]; then
  printf "%s\n" "${SSH_AUTHORIZED_KEY}" > "${STAGE_FILES}/authorized_keys"
  chmod 600 "${STAGE_FILES}/authorized_keys"
  ok "SSH authorized_keys staged"
else
  rm -f "${STAGE_FILES}/authorized_keys"
fi

# ── Stage: SSH password (will be set via chpasswd in 00-run.sh) ──────────────
# Stored in a chmod 600 file inside the build only — never copied into the
# rootfs as plaintext; 00-run.sh consumes it and removes it before chroot exits.
if [[ -n "${SSH_PASSWORD}" ]]; then
  printf "%s" "${SSH_PASSWORD}" > "${STAGE_FILES}/ssh-password"
  chmod 600 "${STAGE_FILES}/ssh-password"
  ok "SSH password staged"
else
  rm -f "${STAGE_FILES}/ssh-password"
fi

# ── Stage: static IP NetworkManager connection ───────────────────────────────
if [[ -n "${STATIC_IP_CIDR}" ]]; then
  STATIC_TYPE="ethernet"
  STATIC_ID="landfall-eth-static"
  if [[ "${STATIC_INTERFACE}" == wlan* ]]; then
    STATIC_TYPE="wifi"
    STATIC_ID="landfall-wifi-static"
  fi
  # NetworkManager wants semicolon-terminated DNS list
  STATIC_DNS_NM="$(printf '%s' "${STATIC_DNS}" | tr ',' ';')"
  [[ -z "${STATIC_DNS_NM}" || "${STATIC_DNS_NM: -1}" != ";" ]] && STATIC_DNS_NM="${STATIC_DNS_NM};"

  if [[ "${STATIC_TYPE}" == "wifi" && -n "${WIFI_SSID}" ]]; then
    # Replace the WiFi connection file with one that uses manual IPv4
    cat > "${STAGE_FILES}/wifi.nmconnection" << WIFICONF
[connection]
id=${STATIC_ID}
type=wifi
interface-name=${STATIC_INTERFACE}
autoconnect=true
autoconnect-priority=700

[wifi]
mode=infrastructure
ssid=${WIFI_SSID}

[wifi-security]
auth-alg=open
key-mgmt=wpa-psk
psk=${WIFI_PASSWORD}

[ipv4]
method=manual
address1=${STATIC_IP_CIDR},${STATIC_GATEWAY}
dns=${STATIC_DNS_NM}

[ipv6]
method=auto
addr-gen-mode=default
WIFICONF
    chmod 600 "${STAGE_FILES}/wifi.nmconnection"
    ok "Static IP (WiFi): ${STATIC_IP_CIDR} via ${STATIC_GATEWAY} on ${STATIC_INTERFACE}"
    WIFI_STATIC_ALREADY_WRITTEN=1
  else
    cat > "${STAGE_FILES}/static-ip.nmconnection" << ETHCONF
[connection]
id=${STATIC_ID}
type=ethernet
interface-name=${STATIC_INTERFACE}
autoconnect=true
autoconnect-priority=700

[ipv4]
method=manual
address1=${STATIC_IP_CIDR},${STATIC_GATEWAY}
dns=${STATIC_DNS_NM}

[ipv6]
method=auto
addr-gen-mode=default
ETHCONF
    chmod 600 "${STAGE_FILES}/static-ip.nmconnection"
    ok "Static IP (${STATIC_INTERFACE}): ${STATIC_IP_CIDR} via ${STATIC_GATEWAY}"
  fi
else
  rm -f "${STAGE_FILES}/static-ip.nmconnection"
fi

# ── Stage: WiFi NetworkManager connection ────────────────────────────────────
if [[ -n "${WIFI_SSID}" && -z "${WIFI_STATIC_ALREADY_WRITTEN:-}" ]]; then
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
  chmod 600 "${STAGE_FILES}/wifi.nmconnection"
  ok "WiFi staged: ${WIFI_SSID} (country: ${WIFI_COUNTRY})"
else
  rm -f "${STAGE_FILES}/wifi.nmconnection"
  info "No WiFi configured — ethernet only, or add via nmcli after first boot"
fi

# ── Stage: Flutter display bundle ─────────────────────────────────────────────
BUNDLE_DEST="${STAGE_FILES}/bundle"
rm -rf "${BUNDLE_DEST}"
cp -rp "${LINUX_BUNDLE}/." "${BUNDLE_DEST}/"
ok "Display bundle staged ($(du -sh "${BUNDLE_DEST}" | cut -f1))"

# ── Step 2: Server Docker image for arm64 ────────────────────────────────────
SERVER_TARBALL="${STAGE_FILES}/landfall-server.tar.gz"
if [[ -f "${SERVER_TARBALL}" ]]; then
  ok "Server image already staged ($(du -sh "${SERVER_TARBALL}" | cut -f1)) — delete to rebuild"
elif [[ -n "${LANDFALL_SERVER_TARBALL_SOURCE:-}" ]]; then
  cp "${LANDFALL_SERVER_TARBALL_SOURCE}" "${SERVER_TARBALL}"
  ok "Server image tarball staged from ${LANDFALL_SERVER_TARBALL_SOURCE}"
elif (( STAGE_ONLY == 1 )); then
  die "Server image tarball not staged and LANDFALL_SERVER_TARBALL_SOURCE is not set"
else
  echo ""
  info "Cross-compiling server Docker image for arm64 (~20–40 min)..."
  echo ""

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

if (( STAGE_ONLY == 1 )); then
  ok "Stage-only build complete: ${PI_GEN_DIR}/stage2-landfall"
  exit 0
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
  sed_in_place "s/ARG LANDFALL_CACHE_WEEK=.*/ARG LANDFALL_CACHE_WEEK=${CACHE_WEEK}/" \
    "${PI_GEN_DIR}/Dockerfile"
fi

if grep -q "LANDFALL_CACHE_WEEK" "${PI_GEN_DIR}/build-docker.sh"; then
  sed_in_place "s/LANDFALL_CACHE_WEEK=[^ ]*/LANDFALL_CACHE_WEEK=${CACHE_WEEK}/" \
    "${PI_GEN_DIR}/build-docker.sh"
else
  sed_in_place "s|--build-arg BASE_IMAGE=\${BASE_IMAGE}|--build-arg BASE_IMAGE=\${BASE_IMAGE} --build-arg LANDFALL_CACHE_WEEK=${CACHE_WEEK}|" \
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
    sed_in_place '/^binfmt_misc_required=1$/s/=1/=0 # Landfall: macOS binfmt skip/' \
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
  info "Flash with Raspberry Pi Imager:"
  info "  1. Open Raspberry Pi Imager"
  info "  2. Choose OS → Use custom → select the .img file above"
  info "  3. Choose Storage → your SD card"
  info "  4. Click Next → Edit Settings:"
  info "       Hostname:     landfall  (or your preferred name)"
  info "       Username:     landfall"
  info "       Password:     (choose your own)"
  info "       WiFi SSID:    your network name"
  info "       WiFi password: your network password"
  info "       WiFi country: your 2-letter country code (US, GB, etc.)"
  info "       Enable SSH:   yes (optional but recommended)"
  info "  5. Click Save → Yes → Write"
  info ""
  info "Boot sequence:"
  info "  Boot 1 (~30s): Pi Imager configures WiFi/hostname → auto-reboots"
  info "  Boot 2 (~2min): secrets generated, server starts, display appears"
else
  die "Build finished but no .img found in ${PI_GEN_DIR}/deploy/"
fi
