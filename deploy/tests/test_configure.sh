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

run_configure_from_env() {
  local output="$1"
  local env_file="$2"
  LANDFALL_CONFIG_OUTPUT="${output}" bash "${CONFIGURE}" --from-env "${env_file}" > /dev/null
}

# ── Default (all blanks): no WiFi, no SMTP, no integrations ──────────────────
# Prompts (blank → default): country, SSID (skip), hostname, timezone (skip),
# SMTP host (skip), weather, Google client ID (skip), Microsoft client ID (skip).
default_conf="${tmp}/default.conf"
run_configure "${default_conf}" '\n\n\n\n\n\n\n\n\n\n'

bash -n "${default_conf}"
source "${default_conf}"
[[ "${WIFI_COUNTRY}" == "US" ]]
[[ "${WIFI_SSID}" == "" ]]
[[ "${WIFI_PASSWORD}" == "" ]]
[[ "${PI_HOSTNAME}" == "landfall" ]]
[[ "${PI_TIMEZONE}" == "Etc/UTC" ]]
[[ "${SMTP_HOST}" == "" ]]
[[ "${OWM_API_KEY}" == "" ]]
[[ "${WEATHER_LATITUDE}" == "" ]]
[[ "${WEATHER_LONGITUDE}" == "" ]]
[[ "${WEATHER_LOCATION_NAME}" == "" ]]
[[ "${GOOGLE_CLIENT_ID}" == "" ]]
[[ "${MICROSOFT_CLIENT_ID}" == "" ]]

# ── Configured (all fields, including SMTP) ───────────────────────────────────
# Input order mirrors configure.sh's prompt sequence:
#   country, SSID, WiFi password, hostname, timezone,
#   SMTP host, port (default), username, password, from email, from name (default), SSL (default),
#   weather key,
#   Google client ID, Google client secret, Google Drive folder,
#   Microsoft client ID, Microsoft client secret.
configured_conf="${tmp}/configured.conf"
run_configure "${configured_conf}" 'GB\nKitchen WiFi\npa ss $word\nkitchen-pi\nEurope/London\nsmtp.example.com\n\nuser@example.com\nsmtppass\nnoreply@example.com\n\n\nweather key\n51.5074\n-0.1278\nLondon\nclient id\ngoogle secret\ndrive folder\nms client\nms secret\n'

bash -n "${configured_conf}"
source "${configured_conf}"
[[ "${WIFI_COUNTRY}" == "GB" ]]
[[ "${WIFI_SSID}" == "Kitchen WiFi" ]]
[[ "${WIFI_PASSWORD}" == 'pa ss $word' ]]
[[ "${PI_HOSTNAME}" == "kitchen-pi" ]]
[[ "${PI_TIMEZONE}" == "Europe/London" ]]
[[ "${SMTP_HOST}" == "smtp.example.com" ]]
[[ "${SMTP_PORT}" == "587" ]]
[[ "${SMTP_USERNAME}" == "user@example.com" ]]
[[ "${SMTP_PASSWORD}" == "smtppass" ]]
[[ "${SMTP_FROM_EMAIL}" == "noreply@example.com" ]]
[[ "${SMTP_FROM_NAME}" == "Landfall" ]]
[[ "${SMTP_SSL}" == "false" ]]
[[ "${OWM_API_KEY}" == "weather key" ]]
[[ "${WEATHER_LATITUDE}" == "51.5074" ]]
[[ "${WEATHER_LONGITUDE}" == "-0.1278" ]]
[[ "${WEATHER_LOCATION_NAME}" == "London" ]]
[[ "${GOOGLE_CLIENT_ID}" == "client id" ]]
[[ "${GOOGLE_CLIENT_SECRET}" == "google secret" ]]
[[ "${GOOGLE_DRIVE_FOLDER_ID}" == "drive folder" ]]
[[ "${MICROSOFT_CLIENT_ID}" == "ms client" ]]
[[ "${MICROSOFT_CLIENT_SECRET}" == "ms secret" ]]

