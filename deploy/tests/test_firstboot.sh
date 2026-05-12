#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
FIRSTBOOT="${REPO_ROOT}/deploy/pi-gen/stage2-landfall/00-landfall/files/firstboot.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

assert_contains() {
  local file="$1"
  local pattern="$2"
  grep -Eq "${pattern}" "${file}" || {
    echo "Expected ${file} to match: ${pattern}" >&2
    exit 1
  }
}

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  if grep -Eq "${pattern}" "${file}"; then
    echo "Expected ${file} not to match: ${pattern}" >&2
    exit 1
  fi
}

write_docker_stub() {
  local stub="$1"
  cat > "${stub}" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" != "load" ]]; then
  echo "unexpected docker command: $*" >&2
  exit 1
fi
cat > /dev/null
SH
  chmod +x "${stub}"
}

hostname_file="${tmp}/hostname"
env_file="${tmp}/deploy/.env"
integrations_file="${tmp}/integrations.env"
flag_file="${tmp}/state/.initialized"
image_tarball="${tmp}/landfall-server.tar.gz"
docker_stub="${tmp}/docker"

printf 'kitchen-frame\n' > "${hostname_file}"
printf 'fake image\n' > "${image_tarball}"
write_docker_stub "${docker_stub}"

cat > "${integrations_file}" <<'ENV'
GOOGLE_CLIENT_ID=google-client
GOOGLE_CLIENT_SECRET='google secret'
MICROSOFT_CLIENT_ID=microsoft-client
MICROSOFT_CLIENT_SECRET='microsoft secret'
OWM_API_KEY=weather-key
STRIPE_WEBHOOK_SECRET=stripe-key
ENV

LANDFALL_HOSTNAME_FILE="${hostname_file}" \
LANDFALL_ENV_FILE="${env_file}" \
LANDFALL_INTEGRATIONS_FILE="${integrations_file}" \
LANDFALL_INITIALIZED_FLAG="${flag_file}" \
LANDFALL_IMAGE_TARBALL="${image_tarball}" \
LANDFALL_DOCKER_BIN="${docker_stub}" \
LANDFALL_DATA_DIR="${tmp}/data/landfall" \
  bash "${FIRSTBOOT}"

[[ -f "${env_file}" ]] || { echo ".env was not created" >&2; exit 1; }
[[ -f "${flag_file}" ]] || { echo "initialized flag was not created" >&2; exit 1; }
[[ ! -f "${image_tarball}" ]] || { echo "image tarball was not removed after load" >&2; exit 1; }

for key in \
  DB_PASSWORD \
  REDIS_PASSWORD \
  SERVERPOD_SERVICE_SECRET \
  JWT_HMAC_KEY \
  JWT_REFRESH_PEPPER \
  API_KEY_MANAGEMENT_TOKEN \
  API_KEY_HMAC_SECRET \
  PHOTO_SIGNING_SECRET \
  OAUTH_TOKEN_ENCRYPTION_KEY \
  SMTP_PORT \
  SMTP_FROM_NAME \
  SMTP_SSL \
  SMTP_ALLOW_INSECURE \
  OTP_LOG_CODES; do
  assert_contains "${env_file}" "^${key}=.+"
done

assert_contains "${env_file}" '^LANDFALL_DOMAIN=kitchen-frame\.local$'
assert_contains "${env_file}" '^GOOGLE_REDIRECT_URI=https://kitchen-frame\.local/calendar/oauth/callback$'
assert_contains "${env_file}" '^MICROSOFT_REDIRECT_URI=https://kitchen-frame\.local/calendar/microsoft/oauth/callback$'

tmp2="$(mktemp -d)"
printf 'hallway\n' > "${tmp2}/hostname"
LANDFALL_HOSTNAME_FILE="${tmp2}/hostname" \
LANDFALL_ENV_FILE="${tmp2}/deploy/.env" \
LANDFALL_INTEGRATIONS_FILE="${tmp2}/missing-integrations.env" \
LANDFALL_INITIALIZED_FLAG="${tmp2}/state/.initialized" \
LANDFALL_IMAGE_TARBALL="${tmp2}/missing-server.tar.gz" \
LANDFALL_DOCKER_BIN="${docker_stub}" \
LANDFALL_DATA_DIR="${tmp2}/data/landfall" \
  bash "${FIRSTBOOT}"

assert_contains "${tmp2}/deploy/.env" '^LANDFALL_DOMAIN=hallway\.local$'
assert_contains "${tmp2}/deploy/.env" '^GOOGLE_REDIRECT_URI=$'
assert_contains "${tmp2}/deploy/.env" '^MICROSOFT_REDIRECT_URI=$'
assert_not_contains "${tmp2}/deploy/.env" '^GOOGLE_REDIRECT_URI=.+'
assert_not_contains "${tmp2}/deploy/.env" '^MICROSOFT_REDIRECT_URI=.+'
[[ -f "${tmp2}/state/.initialized" ]] || { echo "initialized flag missing without tarball" >&2; exit 1; }
rm -rf "${tmp2}"
