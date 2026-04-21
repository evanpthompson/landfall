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
# Optional 7th argument: externalId for stable in-place updates.
push_card_agent() {
  local api_key="$1"
  local source="$2"
  local title="$3"
  local body="${4:-}"
  local layout="${5:-medium}"
  local priority="${6:-normal}"
  local external_id="${7:-}"

  local request
  request=$(printf '{"__className__":"CardPushRequest","source":"%s","title":"%s","layout":"%s","priority":"%s"' \
    "${source}" "${title}" "${layout}" "${priority}")
  if [[ -n "${body}" ]]; then
    request+=,"\"body\":\"${body}\""
  fi
  if [[ -n "${external_id}" ]]; then
    request+=,"\"externalId\":\"${external_id}\""
  fi
  request+="}"

  curl -sf \
    -X POST "${SERVER_URL}/agent/pushCard" \
    -H "Content-Type: application/json" \
    -d "{\"apiKey\":\"${api_key}\",\"request\":${request}}" \
    > /dev/null
}

# Update an existing card in-place by externalId.
update_card_agent() {
  local api_key="$1"
  local external_id="$2"
  local source="$3"
  local title="$4"
  local body="${5:-}"

  local request
  request=$(printf '{"__className__":"CardPushRequest","source":"%s","title":"%s"' \
    "${source}" "${title}")
  if [[ -n "${body}" ]]; then
    request+=,"\"body\":\"${body}\""
  fi
  request+="}"

  curl -sf \
    -X POST "${SERVER_URL}/agent/updateCard" \
    -H "Content-Type: application/json" \
    -d "{\"apiKey\":\"${api_key}\",\"externalId\":\"${external_id}\",\"request\":${request}}" \
    > /dev/null
}

# Dismiss a card by externalId.
dismiss_card_agent() {
  local api_key="$1"
  local external_id="$2"

  curl -sf \
    -X POST "${SERVER_URL}/agent/dismissCard" \
    -H "Content-Type: application/json" \
    -d "{\"apiKey\":\"${api_key}\",\"externalId\":\"${external_id}\"}" \
    > /dev/null
}

