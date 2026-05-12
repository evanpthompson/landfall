#!/bin/bash
# Landfall first-boot initialization.
# Runs once as a systemd one-shot service on the first boot after Pi Imager's
# firstrun.sh has completed (i.e. the second actual power-on).
#
# Responsibilities:
#   1. Derive LANDFALL_DOMAIN from the hostname Pi Imager set
#   2. Load optional integration credentials staged by build.sh
#   3. Generate all secrets (unique per device)
#   4. Write /home/landfall/landfall/deploy/.env
#   5. Load the pre-built server Docker image
#   6. Mark the system as initialized (so this never runs again)

set -euo pipefail

log() { echo "[landfall-firstboot] $*"; }

gen_secret()     { openssl rand -base64 32 | tr -d '\n/+=' | cut -c1-43; }
gen_hex_secret() { openssl rand -hex 32; }

IMAGE_TARBALL="${LANDFALL_IMAGE_TARBALL:-/opt/landfall/landfall-server.tar.gz}"
INITIALIZED_FLAG="${LANDFALL_INITIALIZED_FLAG:-/var/lib/landfall/.initialized}"
ENV_FILE="${LANDFALL_ENV_FILE:-/home/landfall/landfall/deploy/.env}"
INTEGRATIONS_FILE="${LANDFALL_INTEGRATIONS_FILE:-/opt/landfall/integrations.env}"
HOSTNAME_FILE="${LANDFALL_HOSTNAME_FILE:-/etc/hostname}"
DOCKER_BIN="${LANDFALL_DOCKER_BIN:-docker}"

# ── Derive domain from hostname ───────────────────────────────────────────────
# Pi Imager's firstrun.sh sets /etc/hostname on boot 1 and reboots.
# By the time this service runs we have the correct hostname.
HOSTNAME_VAL="$(cat "${HOSTNAME_FILE}" | tr -d '[:space:]')"
LANDFALL_DOMAIN="${HOSTNAME_VAL}.local"
log "Domain: ${LANDFALL_DOMAIN}"

# ── Load optional integration credentials ─────────────────────────────────────
OWM_API_KEY=""
GOOGLE_CLIENT_ID=""
GOOGLE_CLIENT_SECRET=""
GOOGLE_DRIVE_FOLDER_ID=""
MICROSOFT_CLIENT_ID=""
MICROSOFT_CLIENT_SECRET=""
STRIPE_WEBHOOK_SECRET=""

if [[ -f "${INTEGRATIONS_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${INTEGRATIONS_FILE}"
  log "Integration credentials loaded"
fi

# Build redirect URIs from the actual hostname
GOOGLE_REDIRECT_URI=""
MICROSOFT_REDIRECT_URI=""
[[ -n "${GOOGLE_CLIENT_ID}" ]] && \
  GOOGLE_REDIRECT_URI="https://${LANDFALL_DOMAIN}/calendar/oauth/callback"
[[ -n "${MICROSOFT_CLIENT_ID}" ]] && \
  MICROSOFT_REDIRECT_URI="https://${LANDFALL_DOMAIN}/calendar/microsoft/oauth/callback"

# ── Generate secrets ──────────────────────────────────────────────────────────
log "Generating secrets..."
DB_PASSWORD="$(gen_secret)"
REDIS_PASSWORD="$(gen_secret)"
SERVERPOD_SERVICE_SECRET="$(gen_secret)"
JWT_HMAC_KEY="$(gen_secret)"
JWT_REFRESH_PEPPER="$(gen_secret)"
API_KEY_MANAGEMENT_TOKEN="$(gen_secret)"
API_KEY_HMAC_SECRET="$(gen_secret)"
PHOTO_SIGNING_SECRET="$(gen_secret)"
OAUTH_TOKEN_ENCRYPTION_KEY="$(gen_hex_secret)"

# ── Write .env ────────────────────────────────────────────────────────────────
# Without SMTP, OTP codes are logged to docker logs so self-hosted installs
# can sign in. Automatically disabled once an SMTP host is configured.
SMTP_HOST="${SMTP_HOST:-}"
OTP_LOG_CODES=false
[[ -z "${SMTP_HOST}" ]] && OTP_LOG_CODES=true

log "Writing .env..."
mkdir -p "$(dirname "${ENV_FILE}")"
cat > "${ENV_FILE}" << ENVFILE
LANDFALL_DOMAIN=${LANDFALL_DOMAIN}
DB_NAME=landfall
DB_USER=landfall
DB_PASSWORD=${DB_PASSWORD}
REDIS_PASSWORD=${REDIS_PASSWORD}
SERVERPOD_SERVICE_SECRET=${SERVERPOD_SERVICE_SECRET}
JWT_HMAC_KEY=${JWT_HMAC_KEY}
JWT_REFRESH_PEPPER=${JWT_REFRESH_PEPPER}
API_KEY_MANAGEMENT_TOKEN=${API_KEY_MANAGEMENT_TOKEN}
API_KEY_HMAC_SECRET=${API_KEY_HMAC_SECRET}
PHOTO_SIGNING_SECRET=${PHOTO_SIGNING_SECRET}
OAUTH_TOKEN_ENCRYPTION_KEY=${OAUTH_TOKEN_ENCRYPTION_KEY}
SMTP_HOST=${SMTP_HOST}
SMTP_PORT=587
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_FROM_EMAIL=
SMTP_FROM_NAME=Landfall
SMTP_SSL=false
SMTP_ALLOW_INSECURE=false
OTP_LOG_CODES=${OTP_LOG_CODES}
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

if [[ "$(id -u)" -eq 0 ]] && id landfall > /dev/null 2>&1; then
  chown landfall:landfall "${ENV_FILE}"
else
  log "Skipping chown for ${ENV_FILE}"
fi
chmod 640 "${ENV_FILE}"
log ".env written"

# ── Load server Docker image ──────────────────────────────────────────────────
log "Loading Landfall server Docker image..."
if [[ -f "${IMAGE_TARBALL}" ]]; then
  "${DOCKER_BIN}" load < "${IMAGE_TARBALL}"
  log "Image loaded — removing tarball to reclaim space"
  rm -f "${IMAGE_TARBALL}"
else
  log "WARNING: ${IMAGE_TARBALL} not found — skipping image load"
  log "The server may fail to start if the image was not pre-loaded."
fi

# ── Ensure display app data directory is owned by landfall ───────────────────
# The app creates this directory at first launch. If anything ever ran the
# binary as root (e.g. during dev/testing), the directory ends up root-owned
# and the app can no longer write its SQLite database. Pre-creating it here
# with correct ownership prevents that regardless of how the device was used.
if [[ "$(id -u)" -eq 0 ]] && id landfall > /dev/null 2>&1; then
  DATA_DIR="${LANDFALL_DATA_DIR:-/home/landfall/.local/share/landfall}"
  mkdir -p "${DATA_DIR}"
  chown -R landfall:landfall "$(dirname "$(dirname "${DATA_DIR}")")"
  log "Data directory ownership set: ${DATA_DIR}"
else
  log "Skipping data directory setup (not running as root with landfall user)"
fi

mkdir -p "$(dirname "${INITIALIZED_FLAG}")"
touch "${INITIALIZED_FLAG}"
log "First-boot initialization complete"
