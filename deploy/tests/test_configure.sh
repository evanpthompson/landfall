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
  # Use a clean HOME so the wizard's default SSH key path doesn't pick up the
  # developer's id_ed25519.pub (or id_rsa.pub) and turn this into an interactive
  # test that varies between machines. Tests cover SSH via --from-env / --from-yaml.
  printf "%b" "${input}" | HOME="${tmp}/clean-home" LANDFALL_CONFIG_OUTPUT="${output}" bash "${CONFIGURE}" > /dev/null
}

run_configure_from_env() {
  local output="$1"
  local env_file="$2"
  LANDFALL_CONFIG_OUTPUT="${output}" bash "${CONFIGURE}" --from-env "${env_file}" > /dev/null
}

run_configure_from_yaml() {
  local output="$1"
  local yaml_file="$2"
  shift 2
  LANDFALL_CONFIG_OUTPUT="${output}" env "$@" bash "${CONFIGURE}" --from-yaml "${yaml_file}" > /dev/null
}

# ── Default (all blanks): no WiFi, no SSH, no static IP, no SMTP, no integrations
# Prompts (blank → default): country, SSID (skip), hostname, timezone (skip),
# ssh-key-path (skip), ssh-password (skip), static-ip-cidr (skip),
# SMTP host (skip), weather, Google client ID (skip), Microsoft client ID (skip).
default_conf="${tmp}/default.conf"
run_configure "${default_conf}" '\n\n\n\n\n\n\n\n\n\n\n\n\n'

bash -n "${default_conf}"
source "${default_conf}"
[[ "${WIFI_COUNTRY}" == "US" ]]
[[ "${WIFI_SSID}" == "" ]]
[[ "${WIFI_PASSWORD}" == "" ]]
[[ "${PI_HOSTNAME}" == "landfall" ]]
[[ "${PI_TIMEZONE}" == "Etc/UTC" ]]
[[ "${SSH_AUTHORIZED_KEY}" == "" ]]
[[ "${SSH_PASSWORD}" == "" ]]
[[ "${STATIC_IP_CIDR}" == "" ]]
[[ "${STATIC_GATEWAY}" == "" ]]
[[ "${STATIC_INTERFACE}" == "eth0" ]]
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
# After timezone the new prompts are: ssh-key-path (skip), ssh-password (skip),
# static-ip-cidr (skip). Three blank lines.
run_configure "${configured_conf}" 'GB\nKitchen WiFi\npa ss $word\nkitchen-pi\nEurope/London\n\n\n\nsmtp.example.com\n\nuser@example.com\nsmtppass\nnoreply@example.com\n\n\nweather key\n51.5074\n-0.1278\nLondon\nclient id\ngoogle secret\ndrive folder\nms client\nms secret\n'

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
SSH_AUTHORIZED_KEY='ssh-ed25519 AAAATEST user@host'
SSH_PASSWORD=envpass
STATIC_IP_CIDR=10.0.0.50/24
STATIC_GATEWAY=10.0.0.1
STATIC_DNS=1.1.1.1,8.8.8.8
STATIC_INTERFACE=eth0
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
[[ "${SSH_AUTHORIZED_KEY}" == "ssh-ed25519 AAAATEST user@host" ]]
[[ "${SSH_PASSWORD}" == "envpass" ]]
[[ "${STATIC_IP_CIDR}" == "10.0.0.50/24" ]]
[[ "${STATIC_GATEWAY}" == "10.0.0.1" ]]
[[ "${STATIC_DNS}" == "1.1.1.1,8.8.8.8" ]]
[[ "${STATIC_INTERFACE}" == "eth0" ]]
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

