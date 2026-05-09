#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD="${REPO_ROOT}/deploy/pi-gen/build.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

pi_gen="${tmp}/pi-gen"
bundle="${tmp}/bundle"
server_tarball="${tmp}/landfall-server.tar.gz"
conf="${REPO_ROOT}/deploy/pi-gen/landfall-build.conf"
conf_backup="${tmp}/landfall-build.conf.backup"
had_conf=0

if [[ -f "${conf}" ]]; then
  cp "${conf}" "${conf_backup}"
  had_conf=1
fi
restore_conf() {
  if (( had_conf == 1 )); then
    cp "${conf_backup}" "${conf}"
  else
    rm -f "${conf}"
  fi
  rm -rf "${tmp}"
}
trap restore_conf EXIT

mkdir -p "${pi_gen}" "${bundle}/data" "${bundle}/lib"
printf 'TARGET_HOSTNAME="raspberrypi"\n' > "${pi_gen}/config"
touch "${bundle}/display" "${bundle}/data/icudtl.dat" "${bundle}/lib/libapp.so"
printf 'server image\n' > "${server_tarball}"

cat > "${conf}" <<'CONF'
WIFI_COUNTRY=GB
WIFI_SSID=Kitchen\ WiFi
WIFI_PASSWORD=pa\ ss\ \$word
PI_HOSTNAME=kitchen-pi
OWM_API_KEY=weather\ key
GOOGLE_CLIENT_ID=google\ client
GOOGLE_CLIENT_SECRET=google\ secret
GOOGLE_DRIVE_FOLDER_ID=drive\ folder
MICROSOFT_CLIENT_ID=ms\ client
MICROSOFT_CLIENT_SECRET=ms\ secret
STRIPE_WEBHOOK_SECRET=stripe\ secret
CONF

LANDFALL_PI_GEN_DIR="${pi_gen}" \
LANDFALL_LINUX_BUNDLE="${bundle}" \
LANDFALL_SERVER_TARBALL_SOURCE="${server_tarball}" \
  bash "${BUILD}" --stage-only > "${tmp}/build.log"

stage="${pi_gen}/stage2-landfall/00-landfall/files"
[[ -d "${stage}/deploy" ]]
[[ -f "${stage}/deploy/docker-compose.prod.yml" ]]
[[ -f "${stage}/integrations.env" ]]
[[ -f "${stage}/wifi-country" ]]
[[ "$(cat "${stage}/wifi-country")" == "GB" ]]
[[ -f "${stage}/wifi.nmconnection" ]]
if [[ "$(uname -s)" == "Darwin" ]]; then
  wifi_mode="$(stat -f '%Lp' "${stage}/wifi.nmconnection")"
else
  wifi_mode="$(stat -c '%a' "${stage}/wifi.nmconnection")"
fi
[[ "${wifi_mode}" == "600" ]]
[[ -f "${stage}/bundle/display" ]]
[[ -f "${stage}/landfall-server.tar.gz" ]]
grep -q 'TARGET_HOSTNAME="kitchen-pi"' "${pi_gen}/config"
grep -q 'WPA_COUNTRY="GB"' "${pi_gen}/config"

source "${stage}/integrations.env"
[[ "${GOOGLE_CLIENT_SECRET}" == "google secret" ]]
[[ "${MICROSOFT_CLIENT_SECRET}" == "ms secret" ]]
[[ "${STRIPE_WEBHOOK_SECRET}" == "stripe secret" ]]

if grep -Eq 'DB_PASSWORD|JWT_HMAC_KEY|SERVERPOD_SERVICE_SECRET|PHOTO_SIGNING_SECRET' "${stage}/integrations.env"; then
  echo "Runtime secrets were staged into integrations.env" >&2
  exit 1
fi

cat > "${conf}" <<'CONF'
WIFI_COUNTRY=US
WIFI_SSID=''
WIFI_PASSWORD=''
PI_HOSTNAME=landfall
OWM_API_KEY=''
GOOGLE_CLIENT_ID=''
GOOGLE_CLIENT_SECRET=''
GOOGLE_DRIVE_FOLDER_ID=''
MICROSOFT_CLIENT_ID=''
MICROSOFT_CLIENT_SECRET=''
STRIPE_WEBHOOK_SECRET=''
CONF

rm -rf "${pi_gen}/stage2-landfall"
LANDFALL_PI_GEN_DIR="${pi_gen}" \
LANDFALL_LINUX_BUNDLE="${bundle}" \
LANDFALL_SERVER_TARBALL_SOURCE="${server_tarball}" \
  bash "${BUILD}" --stage-only > "${tmp}/build-no-wifi.log"

[[ ! -f "${pi_gen}/stage2-landfall/00-landfall/files/wifi.nmconnection" ]]
