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
YELLOW=$'\033[1;33m'
DIM=$'\033[2m'
RESET=$'\033[0m'

ok()      { echo "${GREEN}✓  $*${RESET}"; }
info()    { echo "   $*"; }
dim()     { echo "${DIM}   $*${RESET}"; }
section() { echo ""; echo "${CYAN}${BOLD}$*${RESET}"; echo ""; }
ask()     { printf "${BOLD}%s${RESET} " "$*"; }
skip()    { echo "${YELLOW}   ↩  skipped — edit .env on the Pi to add later${RESET}"; }

gen_secret()     { openssl rand -base64 32 | tr -d '\n/+=' | cut -c1-43; }
gen_hex_secret() { openssl rand -hex 32; }

echo ""
echo "${CYAN}${BOLD}Landfall — Pi image configuration${RESET}"
echo ""
info "Your answers are baked into the SD card image."
info "Press Enter to skip any optional field — you can edit /home/landfall/landfall/deploy/.env"
info "on the Pi at any time and restart the server to apply changes."
echo ""

# ── WiFi ─────────────────────────────────────────────────────────────────────
section "Network"
info "WiFi — leave blank to use ethernet or configure after first boot."
ask "WiFi SSID [blank to skip]:"
read -r WIFI_SSID
WIFI_PASSWORD=""
if [[ -n "${WIFI_SSID}" ]]; then
  ask "WiFi password:"
  read -rs WIFI_PASSWORD
  echo ""
  ok "WiFi configured: ${WIFI_SSID}"
fi

echo ""
ask "Pi hostname [landfall]:"
read -r PI_HOSTNAME
PI_HOSTNAME="${PI_HOSTNAME:-landfall}"

echo ""
info "Server address — used by the display app and Caddy."
info "  Local:   ${PI_HOSTNAME}.local  or  192.168.1.x"
info "  Public:  api.example.com  (Caddy auto-fetches a TLS certificate)"
ask "Domain / IP [${PI_HOSTNAME}.local]:"
read -r LANDFALL_DOMAIN
LANDFALL_DOMAIN="${LANDFALL_DOMAIN:-${PI_HOSTNAME}.local}"

# ── Weather ───────────────────────────────────────────────────────────────────
section "Weather  (optional)"
dim "Free API key at openweathermap.org/api — 60 calls/min is more than enough."
ask "OpenWeatherMap API key [blank to skip]:"
read -r OWM_API_KEY
[[ -z "${OWM_API_KEY}" ]] && skip

# ── Google Calendar + Drive Photos ───────────────────────────────────────────
section "Google Calendar + Drive Photos  (optional)"
dim "Requires a Google Cloud project with Calendar API and Drive API enabled."
dim "Create an OAuth 2.0 client ID (Web application) at console.cloud.google.com."
dim "Set the redirect URI to: https://${LANDFALL_DOMAIN}/calendar/oauth/callback"
echo ""
ask "Google Client ID [blank to skip]:"
read -r GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET=""
GOOGLE_REDIRECT_URI=""
GOOGLE_DRIVE_FOLDER_ID=""
if [[ -n "${GOOGLE_CLIENT_ID}" ]]; then
  ask "Google Client Secret:"
  read -rs GOOGLE_CLIENT_SECRET
  echo ""
  GOOGLE_REDIRECT_URI="https://${LANDFALL_DOMAIN}/calendar/oauth/callback"
  ok "Google OAuth configured"
  echo ""
  dim "Optional: restrict photo sync to a specific Google Drive folder."
  dim "Leave blank to allow the user to pick any folder in the app."
  ask "Google Drive Folder ID [blank to skip]:"
  read -r GOOGLE_DRIVE_FOLDER_ID
else
  skip
fi

# ── Microsoft Calendar ────────────────────────────────────────────────────────
section "Microsoft Calendar  (optional)"
dim "Requires an app registration at portal.azure.com."
dim "Add Calendars.Read delegated permission and grant admin consent."
dim "Set the redirect URI to: https://${LANDFALL_DOMAIN}/calendar/microsoft/oauth/callback"
echo ""
ask "Microsoft Client ID [blank to skip]:"
read -r MICROSOFT_CLIENT_ID
MICROSOFT_CLIENT_SECRET=""
MICROSOFT_REDIRECT_URI=""
if [[ -n "${MICROSOFT_CLIENT_ID}" ]]; then
  ask "Microsoft Client Secret:"
  read -rs MICROSOFT_CLIENT_SECRET
  echo ""
  MICROSOFT_REDIRECT_URI="https://${LANDFALL_DOMAIN}/calendar/microsoft/oauth/callback"
  ok "Microsoft OAuth configured"
else
  skip
fi

# ── Stripe ────────────────────────────────────────────────────────────────────
section "Stripe Webhook  (optional)"
dim "Only needed if you are using Stripe for pack/license purchases."
dim "Find the webhook secret under Developers > Webhooks in your Stripe dashboard."
ask "Stripe Webhook Secret [blank to skip]:"
read -r STRIPE_WEBHOOK_SECRET
[[ -z "${STRIPE_WEBHOOK_SECRET}" ]] && skip

