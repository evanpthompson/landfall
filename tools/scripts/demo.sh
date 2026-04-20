#!/usr/bin/env bash
# Landfall interactive demo launcher.
# Starts the full stack, generates an API key, pushes demo cards, and
# launches the display.
#
# Usage:  ./tools/scripts/demo.sh

set -euo pipefail

# ── Colours ────────────────────────────────────────────────────────────────
BOLD=$'\033[1m'
DIM=$'\033[2m'
CYAN=$'\033[1;36m'
GREEN=$'\033[1;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[1;31m'
RESET=$'\033[0m'

# ── Paths ──────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SERVER_DIR="${REPO_ROOT}/server/landfall_server"
DISPLAY_DIR="${REPO_ROOT}/apps/display"
PASSWORDS_YAML="${SERVER_DIR}/config/passwords.yaml"
SERVER_URL="http://localhost:8080"
SERVER_LOG="${REPO_ROOT}/tools/scripts/.server.log"

# ── PIDs tracked for cleanup ───────────────────────────────────────────────
SERVER_PID=""

# ── Helpers ────────────────────────────────────────────────────────────────
step()    { echo ""; echo "${CYAN}▶  $*${RESET}"; }
ok()      { echo "${GREEN}✓  $*${RESET}"; }
info()    { echo "${DIM}   $*${RESET}"; }
warn()    { echo "${YELLOW}⚠  $*${RESET}"; }
die()     { echo "${RED}✗  $*${RESET}"; exit 1; }

pause() {
  echo ""
  echo "${BOLD}$*${RESET}"
  read -r -p "   Press Enter to continue... "
}

cleanup() {
  echo ""
  step "Shutting down..."
  if [[ -n "${SERVER_PID}" ]] && kill -0 "${SERVER_PID}" 2>/dev/null; then
    kill "${SERVER_PID}" 2>/dev/null || true
    ok "Server stopped"
  fi
  (cd "${SERVER_DIR}" && docker compose down --remove-orphans -q 2>/dev/null) || true
  ok "Docker services stopped"
  rm -f "${SERVER_LOG}"
  echo ""
  echo "${CYAN}${BOLD}Demo complete. Thanks for watching!${RESET}"
  echo ""
}
trap cleanup EXIT INT TERM

# Push a card via the unauthenticated card endpoint (Phase 0 / open API).
push_card() {
  local source="$1"
  local title="$2"
  local body="${3:-}"
  local layout="${4:-medium}"
  local priority="${5:-normal}"

  local inner
  inner=$(printf '{"__className__":"CardPushRequest","source":"%s","title":"%s","layout":"%s","priority":"%s"' \
    "${source}" "${title}" "${layout}" "${priority}")
  if [[ -n "${body}" ]]; then
    inner+=,"\"body\":\"${body}\""
  fi
  inner+="}"

  curl -sf \
    -X POST "${SERVER_URL}/card/pushCard" \
    -H "Content-Type: application/json" \
    -d "{\"request\":${inner}}" \
    > /dev/null
}

# Push a card via the authenticated agent endpoint (requires API key).
push_card_agent() {
  local api_key="$1"
  local source="$2"
  local title="$3"
  local body="${4:-}"
  local layout="${5:-medium}"
  local priority="${6:-normal}"

  local request
  request=$(printf '{"__className__":"CardPushRequest","source":"%s","title":"%s","layout":"%s","priority":"%s"' \
    "${source}" "${title}" "${layout}" "${priority}")
  if [[ -n "${body}" ]]; then
    request+=,"\"body\":\"${body}\""
  fi
  request+="}"

  curl -sf \
    -X POST "${SERVER_URL}/agent/pushCard" \
    -H "Content-Type: application/json" \
    -d "{\"apiKey\":\"${api_key}\",\"request\":${request}}" \
    > /dev/null
}

wait_for_server() {
  local attempts=0
  while [[ ${attempts} -lt 30 ]]; do
    if curl -sf "${SERVER_URL}/card/getCards" -H "Content-Type: application/json" \
       -d '{"method":"getCards"}' > /dev/null 2>&1; then
      return 0
    fi
    # Also accept a non-5xx response — getCards with wrong body still means server is up
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" "${SERVER_URL}" 2>/dev/null || echo "000")
    if [[ "${status}" != "000" ]]; then
      return 0
    fi
    sleep 1
    (( attempts++ )) || true
  done
  return 1
}

# ── Preflight ──────────────────────────────────────────────────────────────
clear
echo ""
echo "${CYAN}${BOLD}"
echo "  ██╗      █████╗ ███╗   ██╗██████╗ ███████╗ █████╗ ██╗     ██╗"
echo "  ██║     ██╔══██╗████╗  ██║██╔══██╗██╔════╝██╔══██╗██║     ██║"
echo "  ██║     ███████║██╔██╗ ██║██║  ██║█████╗  ███████║██║     ██║"
echo "  ██║     ██╔══██║██║╚██╗██║██║  ██║██╔══╝  ██╔══██║██║     ██║"
echo "  ███████╗██║  ██║██║ ╚████║██████╔╝██║     ██║  ██║███████╗███████╗"
echo "  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝"
echo "${RESET}"
echo "  ${DIM}The ambient display layer for the agentic era${RESET}"
echo ""

pause "Welcome to the Landfall demo. We'll start the server, generate an API key, push some live cards, and launch the display."

# Check prerequisites
step "Checking prerequisites"
command -v docker   > /dev/null || die "Docker is not installed or not in PATH"
command -v dart     > /dev/null || die "Dart SDK is not installed or not in PATH"
command -v flutter  > /dev/null || die "Flutter SDK is not installed or not in PATH"
command -v curl     > /dev/null || die "curl is not installed"
command -v python3  > /dev/null || die "python3 is not installed"
ok "All prerequisites found"

