#!/usr/bin/env bash
# Landfall Pi — pre-build configuration wizard.
# Run this BEFORE build.sh. Writes landfall-build.conf which is sourced
# by build.sh and baked into the SD card image.
#
# Usage: bash deploy/pi-gen/configure.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="${SCRIPT_DIR}/landfall-build.conf"

BOLD=$'\033[1m'
GREEN=$'\033[1;32m'
CYAN=$'\033[1;36m'
RESET=$'\033[0m'

ok()   { echo "${GREEN}✓  $*${RESET}"; }
info() { echo "   $*"; }
ask()  { printf "${BOLD}%s${RESET} " "$*"; }

gen_secret()     { openssl rand -base64 32 | tr -d '\n/+=' | cut -c1-43; }
gen_hex_secret() { openssl rand -hex 32; }

echo ""
echo "${CYAN}${BOLD}Landfall — Pi image configuration${RESET}"
echo ""
info "Your answers are baked into the SD card image."
info "Run  bash deploy/pi-gen/build.sh  afterwards to create the image."
echo ""

# ── WiFi ─────────────────────────────────────────────────────────────────────
info "WiFi — leave blank to skip and configure after first boot (or use ethernet)."
ask "WiFi SSID [blank to skip]:"
read -r WIFI_SSID
WIFI_PASSWORD=""
if [[ -n "${WIFI_SSID}" ]]; then
  ask "WiFi password:"
  read -rs WIFI_PASSWORD
  echo ""
fi
echo ""

# ── Hostname ─────────────────────────────────────────────────────────────────
ask "Pi hostname [landfall]:"
read -r PI_HOSTNAME
PI_HOSTNAME="${PI_HOSTNAME:-landfall}"

# ── Domain ───────────────────────────────────────────────────────────────────
echo ""
info "Server address — used by the display app and the Caddyfile."
info "  Local network:  ${PI_HOSTNAME}.local  or  192.168.1.x"
info "  Public domain:  api.example.com  (Caddy auto-fetches TLS)"
ask "Domain / IP [${PI_HOSTNAME}.local]:"
read -r LANDFALL_DOMAIN
LANDFALL_DOMAIN="${LANDFALL_DOMAIN:-${PI_HOSTNAME}.local}"

# ── Optional integrations ─────────────────────────────────────────────────────
echo ""
info "Optional — press Enter to skip (you can edit .env on the Pi later)."
ask "OpenWeatherMap API key:"
read -r OWM_API_KEY

# ── Generate secrets ─────────────────────────────────────────────────────────
echo ""
info "Generating secrets..."
DB_PASSWORD="$(gen_secret)"
REDIS_PASSWORD="$(gen_secret)"
SERVERPOD_SERVICE_SECRET="$(gen_secret)"
JWT_HMAC_KEY="$(gen_secret)"
JWT_REFRESH_PEPPER="$(gen_secret)"
API_KEY_MANAGEMENT_TOKEN="$(gen_secret)"
API_KEY_HMAC_SECRET="$(gen_secret)"
PHOTO_SIGNING_SECRET="$(gen_secret)"
OAUTH_TOKEN_ENCRYPTION_KEY="$(gen_hex_secret)"
ok "Secrets generated"

# ── Write config ──────────────────────────────────────────────────────────────
# Use printf for each line so special characters in WiFi passwords don't
# break the file — %q shell-quotes the value safely.
{
  echo "# Landfall build config — $(date)"
  echo "# Baked into the SD card image. Keep this file private."
  echo ""
  printf "WIFI_SSID=%q\n"     "${WIFI_SSID}"
  printf "WIFI_PASSWORD=%q\n" "${WIFI_PASSWORD}"
  printf "PI_HOSTNAME=%q\n"   "${PI_HOSTNAME}"
  printf "LANDFALL_DOMAIN=%q\n" "${LANDFALL_DOMAIN}"
  printf "OWM_API_KEY=%q\n"   "${OWM_API_KEY:-}"
  echo ""
  echo "DB_NAME=landfall"
  echo "DB_USER=landfall"
  echo "DB_PASSWORD=${DB_PASSWORD}"
  echo "REDIS_PASSWORD=${REDIS_PASSWORD}"
  echo "SERVERPOD_SERVICE_SECRET=${SERVERPOD_SERVICE_SECRET}"
  echo "JWT_HMAC_KEY=${JWT_HMAC_KEY}"
  echo "JWT_REFRESH_PEPPER=${JWT_REFRESH_PEPPER}"
  echo "API_KEY_MANAGEMENT_TOKEN=${API_KEY_MANAGEMENT_TOKEN}"
  echo "API_KEY_HMAC_SECRET=${API_KEY_HMAC_SECRET}"
  echo "PHOTO_SIGNING_SECRET=${PHOTO_SIGNING_SECRET}"
  echo "OAUTH_TOKEN_ENCRYPTION_KEY=${OAUTH_TOKEN_ENCRYPTION_KEY}"
} > "${CONF_FILE}"

echo ""
ok "Saved: ${CONF_FILE}"
info ""
info "Next:  bash deploy/pi-gen/build.sh"
echo ""
