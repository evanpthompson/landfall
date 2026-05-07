#!/usr/bin/env bash
# Landfall Pi — optional pre-build integration configuration.
# Run this BEFORE build.sh only if you want to bake in API credentials
# (weather, Google Calendar, Microsoft Calendar, Stripe).
#
# WiFi, hostname, and SSH are configured in Raspberry Pi Imager when you flash —
# you do NOT need to run this script for a basic working setup.
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
skip()    { echo "${YELLOW}   ↩  skipped — add via the app settings after first boot${RESET}"; }

echo ""
echo "${CYAN}${BOLD}Landfall — integration credentials${RESET}"
echo ""
info "This configures optional API integrations baked into the image."
info "WiFi, hostname, and SSH are set in Raspberry Pi Imager — not here."
info ""
info "Press Enter to skip any field — you can add credentials later via"
info "SSH: nano /home/landfall/landfall/deploy/.env && sudo systemctl restart landfall-server"
echo ""

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
dim "Set the redirect URI to: https://landfall.local/calendar/oauth/callback"
dim "(replace landfall.local with your hostname if you used a different one in Pi Imager)"
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
dim "Set the redirect URI to: https://landfall.local/calendar/microsoft/oauth/callback"
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
  echo "# Landfall integration credentials — $(date)"
  echo "# WiFi/hostname/secrets are NOT stored here — they are set in Pi Imager"
  echo "# and generated on the Pi at first boot."
  echo ""
  printf "OWM_API_KEY=%q\n"            "${OWM_API_KEY:-}"
  printf "GOOGLE_CLIENT_ID=%q\n"       "${GOOGLE_CLIENT_ID:-}"
  printf "GOOGLE_CLIENT_SECRET=%q\n"   "${GOOGLE_CLIENT_SECRET:-}"
  printf "GOOGLE_DRIVE_FOLDER_ID=%q\n" "${GOOGLE_DRIVE_FOLDER_ID:-}"
  printf "MICROSOFT_CLIENT_ID=%q\n"    "${MICROSOFT_CLIENT_ID:-}"
  printf "MICROSOFT_CLIENT_SECRET=%q\n" "${MICROSOFT_CLIENT_SECRET:-}"
  printf "STRIPE_WEBHOOK_SECRET=%q\n"  "${STRIPE_WEBHOOK_SECRET:-}"
} > "${CONF_FILE}"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "${CYAN}${BOLD}Summary${RESET}"
echo ""
[[ -n "${OWM_API_KEY:-}" ]]         && info "Weather:     enabled" \
                                     || info "Weather:     not configured"
[[ -n "${GOOGLE_CLIENT_ID:-}" ]]    && info "Google:      enabled (Calendar + Drive)" \
                                     || info "Google:      not configured"
[[ -n "${MICROSOFT_CLIENT_ID:-}" ]] && info "Microsoft:   enabled (Calendar)" \
                                     || info "Microsoft:   not configured"
[[ -n "${STRIPE_WEBHOOK_SECRET:-}" ]] && info "Stripe:      configured" \
                                      || info "Stripe:      not configured"
echo ""
ok "Saved: ${CONF_FILE}"
info ""
info "Next:  bash deploy/pi-gen/build.sh"
echo ""
