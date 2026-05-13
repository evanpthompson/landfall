#!/usr/bin/env bash
# Landfall Pi — pre-build configuration wizard.
# Run this BEFORE build.sh. Writes landfall-build.conf which build.sh reads
# to bake WiFi, hostname, and integration credentials into the SD card image.
# All secrets (DB password, JWT keys, etc.) are generated on the Pi at first
# boot — nothing sensitive is stored here except integration API keys.
#
# Usage:
#   bash deploy/pi-gen/configure.sh                     # interactive wizard
#   bash deploy/pi-gen/configure.sh --from-env FILE     # non-interactive, load from file

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
warn()    { echo "${YELLOW}⚠  $*${RESET}"; }
info()    { echo "   $*"; }
dim()     { echo "${DIM}   $*${RESET}"; }
section() { echo ""; echo "${CYAN}${BOLD}$*${RESET}"; echo ""; }
ask()     { printf "${BOLD}%s${RESET} " "$*"; }
skip()    { echo "${YELLOW}   ↩  skipped — add via SSH later${RESET}"; }

# ── Non-interactive mode ──────────────────────────────────────────────────────
# --from-env FILE  sources the file to populate variables, then writes the conf
# without prompting. Accepts .env format (KEY=value) or existing landfall-build.conf.

FROM_ENV_FILE=""
if [[ "${1:-}" == "--from-env" ]]; then
  if [[ -z "${2:-}" || ! -f "${2}" ]]; then
    echo "Usage: $0 --from-env <path-to-env-file>" >&2
    exit 1
  fi
  FROM_ENV_FILE="${2}"
fi

if [[ -n "${FROM_ENV_FILE}" ]]; then
  echo ""
  echo "${CYAN}${BOLD}Landfall — Pi image configuration (non-interactive)${RESET}"
  echo ""
  info "Loading from: ${FROM_ENV_FILE}"

  # Source with defaults so unset keys don't error under set -u
  WIFI_COUNTRY=""
  WIFI_SSID=""
  WIFI_PASSWORD=""
  PI_HOSTNAME=""
  PI_TIMEZONE=""
  SMTP_HOST=""
  SMTP_PORT=""
  SMTP_USERNAME=""
  SMTP_PASSWORD=""
  SMTP_FROM_EMAIL=""
  SMTP_FROM_NAME=""
  SMTP_SSL=""
  SMTP_ALLOW_INSECURE=""
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

  # shellcheck disable=SC1090
  source "${FROM_ENV_FILE}"

  # Apply defaults for required fields
  WIFI_COUNTRY="${WIFI_COUNTRY:-US}"
  PI_HOSTNAME="${PI_HOSTNAME:-landfall}"
  PI_TIMEZONE="${PI_TIMEZONE:-Etc/UTC}"
  SMTP_PORT="${SMTP_PORT:-587}"
  SMTP_FROM_NAME="${SMTP_FROM_NAME:-Landfall}"
  SMTP_SSL="${SMTP_SSL:-false}"
  SMTP_ALLOW_INSECURE="${SMTP_ALLOW_INSECURE:-false}"

  if [[ -n "${OWM_API_KEY}" && -z "${WEATHER_LATITUDE}" ]]; then
    warn "OWM_API_KEY set but WEATHER_LATITUDE/WEATHER_LOCATION_NAME missing — weather cards will be blank."
  fi

  ok "Loaded"
else
  # ── Interactive wizard ──────────────────────────────────────────────────────
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

  # ── Network ─────────────────────────────────────────────────────────────────
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

  echo ""
  dim "Timezone — used for the clock card and Serverpod schedulers."
  dim "Examples: America/Chicago, America/Los_Angeles, Europe/London, Asia/Tokyo."
  ask "Timezone [Etc/UTC]:"
  read -r PI_TIMEZONE
  PI_TIMEZONE="${PI_TIMEZONE:-Etc/UTC}"
  ok "Timezone: ${PI_TIMEZONE}"

  # ── Email / OTP ──────────────────────────────────────────────────────────────
  section "Email — required for OTP sign-in"
  dim "Users sign in with a one-time code emailed to them. Configure any SMTP provider."
  dim "Gmail: use an App Password (myaccount.google.com > Security > 2-Step > App passwords)"
  dim "SendGrid / Mailgun / AWS SES also work with port 587 and TLS."
  echo ""
  ask "SMTP host (e.g. smtp.gmail.com) [blank to skip — codes logged to server logs]:"
  read -r SMTP_HOST
  SMTP_PORT="587"
  SMTP_USERNAME=""
  SMTP_PASSWORD=""
  SMTP_FROM_EMAIL=""
  SMTP_FROM_NAME="Landfall"
  SMTP_SSL="false"
  SMTP_ALLOW_INSECURE="false"
  if [[ -n "${SMTP_HOST}" ]]; then
    ask "SMTP port [587]:"
    read -r SMTP_PORT
    SMTP_PORT="${SMTP_PORT:-587}"
    ask "SMTP username:"
    read -r SMTP_USERNAME
    ask "SMTP password:"
    read -rs SMTP_PASSWORD
    echo ""
    ask "From email address (e.g. noreply@yourdomain.com):"
    read -r SMTP_FROM_EMAIL
    ask "From name [Landfall]:"
    read -r SMTP_FROM_NAME
    SMTP_FROM_NAME="${SMTP_FROM_NAME:-Landfall}"
    ask "Use SSL/TLS? (true/false) [false — most providers use STARTTLS on 587]:"
    read -r SMTP_SSL
    SMTP_SSL="${SMTP_SSL:-false}"
    ok "SMTP configured: ${SMTP_HOST}:${SMTP_PORT} (from: ${SMTP_FROM_EMAIL})"
  else
    dim "Skipped — OTP codes will be written to server logs. Add SMTP later:"
    dim "  nano /home/landfall/landfall/deploy/.env"
    dim "  sudo systemctl restart landfall-server"
  fi

  # ── Weather ──────────────────────────────────────────────────────────────────
  section "Weather  (optional)"
  dim "Free API key at openweathermap.org/api"
  ask "OpenWeatherMap API key [blank to skip]:"
  read -r OWM_API_KEY
  WEATHER_LATITUDE=""
  WEATHER_LONGITUDE=""
  WEATHER_LOCATION_NAME=""
  if [[ -n "${OWM_API_KEY}" ]]; then
    dim "Enter your location coordinates. Find lat/lon at maps.google.com (right-click → What's here?)."
    ask "Latitude (e.g. 38.89):"
    read -r WEATHER_LATITUDE
    ask "Longitude (e.g. -94.88):"
    read -r WEATHER_LONGITUDE
    ask "Location display name (e.g. Kansas City):"
    read -r WEATHER_LOCATION_NAME
    if [[ -n "${WEATHER_LATITUDE}" && -n "${WEATHER_LOCATION_NAME}" ]]; then
      ok "Weather: ${WEATHER_LOCATION_NAME} (${WEATHER_LATITUDE}, ${WEATHER_LONGITUDE})"
    else
      warn "Weather API key set but location not configured — weather cards will be blank."
    fi
  else
    skip
  fi

  # ── Google Calendar + Drive Photos ──────────────────────────────────────────
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

  # ── Microsoft Calendar ───────────────────────────────────────────────────────
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

  STRIPE_WEBHOOK_SECRET=""
