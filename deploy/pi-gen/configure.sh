#!/usr/bin/env bash
# Landfall Pi — pre-build configuration wizard.
# Run this BEFORE build.sh. Writes landfall-build.conf which build.sh reads
# to bake WiFi, hostname, and integration credentials into the SD card image.
# All secrets (DB password, JWT keys, etc.) are generated on the Pi at first
# boot — nothing sensitive is stored here except integration API keys.
#
# Usage:
#   bash deploy/pi-gen/configure.sh                      # interactive wizard
#   bash deploy/pi-gen/configure.sh --from-env FILE      # load from KEY=value file
#   bash deploy/pi-gen/configure.sh --from-yaml FILE     # load from passwords.yaml
#
# --from-yaml reads integration credentials (SMTP, OWM, Google, Microsoft) from
# the Serverpod passwords.yaml. Pi-specific fields that passwords.yaml does not
# contain (hostname, WiFi, timezone) are taken from environment variables or
# their defaults:
#   PI_HOSTNAME=kitchen-pi PI_TIMEZONE=America/Chicago \
#     bash deploy/pi-gen/configure.sh --from-yaml server/landfall_server/config/passwords.yaml
#
# See deploy/pi-gen/landfall-build.conf.example for a full --from-env template.

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

# Extract a value from a passwords.yaml-style file.
# Matches:  <whitespace>key: 'value'  or  key: "value"  or  key: bare_value
yaml_get() {
  local key="$1" file="$2"
  sed -n "s/^[[:space:]]*${key}: *'\(.*\)'.*/\1/p;
          s/^[[:space:]]*${key}: *\"\(.*\)\".*/\1/p;
          s/^[[:space:]]*${key}: *\([^'\"#][^#]*\)/\1/p" "${file}" \
    | head -1 | sed 's/[[:space:]]*$//'
}

# ── Argument parsing ──────────────────────────────────────────────────────────
FROM_ENV_FILE=""
FROM_YAML_FILE=""
case "${1:-}" in
  --from-env)
    if [[ -z "${2:-}" || ! -f "${2}" ]]; then
      echo "Usage: $0 --from-env <path-to-env-file>" >&2; exit 1
    fi
    FROM_ENV_FILE="${2}"
    ;;
  --from-yaml)
    if [[ -z "${2:-}" || ! -f "${2}" ]]; then
      echo "Usage: $0 --from-yaml <path-to-passwords.yaml>" >&2; exit 1
    fi
    FROM_YAML_FILE="${2}"
    ;;
esac