wait_for_server() {
  local attempts=0
  # Poll getCards until it returns 200 — proves the API server is up and the
  # DB connection pool is ready. The fallback that accepted any non-000 status
  # was removed because the web server can respond before the API is ready.
  while [[ ${attempts} -lt 40 ]]; do
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" \
      -X POST "${SERVER_URL}/card/getCards" \
      -H "Content-Type: application/json" \
      -d '{}' 2>/dev/null || echo "000")
    if [[ "${status}" == "200" ]]; then
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
WEATHER_LIVE=false
if grep -q "your-owm-api-key-here" "${PASSWORDS_YAML}" 2>/dev/null; then
  warn "OpenWeatherMap API key is not configured."
  info "The weather slot will show a placeholder tile during the demo."
  info "To enable live weather: edit ${PASSWORDS_YAML}"
  info "and set openWeatherMapApiKey to your key from openweathermap.org/api"
else
  WEATHER_LIVE=true
  ok "OpenWeatherMap API key is configured — weather widget will be live"
fi

# ── Step 0: Clear stale server ────────────────────────────────────────────
step "Checking for stale server on :8080"
STALE_PID=$(lsof -ti :8080 2>/dev/null || true)
if [[ -n "${STALE_PID}" ]]; then
  kill "${STALE_PID}" 2>/dev/null || true
  sleep 1
  ok "Stopped stale server (PID ${STALE_PID})"
else
  ok "Port 8080 is free"
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
KEY_RESPONSE=$(curl -s \
  -X POST "${SERVER_URL}/apiKey/generateKey" \
  -H "Content-Type: application/json" \
  -d '{"name":"demo"}') \
  || die "Could not reach server at ${SERVER_URL}. Check ${SERVER_LOG}"

DEMO_API_KEY=$(echo "${KEY_RESPONSE}" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d['plainTextKey'])" 2>/dev/null) \
  || die "Failed to parse API key response: ${KEY_RESPONSE}"

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
ok "Card 2 — Home automation alert (agent API)"

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

# ── Step 5: Live card update ───────────────────────────────────────────────
pause "Each card so far is fire-and-forget. But Landfall also supports stable card slots — an agent can own a named ID and update the card in-place over time, no duplicates."

step "Demonstrating live card update (stable externalId)"
BUILD_CARD_ID="demo.build.status"

push_card_agent \
  "${DEMO_API_KEY}" \
  "agent.ci" \
  "Build running…" \
  "CI pipeline started for main branch. 0/237 tests passing." \
  "medium" "normal" \
  "${BUILD_CARD_ID}"
ok "Card pushed: 'Build running…'  (externalId: ${BUILD_CARD_ID})"

info "Simulating CI job completion..."
sleep 2

update_card_agent \
  "${DEMO_API_KEY}" \
  "${BUILD_CARD_ID}" \
  "agent.ci" \
  "Build passed ✓" \
  "All 237 tests passed in 42 s. Ready to merge."
ok "Card updated in-place: 'Build passed ✓'"
info "Same slot, new content — the display shows exactly one build-status card at all times."

# ── Step 6: Programmatic dismissal ────────────────────────────────────────
pause "Agents can also dismiss cards programmatically — useful for ephemeral alerts that resolve themselves."

step "Demonstrating programmatic card dismissal"
DISK_ALERT_ID="demo.alert.disk"

push_card_agent \
  "${DEMO_API_KEY}" \
  "agent.monitor" \
  "Disk at 89%" \
  "macOS partition getting full. Clean up Downloads?" \
  "medium" "ephemeral" \
  "${DISK_ALERT_ID}"
ok "Alert card pushed  (externalId: ${DISK_ALERT_ID})"

info "Agent detects the situation is resolved..."
sleep 1

dismiss_card_agent "${DEMO_API_KEY}" "${DISK_ALERT_ID}"
ok "Card dismissed — will disappear from display on the next poll"

# ── Step 7: List active board ──────────────────────────────────────────────
step "Listing the current active board via the agent API"
LIST_RESPONSE=$(curl -sf \
  -X POST "${SERVER_URL}/agent/listCards" \
  -H "Content-Type: application/json" \
  -d "{\"apiKey\":\"${DEMO_API_KEY}\"}")

CARD_COUNT=$(echo "${LIST_RESPONSE}" | python3 -c \
  "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "?")

echo "${LIST_RESPONSE}" | python3 -c "
import sys, json
cards = json.load(sys.stdin)
for c in cards:
    print(f'   • [{c[\"source\"]}]  {c[\"title\"]}')
" 2>/dev/null || true

ok "${CARD_COUNT} active card(s) on the display"
info "Dismissed cards are retained in the database for history but excluded from this list."

# ── Step 8: MCP info ───────────────────────────────────────────────────────
pause "All of the above — push, update, dismiss, list — is also available as MCP tools so AI agents with tool-use support (Claude Desktop, Cursor) can drive the display directly."

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
info "Once connected, Claude can call push_card, update_card, list_cards, and dismiss_card as native tools."

# ── Step 9: Weather ────────────────────────────────────────────────────────
pause "Finally, Landfall includes a built-in weather widget — no agent required."

step "Weather widget"
echo ""
echo "  ${BOLD}Two automatic cards:${RESET}"
echo "  ${DIM}• Current conditions  — temperature, description, feels-like, humidity${RESET}"
echo "  ${DIM}• 5-day forecast strip — high/low and icon for each day${RESET}"
echo ""
echo "  ${BOLD}Refresh cadence:${RESET}  ${DIM}every 10 minutes, driven by the server${RESET}"
echo "  ${BOLD}Data source:${RESET}      ${DIM}OpenWeatherMap (free tier, 60 calls/min)${RESET}"
echo ""
if [[ "${WEATHER_LIVE}" == "true" ]]; then
  ok "Live weather will appear in the display automatically."
else
  warn "OWM key not set — weather cards will show a placeholder."
  info "Set openWeatherMapApiKey in ${PASSWORDS_YAML} to enable live data."
fi

# ── Step 10: Display ────────────────────────────────────────────────────────
pause "Let's launch the display. The clock and weather widget load automatically. Agent cards appear in the right-side feed."

step "Launching Landfall display (macOS)"
info "The app will open in a new window. Press Cmd+Q to quit when done."
echo ""

(cd "${DISPLAY_DIR}" && flutter run -d macos lib/main.dart)

# flutter run is blocking — script resumes (and cleanup fires) when the app quits
