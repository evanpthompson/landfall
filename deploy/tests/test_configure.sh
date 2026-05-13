#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CONFIGURE="${REPO_ROOT}/deploy/pi-gen/configure.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

run_configure() {
  local output="$1"
  local input="$2"
  printf "%b" "${input}" | LANDFALL_CONFIG_OUTPUT="${output}" bash "${CONFIGURE}" > /dev/null
}

# ── Default (all blanks): no WiFi, no SMTP, no integrations ──────────────────
# Prompts (blank → default): country, SSID (skip), hostname, SMTP host (skip),
# weather, Google client ID (skip), Microsoft client ID (skip), Stripe.
default_conf="${tmp}/default.conf"
run_configure "${default_conf}" '\n\n\n\n\n\n\n\n'

bash -n "${default_conf}"
source "${default_conf}"
[[ "${WIFI_COUNTRY}" == "US" ]]
[[ "${WIFI_SSID}" == "" ]]
[[ "${WIFI_PASSWORD}" == "" ]]
[[ "${PI_HOSTNAME}" == "landfall" ]]
[[ "${SMTP_HOST}" == "" ]]
[[ "${OWM_API_KEY}" == "" ]]
[[ "${GOOGLE_CLIENT_ID}" == "" ]]
[[ "${MICROSOFT_CLIENT_ID}" == "" ]]
[[ "${STRIPE_WEBHOOK_SECRET}" == "" ]]

# ── Configured (all fields, including SMTP) ───────────────────────────────────
# Input order mirrors configure.sh's prompt sequence:
#   country, SSID, WiFi password, hostname,
#   SMTP host, port (default), username, password, from email, from name (default), SSL (default),
#   weather key,
#   Google client ID, Google client secret, Google Drive folder,
#   Microsoft client ID, Microsoft client secret,
#   Stripe secret.
configured_conf="${tmp}/configured.conf"
run_configure "${configured_conf}" 'GB\nKitchen WiFi\npa ss $word\nkitchen-pi\nsmtp.example.com\n\nuser@example.com\nsmtppass\nnoreply@example.com\n\n\nweather key\nclient id\ngoogle secret\ndrive folder\nms client\nms secret\nstripe secret\n'

bash -n "${configured_conf}"
source "${configured_conf}"
[[ "${WIFI_COUNTRY}" == "GB" ]]
[[ "${WIFI_SSID}" == "Kitchen WiFi" ]]
[[ "${WIFI_PASSWORD}" == 'pa ss $word' ]]
[[ "${PI_HOSTNAME}" == "kitchen-pi" ]]
[[ "${SMTP_HOST}" == "smtp.example.com" ]]
[[ "${SMTP_PORT}" == "587" ]]
[[ "${SMTP_USERNAME}" == "user@example.com" ]]
[[ "${SMTP_PASSWORD}" == "smtppass" ]]
[[ "${SMTP_FROM_EMAIL}" == "noreply@example.com" ]]
[[ "${SMTP_FROM_NAME}" == "Landfall" ]]
[[ "${SMTP_SSL}" == "false" ]]
[[ "${OWM_API_KEY}" == "weather key" ]]
[[ "${GOOGLE_CLIENT_ID}" == "client id" ]]
[[ "${GOOGLE_CLIENT_SECRET}" == "google secret" ]]
[[ "${GOOGLE_DRIVE_FOLDER_ID}" == "drive folder" ]]
[[ "${MICROSOFT_CLIENT_ID}" == "ms client" ]]
[[ "${MICROSOFT_CLIENT_SECRET}" == "ms secret" ]]
[[ "${STRIPE_WEBHOOK_SECRET}" == "stripe secret" ]]

grep -Eq '^WIFI_PASSWORD=' "${configured_conf}"
grep -Eq '^SMTP_HOST=' "${configured_conf}"
grep -Eq '^SMTP_PASSWORD=' "${configured_conf}"