# ── Generate secrets ─────────────────────────────────────────────────────────
section "Generating secrets..."
DB_PASSWORD="$(gen_secret)"
REDIS_PASSWORD="$(gen_secret)"
SERVERPOD_SERVICE_SECRET="$(gen_secret)"
JWT_HMAC_KEY="$(gen_secret)"
JWT_REFRESH_PEPPER="$(gen_secret)"
API_KEY_MANAGEMENT_TOKEN="$(gen_secret)"
API_KEY_HMAC_SECRET="$(gen_secret)"
PHOTO_SIGNING_SECRET="$(gen_secret)"
OAUTH_TOKEN_ENCRYPTION_KEY="$(gen_hex_secret)"
ok "All secrets generated"

# ── Write config ──────────────────────────────────────────────────────────────
# Use printf %q for user-supplied strings so special characters (spaces, quotes,
# backslashes in WiFi passwords etc.) don't break the sourced config file.
{
  echo "# Landfall build config — $(date)"
  echo "# Baked into the SD card image. Keep this file private — it contains secrets."
  echo ""
  echo "# ── Network ──────────────────────────────────────────────────────────────────"
  printf "WIFI_SSID=%q\n"        "${WIFI_SSID}"
  printf "WIFI_PASSWORD=%q\n"    "${WIFI_PASSWORD}"
  printf "PI_HOSTNAME=%q\n"      "${PI_HOSTNAME}"
  printf "LANDFALL_DOMAIN=%q\n"  "${LANDFALL_DOMAIN}"
  echo ""
  echo "# ── Database + Redis ─────────────────────────────────────────────────────────"
  echo "DB_NAME=landfall"
  echo "DB_USER=landfall"
  echo "DB_PASSWORD=${DB_PASSWORD}"
  echo "REDIS_PASSWORD=${REDIS_PASSWORD}"
  echo ""
  echo "# ── Serverpod secrets ────────────────────────────────────────────────────────"
  echo "SERVERPOD_SERVICE_SECRET=${SERVERPOD_SERVICE_SECRET}"
  echo "JWT_HMAC_KEY=${JWT_HMAC_KEY}"
  echo "JWT_REFRESH_PEPPER=${JWT_REFRESH_PEPPER}"
  echo ""
  echo "# ── API key service ──────────────────────────────────────────────────────────"
  echo "API_KEY_MANAGEMENT_TOKEN=${API_KEY_MANAGEMENT_TOKEN}"
  echo "API_KEY_HMAC_SECRET=${API_KEY_HMAC_SECRET}"
  echo ""
  echo "# ── Photo signing ────────────────────────────────────────────────────────────"
  echo "PHOTO_SIGNING_SECRET=${PHOTO_SIGNING_SECRET}"
  echo "OAUTH_TOKEN_ENCRYPTION_KEY=${OAUTH_TOKEN_ENCRYPTION_KEY}"
  echo ""
  echo "# ── Optional integrations ────────────────────────────────────────────────────"
  printf "OWM_API_KEY=%q\n"               "${OWM_API_KEY:-}"
  printf "GOOGLE_CLIENT_ID=%q\n"          "${GOOGLE_CLIENT_ID:-}"
  printf "GOOGLE_CLIENT_SECRET=%q\n"      "${GOOGLE_CLIENT_SECRET:-}"
  printf "GOOGLE_REDIRECT_URI=%q\n"       "${GOOGLE_REDIRECT_URI:-}"
  printf "GOOGLE_DRIVE_FOLDER_ID=%q\n"    "${GOOGLE_DRIVE_FOLDER_ID:-}"
  printf "MICROSOFT_CLIENT_ID=%q\n"       "${MICROSOFT_CLIENT_ID:-}"
  printf "MICROSOFT_CLIENT_SECRET=%q\n"   "${MICROSOFT_CLIENT_SECRET:-}"
  printf "MICROSOFT_REDIRECT_URI=%q\n"    "${MICROSOFT_REDIRECT_URI:-}"
  printf "STRIPE_WEBHOOK_SECRET=%q\n"     "${STRIPE_WEBHOOK_SECRET:-}"
} > "${CONF_FILE}"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "${CYAN}${BOLD}Configuration summary${RESET}"
echo ""
info "Hostname:    ${PI_HOSTNAME}"
info "Domain:      ${LANDFALL_DOMAIN}"
[[ -n "${WIFI_SSID}" ]]              && info "WiFi:        ${WIFI_SSID}" \
                                     || info "WiFi:        not configured (use ethernet)"
[[ -n "${OWM_API_KEY:-}" ]]          && info "Weather:     enabled" \
                                     || info "Weather:     not configured"
[[ -n "${GOOGLE_CLIENT_ID:-}" ]]     && info "Google:      enabled (Calendar + Drive)" \
                                     || info "Google:      not configured"
[[ -n "${MICROSOFT_CLIENT_ID:-}" ]]  && info "Microsoft:   enabled (Calendar)" \
                                     || info "Microsoft:   not configured"
[[ -n "${STRIPE_WEBHOOK_SECRET:-}" ]] && info "Stripe:      configured" \
                                      || info "Stripe:      not configured"
echo ""
ok "Saved: ${CONF_FILE}"
info ""
info "Next:  bash deploy/pi-gen/build.sh"
echo ""