if [[ -n "${FROM_YAML_FILE}" ]]; then
  echo ""
  echo "${CYAN}${BOLD}Landfall — Pi image configuration (from passwords.yaml)${RESET}"
  echo ""
  info "Loading credentials from: ${FROM_YAML_FILE}"
  info "Pi-specific fields (hostname, WiFi, timezone) use environment variable"
  info "overrides or their defaults. Set them before calling this script, e.g.:"
  info "  PI_HOSTNAME=kitchen-pi PI_TIMEZONE=America/Chicago bash configure.sh --from-yaml ..."

  # Pi-specific fields — not in passwords.yaml, use env overrides or defaults
  WIFI_COUNTRY="${WIFI_COUNTRY:-US}"
  WIFI_SSID="${WIFI_SSID:-}"
  WIFI_PASSWORD="${WIFI_PASSWORD:-}"
  PI_HOSTNAME="${PI_HOSTNAME:-landfall}"
  PI_TIMEZONE="${PI_TIMEZONE:-Etc/UTC}"
  # debug | production. Debug images enable local-loopback telemetry,
  # bake the SSH key into authorized_keys, and assume an operator wants
  # full diagnostic visibility. Production = ship-ready.
  LANDFALL_BUILD_TYPE="${LANDFALL_BUILD_TYPE:-production}"
  # SSH: at least one of these should be set so the operator can recover the device.
  SSH_AUTHORIZED_KEY="${SSH_AUTHORIZED_KEY:-$(yaml_get sshAuthorizedKey "${FROM_YAML_FILE}")}"
  SSH_PASSWORD="${SSH_PASSWORD:-$(yaml_get sshPassword "${FROM_YAML_FILE}")}"
  # Static IP (all optional — if STATIC_IP_CIDR is blank, DHCP is used).
  STATIC_IP_CIDR="${STATIC_IP_CIDR:-$(yaml_get staticIpCidr "${FROM_YAML_FILE}")}"
  STATIC_GATEWAY="${STATIC_GATEWAY:-$(yaml_get staticGateway "${FROM_YAML_FILE}")}"
  STATIC_DNS="${STATIC_DNS:-$(yaml_get staticDns "${FROM_YAML_FILE}")}"
  STATIC_INTERFACE="${STATIC_INTERFACE:-$(yaml_get staticInterface "${FROM_YAML_FILE}")}"
  STATIC_INTERFACE="${STATIC_INTERFACE:-eth0}"

  # Integration credentials from passwords.yaml (production section keys)
  SMTP_HOST="$(yaml_get smtpHost "${FROM_YAML_FILE}")"
  SMTP_PORT="$(yaml_get smtpPort "${FROM_YAML_FILE}")"
  SMTP_PORT="${SMTP_PORT:-587}"
  SMTP_USERNAME="$(yaml_get smtpUsername "${FROM_YAML_FILE}")"
  SMTP_PASSWORD="$(yaml_get smtpPassword "${FROM_YAML_FILE}")"
  SMTP_FROM_EMAIL="$(yaml_get smtpFromEmail "${FROM_YAML_FILE}")"
  SMTP_FROM_NAME="$(yaml_get smtpFromName "${FROM_YAML_FILE}")"
  SMTP_FROM_NAME="${SMTP_FROM_NAME:-Landfall}"
  SMTP_SSL="$(yaml_get smtpSsl "${FROM_YAML_FILE}")"
  SMTP_SSL="${SMTP_SSL:-false}"
  SMTP_ALLOW_INSECURE="$(yaml_get smtpAllowInsecure "${FROM_YAML_FILE}")"
  SMTP_ALLOW_INSECURE="${SMTP_ALLOW_INSECURE:-false}"

  OWM_API_KEY="$(yaml_get openWeatherMapApiKey "${FROM_YAML_FILE}")"
  WEATHER_LATITUDE="$(yaml_get weatherLatitude "${FROM_YAML_FILE}")"
  WEATHER_LONGITUDE="$(yaml_get weatherLongitude "${FROM_YAML_FILE}")"
  WEATHER_LOCATION_NAME="$(yaml_get weatherLocationName "${FROM_YAML_FILE}")"

  GOOGLE_CLIENT_ID="$(yaml_get googleOAuthClientId "${FROM_YAML_FILE}")"
  GOOGLE_CLIENT_SECRET="$(yaml_get googleOAuthClientSecret "${FROM_YAML_FILE}")"
  GOOGLE_DRIVE_FOLDER_ID="$(yaml_get googleDriveFolderId "${FROM_YAML_FILE}")"

  MICROSOFT_CLIENT_ID="$(yaml_get microsoftClientId "${FROM_YAML_FILE}")"
  MICROSOFT_CLIENT_SECRET="$(yaml_get microsoftClientSecret "${FROM_YAML_FILE}")"

  STRIPE_WEBHOOK_SECRET="$(yaml_get stripeWebhookSecret "${FROM_YAML_FILE}")"

  # Dev-build-only telemetry — empty in production passwords.yaml.
  LANDFALL_TELEMETRY_ENDPOINT="${LANDFALL_TELEMETRY_ENDPOINT:-$(yaml_get landfallTelemetryEndpoint "${FROM_YAML_FILE}")}"
  LANDFALL_TELEMETRY_API_KEY="${LANDFALL_TELEMETRY_API_KEY:-$(yaml_get landfallTelemetryApiKey "${FROM_YAML_FILE}")}"

  if [[ -n "${OWM_API_KEY}" && -z "${WEATHER_LATITUDE}" ]]; then
    warn "openWeatherMapApiKey set but weatherLatitude/weatherLocationName missing — weather cards will be blank."
  fi

  ok "Loaded"

