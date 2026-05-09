#!/usr/bin/env bash
# Landfall Pi — pre-build configuration wizard.
# Run this BEFORE build.sh. Writes landfall-build.conf which build.sh reads
# to bake WiFi, hostname, and integration credentials into the SD card image.
# All secrets (DB password, JWT keys, etc.) are generated on the Pi at first
# boot — nothing sensitive is stored here except integration API keys.
#
# Usage: bash deploy/pi-gen/configure.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="${LANDFALL_CONFIG_OUTPUT:-${SCRIPT_DIR}/landfall-build.conf}"

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
skip()    { echo "${YELLOW}   ↩  skipped — add via SSH later${RESET}"; }

echo ""
echo "${CYAN}${BOLD}Landfall — Pi image configuration${RESET}"
echo ""
info "Answers are baked into the SD card image so the Pi connects and starts"
info "automatically on first boot. Secrets are generated on the Pi itself."
info ""
info "Press Enter to accept defaults. Optional fields can be added later via SSH:"
info "  nano /home/landfall/landfall/deploy/.env"
info "  sudo systemctl restart landfall-server"
echo ""

# ── Network ───────────────────────────────────────────────────────────────────
section "Network"

ask "WiFi country code [US]:"
read -r WIFI_COUNTRY
WIFI_COUNTRY="${WIFI_COUNTRY:-US}"

echo ""
info "WiFi credentials — leave blank to use ethernet."
ask "WiFi SSID [blank to skip]:"
read -r WIFI_SSID
WIFI_PASSWORD=""
if [[ -n "${WIFI_SSID}" ]]; then
  ask "WiFi password:"
  read -rs WIFI_PASSWORD
  echo ""
  ok "WiFi: ${WIFI_SSID} (country: ${WIFI_COUNTRY})"
else
  info "No WiFi — connect via ethernet or add credentials later."
fi

echo ""
ask "Pi hostname [landfall]:"
read -r PI_HOSTNAME
PI_HOSTNAME="${PI_HOSTNAME:-landfall}"
ok "Hostname: ${PI_HOSTNAME}  (reachable at ${PI_HOSTNAME}.local on your network)"

# ── Weather ───────────────────────────────────────────────────────────────────
section "Weather  (optional)"
dim "Free API key at openweathermap.org/api"
ask "OpenWeatherMap API key [blank to skip]:"
read -r OWM_API_KEY
[[ -z "${OWM_API_KEY}" ]] && skip

# ── Google Calendar + Drive Photos ───────────────────────────────────────────
section "Google Calendar + Drive Photos  (optional)"
dim "Requires a Google Cloud project with Calendar API and Drive API enabled."
dim "Create an OAuth 2.0 client ID (Web application) at console.cloud.google.com."
dim "Set the redirect URI to: https://${PI_HOSTNAME}.local/calendar/oauth/callback"
echo ""
ask "Google Client ID [blank to skip]:"
read -r GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET=""
GOOGLE_DRIVE_FOLDER_ID=""
if [[ -n "${GOOGLE_CLIENT_ID}" ]]; then
  ask "Google Client Secret:"
  read -rs GOOGLE_CLIENT_SECRET
  echo ""
  ok "Google OAuth configured"
  echo ""
  dim "Optional: restrict photo sync to a specific Google Drive folder."
  ask "Google Drive Folder ID [blank to skip]:"
  read -r GOOGLE_DRIVE_FOLDER_ID
else
  skip
fi

# ── Microsoft Calendar ────────────────────────────────────────────────────────
section "Microsoft Calendar  (optional)"
dim "Requires an app registration at portal.azure.com."
dim "Add Calendars.Read delegated permission and grant admin consent."
dim "Set the redirect URI to: https://${PI_HOSTNAME}.local/calendar/microsoft/oauth/callback"
echo ""
ask "Microsoft Client ID [blank to skip]:"
read -r MICROSOFT_CLIENT_ID
MICROSOFT_CLIENT_SECRET=""
if [[ -n "${MICROSOFT_CLIENT_ID}" ]]; then
  ask "Microsoft Client Secret:"
  read -rs MICROSOFT_CLIENT_SECRET
  echo ""
  ok "Microsoft OAuth configured"
else
  skip
fi

# ── Stripe ────────────────────────────────────────────────────────────────────
section "Stripe Webhook  (optional)"
dim "Only needed if you are using Stripe for pack/license purchases."
ask "Stripe Webhook Secret [blank to skip]:"
read -r STRIPE_WEBHOOK_SECRET
[[ -z "${STRIPE_WEBHOOK_SECRET}" ]] && skip

# ── Write config ──────────────────────────────────────────────────────────────
{
  echo "# Landfall Pi build config — $(date)"
  echo "# Baked into the SD card image. Keep private — contains API credentials."
  echo ""
  echo "# ── Network ──────────────────────────────────────────────────────────────────"
  printf "WIFI_COUNTRY=%q\n"   "${WIFI_COUNTRY}"
  printf "WIFI_SSID=%q\n"      "${WIFI_SSID}"
  printf "WIFI_PASSWORD=%q\n"  "${WIFI_PASSWORD}"
  printf "PI_HOSTNAME=%q\n"    "${PI_HOSTNAME}"
  echo ""
  echo "# ── Optional integrations ────────────────────────────────────────────────────"
  printf "OWM_API_KEY=%q\n"              "${OWM_API_KEY:-}"
  printf "GOOGLE_CLIENT_ID=%q\n"         "${GOOGLE_CLIENT_ID:-}"
  printf "GOOGLE_CLIENT_SECRET=%q\n"     "${GOOGLE_CLIENT_SECRET:-}"
  printf "GOOGLE_DRIVE_FOLDER_ID=%q\n"   "${GOOGLE_DRIVE_FOLDER_ID:-}"
  printf "MICROSOFT_CLIENT_ID=%q\n"      "${MICROSOFT_CLIENT_ID:-}"
  printf "MICROSOFT_CLIENT_SECRET=%q\n"  "${MICROSOFT_CLIENT_SECRET:-}"
  printf "STRIPE_WEBHOOK_SECRET=%q\n"    "${STRIPE_WEBHOOK_SECRET:-}"
} > "${CONF_FILE}"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "${CYAN}${BOLD}Summary${RESET}"
echo ""
info "Hostname:  ${PI_HOSTNAME}  →  ${PI_HOSTNAME}.local"
[[ -n "${WIFI_SSID}" ]] && info "WiFi:      ${WIFI_SSID} (${WIFI_COUNTRY})" \
                        || info "WiFi:      ethernet only"
[[ -n "${OWM_API_KEY:-}" ]]         && info "Weather:   enabled" \
                                     || info "Weather:   not configured"
[[ -n "${GOOGLE_CLIENT_ID:-}" ]]    && info "Google:    enabled (Calendar + Drive)" \
                                     || info "Google:    not configured"
[[ -n "${MICROSOFT_CLIENT_ID:-}" ]] && info "Microsoft: enabled (Calendar)" \
                                     || info "Microsoft: not configured"
[[ -n "${STRIPE_WEBHOOK_SECRET:-}" ]] && info "Stripe:    configured" \
                                      || info "Stripe:    not configured"
echo ""
ok "Saved: ${CONF_FILE}"
info ""
info "Next:  bash deploy/pi-gen/build.sh"
echo ""