# ── --from-yaml: credentials from passwords.yaml, pi fields from env vars ────
yaml_input="${tmp}/passwords.yaml"
cat > "${yaml_input}" <<'EOF'
production:
  sshAuthorizedKey: 'ssh-rsa AAAAYAML user@yaml'
  sshPassword: 'yamlpass'
  staticIpCidr: '172.16.0.42/24'
  staticGateway: '172.16.0.1'
  staticDns: '9.9.9.9,8.8.4.4'
  staticInterface: 'eth0'
  smtpHost: 'smtp.sendgrid.net'
  smtpPort: '587'
  smtpUsername: 'apikey'
  smtpPassword: 'SG.testkey'
  smtpFromEmail: 'noreply@example.com'
  smtpFromName: 'MyFrame'
  smtpSsl: 'false'
  smtpAllowInsecure: 'false'
  openWeatherMapApiKey: 'owm-yaml-key'
  weatherLatitude: '40.7128'
  weatherLongitude: '-74.0060'
  weatherLocationName: 'New York'
  googleOAuthClientId: 'yaml-gcid'
  googleOAuthClientSecret: 'yaml-gcsecret'
  googleDriveFolderId: 'yaml-drivefolder'
  microsoftClientId: 'yaml-msid'
  microsoftClientSecret: 'yaml-mssecret'
EOF

yaml_conf="${tmp}/from_yaml.conf"
run_configure_from_yaml "${yaml_conf}" "${yaml_input}" \
  PI_HOSTNAME=yaml-frame PI_TIMEZONE=America/New_York \
  WIFI_SSID=YamlNet WIFI_PASSWORD=yamlpass WIFI_COUNTRY=CA

bash -n "${yaml_conf}"
source "${yaml_conf}"
[[ "${PI_HOSTNAME}" == "yaml-frame" ]]
[[ "${PI_TIMEZONE}" == "America/New_York" ]]
[[ "${WIFI_COUNTRY}" == "CA" ]]
[[ "${WIFI_SSID}" == "YamlNet" ]]
[[ "${WIFI_PASSWORD}" == "yamlpass" ]]
[[ "${SSH_AUTHORIZED_KEY}" == "ssh-rsa AAAAYAML user@yaml" ]]
[[ "${SSH_PASSWORD}" == "yamlpass" ]]
[[ "${STATIC_IP_CIDR}" == "172.16.0.42/24" ]]
[[ "${STATIC_GATEWAY}" == "172.16.0.1" ]]
[[ "${STATIC_DNS}" == "9.9.9.9,8.8.4.4" ]]
# yaml `staticInterface: 'eth0'` is honored even when WiFi is set. Auto-wlan0
# only kicks in when neither env nor yaml supplied an interface — otherwise
# we'd silently produce a manual-IP WiFi connection the operator never asked
# for (static IP belongs to ethernet here; WiFi gets a separate DHCP profile).
[[ "${STATIC_INTERFACE}" == "eth0" ]] \
  || { echo "FAIL: yaml staticInterface=eth0 overridden to ${STATIC_INTERFACE}"; exit 1; }
[[ "${SMTP_HOST}" == "smtp.sendgrid.net" ]]
[[ "${SMTP_USERNAME}" == "apikey" ]]
[[ "${SMTP_PASSWORD}" == "SG.testkey" ]]
[[ "${SMTP_FROM_NAME}" == "MyFrame" ]]
[[ "${OWM_API_KEY}" == "owm-yaml-key" ]]
[[ "${WEATHER_LATITUDE}" == "40.7128" ]]
[[ "${WEATHER_LONGITUDE}" == "-74.0060" ]]
[[ "${WEATHER_LOCATION_NAME}" == "New York" ]]
[[ "${GOOGLE_CLIENT_ID}" == "yaml-gcid" ]]
[[ "${GOOGLE_CLIENT_SECRET}" == "yaml-gcsecret" ]]
[[ "${GOOGLE_DRIVE_FOLDER_ID}" == "yaml-drivefolder" ]]
[[ "${MICROSOFT_CLIENT_ID}" == "yaml-msid" ]]
[[ "${MICROSOFT_CLIENT_SECRET}" == "yaml-mssecret" ]]

# ── --from-yaml: pi-specific defaults when env vars are absent ────────────────
yaml_defaults_conf="${tmp}/from_yaml_defaults.conf"
run_configure_from_yaml "${yaml_defaults_conf}" "${yaml_input}"