elif [[ -n "${FROM_ENV_FILE}" ]]; then
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
  LANDFALL_BUILD_TYPE=""
  SSH_AUTHORIZED_KEY=""
  SSH_PASSWORD=""
  STATIC_IP_CIDR=""
  STATIC_GATEWAY=""
  STATIC_DNS=""
  STATIC_INTERFACE=""
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
  LANDFALL_BUILD_TYPE="${LANDFALL_BUILD_TYPE:-production}"
  STATIC_INTERFACE="${STATIC_INTERFACE:-eth0}"
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

  # ── SSH access ───────────────────────────────────────────────────────────────
  section "SSH access (strongly recommended)"
  dim "Without SSH, the only way to recover the device is to attach a keyboard."
  dim "Provide a public key (preferred) OR a password — at least one is required."
  echo ""
  SSH_AUTHORIZED_KEY=""
  SSH_PASSWORD=""
  default_key="${HOME}/.ssh/id_ed25519.pub"
  [[ -f "${default_key}" ]] || default_key="${HOME}/.ssh/id_rsa.pub"
  if [[ -f "${default_key}" ]]; then
    ask "Path to SSH public key [${default_key} — blank to skip]:"
  else
    ask "Path to SSH public key [blank to skip]:"
  fi
  read -r ssh_key_path
  if [[ -z "${ssh_key_path}" && -f "${default_key}" ]]; then
    ssh_key_path="${default_key}"
  fi
  if [[ -n "${ssh_key_path}" ]]; then
    if [[ -f "${ssh_key_path}" ]]; then
      SSH_AUTHORIZED_KEY="$(cat "${ssh_key_path}")"
      ok "SSH key loaded from ${ssh_key_path}"
    else
      warn "SSH key file not found: ${ssh_key_path}"
    fi
  fi
  echo ""
  ask "SSH password for 'landfall' user [blank to skip]:"
  read -rs SSH_PASSWORD
  echo ""
  if [[ -n "${SSH_PASSWORD}" ]]; then
    ok "SSH password set (key auth still preferred if key is loaded)"
  elif [[ -z "${SSH_AUTHORIZED_KEY}" ]]; then
    warn "No SSH key AND no password — landfall user will be locked out."
    warn "You will only be able to reach the device by attaching a keyboard."
  fi

  # ── Static IP (optional) ─────────────────────────────────────────────────────
  section "Static IP  (optional)"
  dim "Configure a fixed IP for this device. Leave blank to use DHCP (default)."
  dim "Useful for routers that don't support DHCP reservations or running headless."
  echo ""
  ask "Static IP address with CIDR (e.g. 192.168.1.129/24) [blank for DHCP]:"
  read -r STATIC_IP_CIDR
  STATIC_GATEWAY=""
  STATIC_DNS=""
  STATIC_INTERFACE="eth0"
  if [[ -n "${STATIC_IP_CIDR}" ]]; then
    ask "Default gateway (e.g. 192.168.1.1):"
    read -r STATIC_GATEWAY
    ask "DNS servers, comma separated [1.1.1.1,8.8.8.8]:"
    read -r STATIC_DNS
    STATIC_DNS="${STATIC_DNS:-1.1.1.1,8.8.8.8}"
    ask "Interface [eth0 — use wlan0 for WiFi]:"
    read -r STATIC_INTERFACE
    STATIC_INTERFACE="${STATIC_INTERFACE:-eth0}"
    ok "Static IP: ${STATIC_IP_CIDR} via ${STATIC_GATEWAY} on ${STATIC_INTERFACE}"
  else
    skip
  fi

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
  LANDFALL_BUILD_TYPE="${LANDFALL_BUILD_TYPE:-production}"
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
  printf "LANDFALL_BUILD_TYPE=%q\n" "${LANDFALL_BUILD_TYPE}"
  echo ""
  echo "# ── SSH access ───────────────────────────────────────────────────────────────"
  printf "SSH_AUTHORIZED_KEY=%q\n" "${SSH_AUTHORIZED_KEY:-}"
  printf "SSH_PASSWORD=%q\n"       "${SSH_PASSWORD:-}"
  echo ""
  echo "# ── Static IP (blank STATIC_IP_CIDR = use DHCP) ──────────────────────────────"
  printf "STATIC_IP_CIDR=%q\n"   "${STATIC_IP_CIDR:-}"
  printf "STATIC_GATEWAY=%q\n"   "${STATIC_GATEWAY:-}"
  printf "STATIC_DNS=%q\n"       "${STATIC_DNS:-}"
  printf "STATIC_INTERFACE=%q\n" "${STATIC_INTERFACE:-eth0}"
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
  echo ""
  echo "# ── Telemetry (DEV BUILDS ONLY — leave blank for production) ─────────────────"
  echo "# Self-hosted telemetry endpoint. When set, the Pi posts crash-loop and"
  echo "# app_launched events to your own Landfall server. NEVER set on shipping"
  echo "# images. See docs/build_defines.md."
  printf "LANDFALL_TELEMETRY_ENDPOINT=%q\n" "${LANDFALL_TELEMETRY_ENDPOINT:-}"
  printf "LANDFALL_TELEMETRY_API_KEY=%q\n"  "${LANDFALL_TELEMETRY_API_KEY:-}"
} > "${CONF_FILE}"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "${CYAN}${BOLD}Summary${RESET}"
echo ""
info "Hostname:  ${PI_HOSTNAME}  →  ${PI_HOSTNAME}.local"
info "Timezone:  ${PI_TIMEZONE}"
[[ -n "${WIFI_SSID}" ]] && info "WiFi:      ${WIFI_SSID} (${WIFI_COUNTRY})" \
                        || info "WiFi:      ethernet only"
[[ -n "${STATIC_IP_CIDR:-}" ]] && info "Static IP: ${STATIC_IP_CIDR} via ${STATIC_GATEWAY} on ${STATIC_INTERFACE:-eth0}" \
                               || info "Static IP: not configured (DHCP)"
if [[ -n "${SSH_AUTHORIZED_KEY:-}" && -n "${SSH_PASSWORD:-}" ]]; then
  info "SSH:       key + password configured"
elif [[ -n "${SSH_AUTHORIZED_KEY:-}" ]]; then
  info "SSH:       key configured (no password)"
elif [[ -n "${SSH_PASSWORD:-}" ]]; then
  info "SSH:       password configured (no key)"
else
  info "SSH:       NONE — landfall user will be unreachable over network"
fi
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