grep -Eq '^WIFI_PASSWORD=' "${configured_conf}"
grep -Eq '^SMTP_HOST=' "${configured_conf}"
grep -Eq '^SMTP_PASSWORD=' "${configured_conf}"

# ── --from-env: non-interactive load from file ────────────────────────────────
env_input="${tmp}/input.env"
cat > "${env_input}" <<'EOF'
WIFI_COUNTRY=AU
WIFI_SSID=Backyard
WIFI_PASSWORD=hunter2
PI_HOSTNAME=outdoor-frame
PI_TIMEZONE=Australia/Sydney
SMTP_HOST=smtp.fastmail.com
SMTP_PORT=465
SMTP_USERNAME=me@example.com
SMTP_PASSWORD=apppass
SMTP_FROM_EMAIL=display@example.com
SMTP_FROM_NAME=OutdoorFrame
SMTP_SSL=true
OWM_API_KEY=owmkey123
WEATHER_LATITUDE=-33.8688
WEATHER_LONGITUDE=151.2093
WEATHER_LOCATION_NAME=Sydney
GOOGLE_CLIENT_ID=gcid
GOOGLE_CLIENT_SECRET=gcsecret
GOOGLE_DRIVE_FOLDER_ID=drivefolder
MICROSOFT_CLIENT_ID=msid
MICROSOFT_CLIENT_SECRET=mssecret
EOF

from_env_conf="${tmp}/from_env.conf"
run_configure_from_env "${from_env_conf}" "${env_input}"

bash -n "${from_env_conf}"
source "${from_env_conf}"
[[ "${WIFI_COUNTRY}" == "AU" ]]
[[ "${WIFI_SSID}" == "Backyard" ]]
[[ "${WIFI_PASSWORD}" == "hunter2" ]]
[[ "${PI_HOSTNAME}" == "outdoor-frame" ]]
[[ "${PI_TIMEZONE}" == "Australia/Sydney" ]]
[[ "${SMTP_HOST}" == "smtp.fastmail.com" ]]
[[ "${SMTP_PORT}" == "465" ]]
[[ "${SMTP_USERNAME}" == "me@example.com" ]]
[[ "${SMTP_PASSWORD}" == "apppass" ]]
[[ "${SMTP_FROM_EMAIL}" == "display@example.com" ]]
[[ "${SMTP_FROM_NAME}" == "OutdoorFrame" ]]
[[ "${SMTP_SSL}" == "true" ]]
[[ "${OWM_API_KEY}" == "owmkey123" ]]
[[ "${WEATHER_LATITUDE}" == "-33.8688" ]]
[[ "${WEATHER_LONGITUDE}" == "151.2093" ]]
[[ "${WEATHER_LOCATION_NAME}" == "Sydney" ]]
[[ "${GOOGLE_CLIENT_ID}" == "gcid" ]]
[[ "${GOOGLE_CLIENT_SECRET}" == "gcsecret" ]]
[[ "${GOOGLE_DRIVE_FOLDER_ID}" == "drivefolder" ]]
[[ "${MICROSOFT_CLIENT_ID}" == "msid" ]]
[[ "${MICROSOFT_CLIENT_SECRET}" == "mssecret" ]]

# ── --from-env: defaults applied when fields are absent ──────────────────────
minimal_env="${tmp}/minimal.env"
cat > "${minimal_env}" <<'EOF'
PI_HOSTNAME=minimal-frame
EOF

minimal_conf="${tmp}/minimal.conf"
run_configure_from_env "${minimal_conf}" "${minimal_env}"

bash -n "${minimal_conf}"
source "${minimal_conf}"
[[ "${PI_HOSTNAME}" == "minimal-frame" ]]
[[ "${WIFI_COUNTRY}" == "US" ]]
[[ "${PI_TIMEZONE}" == "Etc/UTC" ]]
[[ "${SMTP_PORT}" == "587" ]]
[[ "${SMTP_FROM_NAME}" == "Landfall" ]]
[[ "${SMTP_SSL}" == "false" ]]
