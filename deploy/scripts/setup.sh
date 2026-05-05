#!/usr/bin/env bash
# First-time Landfall deployment setup.
# Generates all required secrets and writes them to deploy/.env.
#
# Usage:  bash deploy/scripts/setup.sh
# Tests:  bash deploy/scripts/test_setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# DEPLOY_DIR_OVERRIDE lets tests redirect output to a temp directory.
DEPLOY_DIR="${DEPLOY_DIR_OVERRIDE:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
ENV_FILE="${DEPLOY_DIR}/.env"
ENV_EXAMPLE="${DEPLOY_DIR}/.env.example"

NON_INTERACTIVE=0
for arg in "$@"; do
  [[ "${arg}" == "--non-interactive" ]] && NON_INTERACTIVE=1
done

BOLD=$'\033[1m'
GREEN=$'\033[1;32m'
CYAN=$'\033[1;36m'
YELLOW=$'\033[1;33m'
RESET=$'\033[0m'

ok()   { echo "${GREEN}✓  $*${RESET}"; }
info() { echo "   $*"; }
ask()  { printf "${BOLD}%s${RESET} " "$*"; }

gen_secret()     { openssl rand -base64 32 | tr -d '\n/+=' | cut -c1-43; }
gen_hex_secret() { openssl rand -hex 32; }

echo ""
echo "${CYAN}${BOLD}Landfall — first-time setup${RESET}"
echo ""

if [[ -f "${ENV_FILE}" && "${NON_INTERACTIVE}" -eq 0 ]]; then
  echo "${YELLOW}⚠  ${ENV_FILE} already exists.${RESET}"
  ask "Overwrite it? [y/N]"
  read -r OVERWRITE
  [[ "${OVERWRITE}" =~ ^[Yy]$ ]] || { info "Aborted."; exit 0; }
fi

cp "${ENV_EXAMPLE}" "${ENV_FILE}"

# ── Domain ──────────────────────────────────────────────────────────────────
if [[ "${NON_INTERACTIVE}" -eq 0 ]]; then
  echo ""
  info "Enter your server's hostname or IP address."
  info "  • Local network:  landfall.local  or  192.168.1.x"
  info "  • Public domain:  api.example.com  (Caddy will auto-fetch SSL)"
  echo ""
  ask "Domain / IP [landfall.local]:"
  read -r DOMAIN
fi
DOMAIN="${DOMAIN:-landfall.local}"
sed -i.bak "s|^LANDFALL_DOMAIN=.*|LANDFALL_DOMAIN=${DOMAIN}|" "${ENV_FILE}"
ok "Domain set to: ${DOMAIN}"

# ── Auto-generate secrets ────────────────────────────────────────────────────
echo ""
info "Generating secrets..."

DB_PASS="$(gen_secret)"
REDIS_PASS="$(gen_secret)"
SERVICE_SECRET="$(gen_secret)"
JWT_HMAC="$(gen_secret)"
JWT_PEPPER="$(gen_secret)"
API_MGMT_TOKEN="$(gen_secret)"
API_HMAC_SECRET="$(gen_secret)"
PHOTO_SECRET="$(gen_secret)"
OAUTH_ENC_KEY="$(gen_hex_secret)"

sed -i.bak "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|"                                   "${ENV_FILE}"
sed -i.bak "s|^REDIS_PASSWORD=.*|REDIS_PASSWORD=${REDIS_PASS}|"                           "${ENV_FILE}"
sed -i.bak "s|^SERVERPOD_SERVICE_SECRET=.*|SERVERPOD_SERVICE_SECRET=${SERVICE_SECRET}|"   "${ENV_FILE}"
sed -i.bak "s|^JWT_HMAC_KEY=.*|JWT_HMAC_KEY=${JWT_HMAC}|"                                 "${ENV_FILE}"
sed -i.bak "s|^JWT_REFRESH_PEPPER=.*|JWT_REFRESH_PEPPER=${JWT_PEPPER}|"                   "${ENV_FILE}"
sed -i.bak "s|^API_KEY_MANAGEMENT_TOKEN=.*|API_KEY_MANAGEMENT_TOKEN=${API_MGMT_TOKEN}|"   "${ENV_FILE}"
sed -i.bak "s|^API_KEY_HMAC_SECRET=.*|API_KEY_HMAC_SECRET=${API_HMAC_SECRET}|"            "${ENV_FILE}"
sed -i.bak "s|^PHOTO_SIGNING_SECRET=.*|PHOTO_SIGNING_SECRET=${PHOTO_SECRET}|"             "${ENV_FILE}"
sed -i.bak "s|^OAUTH_TOKEN_ENCRYPTION_KEY=.*|OAUTH_TOKEN_ENCRYPTION_KEY=${OAUTH_ENC_KEY}|" "${ENV_FILE}"
rm -f "${ENV_FILE}.bak"

ok "All secrets generated"

# ── Optional integrations ────────────────────────────────────────────────────
if [[ "${NON_INTERACTIVE}" -eq 0 ]]; then
  echo ""
  info "Optional: enter your OpenWeatherMap API key (leave blank to skip)."
  info "  Free tier at openweathermap.org/api"
  ask "OWM API key:"
  read -r OWM_KEY
  if [[ -n "${OWM_KEY}" ]]; then
    sed -i.bak "s|^OWM_API_KEY=.*|OWM_API_KEY=${OWM_KEY}|" "${ENV_FILE}"
    rm -f "${ENV_FILE}.bak"
    ok "Weather enabled"
  else
    info "Skipped — weather cards will show a placeholder."
  fi
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "${GREEN}${BOLD}Setup complete.${RESET}"
echo ""
info "Your .env file is ready at: ${ENV_FILE}"
info ""
info "STRIPE_WEBHOOK_SECRET must be set manually — find it under"
info "  Developers > Webhooks in your Stripe dashboard."
info ""
info "To add Google Calendar, Microsoft Calendar, or Google Drive photos,"
info "fill in the remaining keys in ${ENV_FILE} — see the comments for instructions."
info ""
info "To start Landfall:"
info "  cd deploy && docker compose -f docker-compose.prod.yml up -d"
echo ""