# ── Weather config check ───────────────────────────────────────────────────
step "Checking weather configuration"
if grep -q "your-owm-api-key-here" "${PASSWORDS_YAML}" 2>/dev/null; then
  warn "OpenWeatherMap API key is not configured."
  info "The weather slot will show a placeholder tile during the demo."
  info "To enable live weather: edit ${PASSWORDS_YAML}"
  info "and set openWeatherMapApiKey to your key from openweathermap.org/api"
else
  ok "OpenWeatherMap API key is configured — weather widget will be live"
fi

# ── Step 1: Docker ─────────────────────────────────────────────────────────
step "Starting Postgres and Redis (Docker)"
(cd "${SERVER_DIR}" && docker compose up -d --quiet-pull 2>&1) || die "docker compose up failed"
ok "Postgres listening on :8090  •  Redis on :8091"

# Give Postgres a moment to be ready for connections
sleep 2

# ── Step 2: Server ─────────────────────────────────────────────────────────
step "Starting Landfall server"
info "Logs → ${SERVER_LOG}"
(
  cd "${SERVER_DIR}"
  dart bin/main.dart --apply-migrations > "${SERVER_LOG}" 2>&1
) &
SERVER_PID=$!

info "Waiting for server to accept connections..."
if wait_for_server; then
  ok "Server is up at ${SERVER_URL}"
else
  warn "Server did not respond in 30 s. Check ${SERVER_LOG} for errors."
  die "Aborting demo"
fi

# ── Step 3: API key ────────────────────────────────────────────────────────
pause "Server is running and migrations are applied. Now let's generate an API key — this is how any agent or automation authenticates with Landfall."

step "Generating demo API key"
KEY_RESPONSE=$(curl -sf \
  -X POST "${SERVER_URL}/apiKey/generateKey" \
  -H "Content-Type: application/json" \
  -d '{"name":"demo"}')

DEMO_API_KEY=$(echo "${KEY_RESPONSE}" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d['plainTextKey'])" 2>/dev/null) \
  || die "Failed to parse API key response. Check ${SERVER_LOG}"

ok "API key generated: ${BOLD}${DEMO_API_KEY}${RESET}"
info "In production, agents store this key securely and include it in every push."
info "Keys can be revoked at any time via /apiKey/revokeKey."

# ── Step 4: Demo cards ─────────────────────────────────────────────────────
pause "Key in hand. Now let's push some cards — these simulate live output from AI agents."

step "Pushing demo cards via authenticated agent API"

push_card_agent \
  "${DEMO_API_KEY}" \
  "agent.claude" \
  "3 items before your 2 PM" \
  "Reply to Sarah re: Q3 plan, review budget doc, confirm dinner reservation." \
  "medium" "normal"
ok "Card 1 — Claude pre-meeting briefing (agent API)"

push_card_agent \
  "${DEMO_API_KEY}" \
  "agent.home" \
  "Front door unlocked for 9 min" \
  "No motion detected inside. Lock remotely?" \
  "medium" "ephemeral"
ok "Card 2 — Home automation alert, urgent priority (agent API)"

push_card_agent \
  "${DEMO_API_KEY}" \
  "agent.flights" \
  "Flight DEN→LAX dropped to \$287" \
  "Round trip, departing June 14. Sale ends tonight." \
  "medium" "normal"
ok "Card 3 — Price alert (agent API)"

push_card \
  "agent.research" \
  "New paper: LLM reasoning benchmarks" \
  "Three Stanford papers dropped overnight matching your saved topics." \
  "medium" "normal"
ok "Card 4 — Research digest (open endpoint)"

info "Cards arrive on the display within seconds of the 30-second refresh cycle."

# ── Step 5: MCP info ───────────────────────────────────────────────────────
pause "Cards are queued. One more thing — Landfall ships with an MCP server so AI agents with tool-use support (Claude Desktop, Cursor) can push cards directly."

step "MCP server (landfall_mcp)"
echo ""
echo "  ${BOLD}Build the binary:${RESET}"
echo "  ${DIM}dart compile exe server/landfall_mcp/bin/landfall_mcp.dart -o /usr/local/bin/landfall_mcp${RESET}"
echo ""
echo "  ${BOLD}Add to Claude Desktop${RESET} (~/.config/claude/claude_desktop_config.json):"
echo "  ${DIM}{${RESET}"
echo "  ${DIM}  \"mcpServers\": {${RESET}"
echo "  ${DIM}    \"landfall\": {${RESET}"
echo "  ${DIM}      \"command\": \"/usr/local/bin/landfall_mcp\",${RESET}"
echo "  ${DIM}      \"env\": {${RESET}"
echo "  ${DIM}        \"LANDFALL_URL\": \"${SERVER_URL}\",${RESET}"
echo "  ${DIM}        \"LANDFALL_API_KEY\": \"${DEMO_API_KEY}\"${RESET}"
echo "  ${DIM}      }${RESET}"
echo "  ${DIM}    }${RESET}"
echo "  ${DIM}  }${RESET}"
echo "  ${DIM}}${RESET}"
echo ""
info "Once connected, Claude can call push_card, list_cards, and dismiss_card as native tools."

# ── Step 6: Display ────────────────────────────────────────────────────────
pause "Let's launch the display. The clock and weather widget will load automatically. Agent cards appear in the right-side feed."

step "Launching Landfall display (macOS)"
info "The app will open in a new window. Press Cmd+Q to quit when done."
echo ""

(cd "${DISPLAY_DIR}" && flutter run -d macos lib/main.dart)

# flutter run is blocking — script resumes (and cleanup fires) when the app quits
