#!/usr/bin/env bash
# First-time Landfall deployment setup.
# Generates all required secrets and writes them to deploy/.env.
#
# Usage:  bash deploy/scripts/setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${DEPLOY_DIR}/.env"
ENV_EXAMPLE="${DEPLOY_DIR}/.env.example"

BOLD=$'\033[1m'
GREEN=$'\033[1;32m'
CYAN=$'\033[1;36m'
YELLOW=$'\033[1;33m'
RESET=$'\033[0m'

ok()   { echo "${GREEN}✓  $*${RESET}"; }
info() { echo "   $*"; }
ask()  { printf "${BOLD}%s${RESET} " "$*"; }

gen_secret() { openssl rand -base64 32 | tr -d '\n/+=' | cut -c1-43; }

echo ""
echo "${CYAN}${BOLD}Landfall — first-time setup${RESET}"
echo ""

if [[ -f "${ENV_FILE}" ]]; then
  echo "${YELLOW}⚠  ${ENV_FILE} already exists.${RESET}"
  ask "Overwrite it? [y/N]"
  read -r OVERWRITE
  [[ "${OVERWRITE}" =~ ^[Yy]$ ]] || { info "Aborted."; exit 0; }
fi

cp "${ENV_EXAMPLE}" "${ENV_FILE}"

# ── Domain ──────────────────────────────────────────────────────────────────
echo ""
info "Enter your server's hostname or IP address."
info "  • Local network:  landfall.local  or  192.168.1.x"
info "  • Public domain:  api.example.com  (Caddy will auto-fetch SSL)"
echo ""
ask "Domain / IP [landfall.local]:"
read -r DOMAIN
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

sed -i.bak "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|"                         "${ENV_FILE}"
sed -i.bak "s|^REDIS_PASSWORD=.*|REDIS_PASSWORD=${REDIS_PASS}|"                 "${ENV_FILE}"
sed -i.bak "s|^SERVERPOD_SERVICE_SECRET=.*|SERVERPOD_SERVICE_SECRET=${SERVICE_SECRET}|" "${ENV_FILE}"
sed -i.bak "s|^JWT_HMAC_KEY=.*|JWT_HMAC_KEY=${JWT_HMAC}|"                       "${ENV_FILE}"
sed -i.bak "s|^JWT_REFRESH_PEPPER=.*|JWT_REFRESH_PEPPER=${JWT_PEPPER}|"         "${ENV_FILE}"
rm -f "${ENV_FILE}.bak"

ok "DB password, Redis password, and Serverpod JWT secrets generated"

# ── Optional integrations ────────────────────────────────────────────────────
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

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "${GREEN}${BOLD}Setup complete.${RESET}"
echo ""
info "Your .env file is ready at: ${ENV_FILE}"
info ""
info "To add Google Calendar, Microsoft Calendar, or Google Drive photos,"
info "fill in the remaining keys in ${ENV_FILE} — see the comments for instructions."
info ""
info "To start Landfall:"
info "  cd deploy && docker compose -f docker-compose.prod.yml up -d"
echo ""