bash -n "${yaml_defaults_conf}"
source "${yaml_defaults_conf}"
[[ "${PI_HOSTNAME}" == "landfall" ]]
[[ "${PI_TIMEZONE}" == "Etc/UTC" ]]
[[ "${WIFI_COUNTRY}" == "US" ]]
[[ "${WIFI_SSID}" == "" ]]

# ── yaml_get: quoted value with inline comment must not capture the comment ───
# Reproduces the real-world bug where staticInterface: 'eth0'  # 'eth0' for
# wired was parsed as eth0'  # 'eth0' for wired (greedy quote match).
comment_yaml="${tmp}/comment_test.yaml"
cat > "${comment_yaml}" <<'EOF'
production:
  staticInterface: 'eth0'           # 'eth0' for wired, 'wlan0' for WiFi
  smtpHost: 'smtp.example.com'
  smtpPort: '587'
  smtpUsername: 'user'
  smtpPassword: 'pass'
  smtpFromEmail: 'a@b.com'
  smtpSsl: 'false'
  smtpAllowInsecure: 'false'
EOF
comment_conf="${tmp}/comment_test.conf"
run_configure_from_yaml "${comment_conf}" "${comment_yaml}"
source "${comment_conf}"
[[ "${STATIC_INTERFACE}" == "eth0" ]] \
  || { echo "FAIL: yaml_get captured comment: STATIC_INTERFACE=${STATIC_INTERFACE}"; exit 1; }

# ── --from-yaml: explicit STATIC_INTERFACE env var beats WiFi auto-wlan0 ──────
explicit_if_conf="${tmp}/explicit_if.conf"
run_configure_from_yaml "${explicit_if_conf}" "${yaml_input}" \
  WIFI_SSID=MyNet WIFI_PASSWORD=pass STATIC_INTERFACE=eth0
source "${explicit_if_conf}"
[[ "${STATIC_INTERFACE}" == "eth0" ]] \
  || { echo "FAIL: explicit STATIC_INTERFACE=eth0 was overridden to ${STATIC_INTERFACE}"; exit 1; }

# ── --from-yaml: auto-wlan0 when WiFi set and NO interface in env or yaml ─────
no_if_yaml="${tmp}/no_iface.yaml"
cat > "${no_if_yaml}" <<'EOF'
production:
  smtpHost: 'smtp.example.com'
  smtpPort: '587'
  smtpUsername: 'user'
  smtpPassword: 'pass'
  smtpFromEmail: 'a@b.com'
  smtpSsl: 'false'
  smtpAllowInsecure: 'false'
EOF
auto_wlan_conf="${tmp}/auto_wlan.conf"
run_configure_from_yaml "${auto_wlan_conf}" "${no_if_yaml}" \
  WIFI_SSID=MyNet WIFI_PASSWORD=pass
source "${auto_wlan_conf}"
[[ "${STATIC_INTERFACE}" == "wlan0" ]] \
  || { echo "FAIL: auto-wlan0 fallback broke: STATIC_INTERFACE=${STATIC_INTERFACE}"; exit 1; }

# ── --from-yaml: env-var override beats YAML value for SSH/static IP ─────────
override_conf="${tmp}/from_yaml_override.conf"
run_configure_from_yaml "${override_conf}" "${yaml_input}" \
  STATIC_IP_CIDR=192.168.50.50/24 STATIC_GATEWAY=192.168.50.1 \
  SSH_PASSWORD=override-pass

bash -n "${override_conf}"
source "${override_conf}"
[[ "${STATIC_IP_CIDR}" == "192.168.50.50/24" ]]
[[ "${STATIC_GATEWAY}" == "192.168.50.1" ]]
[[ "${SSH_PASSWORD}" == "override-pass" ]]
# Untouched values still come from YAML
[[ "${SSH_AUTHORIZED_KEY}" == "ssh-rsa AAAAYAML user@yaml" ]]
[[ "${STATIC_DNS}" == "9.9.9.9,8.8.4.4" ]]