fi

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
  printf "PI_TIMEZONE=%q\n"    "${PI_TIMEZONE}"
  echo ""
  echo "# ── Email / OTP ──────────────────────────────────────────────────────────────"
  printf "SMTP_HOST=%q\n"           "${SMTP_HOST:-}"
  printf "SMTP_PORT=%q\n"           "${SMTP_PORT:-587}"
  printf "SMTP_USERNAME=%q\n"       "${SMTP_USERNAME:-}"
  printf "SMTP_PASSWORD=%q\n"       "${SMTP_PASSWORD:-}"
  printf "SMTP_FROM_EMAIL=%q\n"     "${SMTP_FROM_EMAIL:-}"
  printf "SMTP_FROM_NAME=%q\n"      "${SMTP_FROM_NAME:-Landfall}"
  printf "SMTP_SSL=%q\n"            "${SMTP_SSL:-false}"
  printf "SMTP_ALLOW_INSECURE=%q\n" "${SMTP_ALLOW_INSECURE:-false}"
  echo ""
  echo "# ── Optional integrations ────────────────────────────────────────────────────"
  printf "OWM_API_KEY=%q\n"              "${OWM_API_KEY:-}"
  printf "WEATHER_LATITUDE=%q\n"         "${WEATHER_LATITUDE:-}"
  printf "WEATHER_LONGITUDE=%q\n"        "${WEATHER_LONGITUDE:-}"
  printf "WEATHER_LOCATION_NAME=%q\n"    "${WEATHER_LOCATION_NAME:-}"
  printf "GOOGLE_CLIENT_ID=%q\n"         "${GOOGLE_CLIENT_ID:-}"
  printf "GOOGLE_CLIENT_SECRET=%q\n"     "${GOOGLE_CLIENT_SECRET:-}"
  printf "GOOGLE_DRIVE_FOLDER_ID=%q\n"   "${GOOGLE_DRIVE_FOLDER_ID:-}"
  printf "MICROSOFT_CLIENT_ID=%q\n"      "${MICROSOFT_CLIENT_ID:-}"
  printf "MICROSOFT_CLIENT_SECRET=%q\n"  "${MICROSOFT_CLIENT_SECRET:-}"
  echo ""
  echo "# ── Advanced (set manually if needed) ───────────────────────────────────────"
  echo "# STRIPE_WEBHOOK_SECRET=  # add if using Stripe for pack purchases"
  printf "STRIPE_WEBHOOK_SECRET=%q\n"    "${STRIPE_WEBHOOK_SECRET:-}"
} > "${CONF_FILE}"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "${CYAN}${BOLD}Summary${RESET}"
echo ""
info "Hostname:  ${PI_HOSTNAME}  →  ${PI_HOSTNAME}.local"
info "Timezone:  ${PI_TIMEZONE}"
[[ -n "${WIFI_SSID}" ]] && info "WiFi:      ${WIFI_SSID} (${WIFI_COUNTRY})" \
                        || info "WiFi:      ethernet only"
[[ -n "${SMTP_HOST:-}" ]]           && info "Email:     ${SMTP_HOST}:${SMTP_PORT:-587} (OTP sign-in enabled)" \
                                     || info "Email:     not configured — OTP codes logged to server logs"
[[ -n "${OWM_API_KEY:-}" ]]         && info "Weather:   ${WEATHER_LOCATION_NAME:-unknown location} (${WEATHER_LATITUDE:-?}, ${WEATHER_LONGITUDE:-?})" \
                                     || info "Weather:   not configured"
[[ -n "${GOOGLE_CLIENT_ID:-}" ]]    && info "Google:    enabled (Calendar + Drive)" \
                                     || info "Google:    not configured"
[[ -n "${MICROSOFT_CLIENT_ID:-}" ]] && info "Microsoft: enabled (Calendar)" \
                                     || info "Microsoft: not configured"
echo ""
ok "Saved: ${CONF_FILE}"
info ""
info "Next:  bash deploy/pi-gen/build.sh"
echo ""
