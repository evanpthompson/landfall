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

# Seed demo calendar events directly into the Postgres DB, bypassing OAuth.
# Inserts a fake LinkedCredential + 5 realistic upcoming events spanning
# Work, Personal, and Family calendars so the system.calendar widget renders.
# Uses docker compose exec so no host-side psql installation is required.
seed_demo_calendar_data() {
  (cd "${SERVER_DIR}" && docker compose exec -T postgres psql -U postgres landfall -q) <<'SQL'
DELETE FROM calendar_events
  WHERE "credentialId" IN (
    SELECT id FROM calendar_linked_credentials WHERE "providerEmail" = 'demo@landfall.local'
  );
DELETE FROM calendar_linked_credentials WHERE "providerEmail" = 'demo@landfall.local';

INSERT INTO calendar_linked_credentials
  ("authUserId", provider, "providerEmail", "accessToken", "isActive", "createdAt", "updatedAt")
VALUES
  ('00000000-0000-0000-0000-000000000001', 'google', 'demo@landfall.local',
   'demo-access-token', true, now(), now());

WITH cred AS (SELECT id FROM calendar_linked_credentials WHERE "providerEmail" = 'demo@landfall.local')
INSERT INTO calendar_events
  ("credentialId", "calendarId", "calendarName", "externalEventId",
   title, "startTime", "endTime", "isAllDay", "fetchedAt")
SELECT c.id, 'primary',      'Work',     'demo-standup',  'Team standup',
       NOW() + interval '1 hour',         NOW() + interval '1 hour 30 minutes',  false, NOW() FROM cred c
UNION ALL
SELECT c.id, 'primary',      'Work',     'demo-1on1',     '1:1 with Sarah',
       NOW() + interval '3 hours',        NOW() + interval '4 hours',            false, NOW() FROM cred c
UNION ALL
SELECT c.id, 'personal_cal', 'Personal', 'demo-dentist',  'Dentist appointment',
       NOW() + interval '25 hours',       NOW() + interval '26 hours',           false, NOW() FROM cred c
UNION ALL
SELECT c.id, 'family_cal',   'Family',   'demo-soccer',   'Kids soccer game',
       NOW() + interval '27 hours',       NOW() + interval '28 hours 30 minutes', false, NOW() FROM cred c
UNION ALL
SELECT c.id, 'primary',      'Work',     'demo-planning', 'Q3 planning session',
       NOW() + interval '50 hours',       NOW() + interval '52 hours',           false, NOW() FROM cred c;
SQL
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

# ── Google Calendar config check ──────────────────────────────────────────
step "Checking Google Calendar configuration"
GOOGLE_OAUTH_READY=false
if grep -q "googleOAuthRedirectUri" "${PASSWORDS_YAML}" 2>/dev/null && \
   ! grep -q "your-redirect-uri" "${PASSWORDS_YAML}" 2>/dev/null; then
  GOOGLE_OAUTH_READY=true
  ok "Google OAuth credentials configured — live calendar connect available"
  info "Connect URL (after server starts): ${SERVER_URL}/calendar/oauth/start?authUserId=<your-uuid>"
else
  warn "googleOAuthRedirectUri not configured in passwords.yaml."
  info "Demo will seed sample calendar events directly."
  info "To enable live Google Calendar: set googleOAuthRedirectUri in ${PASSWORDS_YAML}"
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

# ── Step 10: Calendar ─────────────────────────────────────────────────────
pause "Landfall also has a built-in calendar widget. It aggregates events from multiple feeds — work, personal, shared family calendars — into a single upcoming-events view."

step "Calendar widget (Session 10)"
echo ""
echo "  ${BOLD}Provider support:${RESET}"
echo "  ${DIM}• Google Calendar   — OAuth 2.0, all calendars visible to the account${RESET}"
echo "  ${DIM}• Microsoft Outlook — OAuth 2.0, Microsoft Graph API (add Azure credentials to enable)${RESET}"
echo "  ${DIM}• Apple iCloud      — CalDAV + app-specific password (coming soon)${RESET}"
echo ""
echo "  ${BOLD}Multi-feed design:${RESET}"
echo "  ${DIM}Each connected account is a LinkedCredential row. Events from all active${RESET}"
echo "  ${DIM}credentials merge into one view sorted by start time. You can link your${RESET}"
echo "  ${DIM}work Google account and personal Google account as two separate credentials.${RESET}"
echo "  ${DIM}Shared family calendars visible in any linked account appear automatically.${RESET}"
echo ""
echo "  ${BOLD}Refresh cadence:${RESET}  ${DIM}every 15 minutes, server-side${RESET}"
echo "  ${BOLD}Display slot:${RESET}     ${DIM}system.calendar — bottom-left of the default layout${RESET}"
echo ""

if [[ "${GOOGLE_OAUTH_READY}" == "true" ]]; then
  echo "  ${BOLD}Connect a Google Calendar account:${RESET}"
  echo "  ${CYAN}  ${SERVER_URL}/calendar/oauth/start?authUserId=00000000-0000-0000-0000-000000000001${RESET}"
  echo ""
fi

step "Seeding demo calendar events"
if seed_demo_calendar_data; then
  ok "5 demo events inserted across Work, Personal, and Family calendars"
  info "Today:    Team standup  •  1:1 with Sarah"
  info "Tomorrow: Dentist appointment  •  Kids soccer game"
  info "Day 3:    Q3 planning session"
  info ""
  info "The calendar widget will show these events on the display."
  info "In production, the server fetches live events every 15 minutes."
else
  warn "Could not connect to Postgres — calendar widget will show placeholder."
  info "Start Postgres first or check ${SERVER_LOG} for errors."
fi

# ── Step 11: Photo frame ──────────────────────────────────────────────────
pause "Session 11 added a photo frame slot and Microsoft Calendar. Let's walk through both."

step "Photo frame (system.photos)"
echo ""
echo "  ${BOLD}How it works:${RESET}"
echo "  ${DIM}• A 30-min server-side FutureCall syncs image metadata from a Google Drive folder${RESET}"
echo "  ${DIM}• The display fetches metadata via PhotoEndpoint.getPhotos()${RESET}"
echo "  ${DIM}• Image bytes are proxied on-demand through GET /photos/{id} — nothing stored on disk${RESET}"
echo "  ${DIM}• Photos rotate every 45 seconds with an animated crossfade${RESET}"
echo ""
echo "  ${BOLD}Display slot:${RESET}  ${DIM}system.photos — bottom-right of the default layout${RESET}"
echo "  ${BOLD}Refresh cadence:${RESET}  ${DIM}metadata every 30 min, bytes fetched live on each transition${RESET}"
echo ""
echo "  ${BOLD}To enable live photos:${RESET}"
echo "  ${DIM}1. Create a folder in Google Drive and share it with your connected Google account${RESET}"
echo "  ${DIM}2. Set googleDriveFolderId in ${PASSWORDS_YAML}${RESET}"
echo "  ${DIM}3. The 30-min refresh call picks it up automatically — no restart needed${RESET}"
echo ""
GDRIVE_FOLDER_ID=$(python3 -c "
import re, sys
text = open('${PASSWORDS_YAML}').read()
m = re.search(r'googleDriveFolderId\s*:\s*[\'\"](.*?)[\'\"]\s*\$', text, re.MULTILINE)
print(m.group(1) if m else '')
" 2>/dev/null || echo "")
if [[ -n "${GDRIVE_FOLDER_ID}" ]]; then
  ok "googleDriveFolderId configured — photo sync will run on startup"
else
  warn "googleDriveFolderId not set — photo slot will show 'No photos configured'"
fi

echo ""
echo "  ${BOLD}Microsoft Calendar:${RESET}"
echo "  ${DIM}MicrosoftCalendarService is fully implemented (Microsoft Graph API, OAuth 2.0).${RESET}"
echo "  ${DIM}Routes are live at /calendar/microsoft/oauth/start and /calendar/microsoft/oauth/callback.${RESET}"
echo "  ${DIM}Add microsoftClientId + microsoftClientSecret + microsoftOAuthRedirectUri to${RESET}"
echo "  ${DIM}passwords.yaml (from an Azure app registration) and the connect flow works immediately.${RESET}"
echo ""

# ── Step 12: Settings ─────────────────────────────────────────────────────
pause "Session 12 added a settings screen, ambient dim mode, and a drag-to-move layout editor."

step "Settings screen"
echo ""
echo "  ${BOLD}How to access:${RESET}"
echo "  ${DIM}Single-tap anywhere on the display — a gear icon (⚙) appears in the bottom-right${RESET}"
echo "  ${DIM}corner. Tap the icon to open Settings. It auto-hides after 5 seconds.${RESET}"
echo ""
echo "  ${BOLD}Display tab:${RESET}"
echo "  ${DIM}• Ambient dim — toggle on/off, set start hour and end hour (default: 10 pm → 7 am)${RESET}"
echo "  ${DIM}• Dim level slider — default 85% opacity (still viewable, noticeably dimmer)${RESET}"
echo "  ${DIM}• Location name — override the label shown on the weather card${RESET}"
echo "  ${DIM}All changes are saved immediately to local SQLite storage.${RESET}"
echo ""
echo "  ${BOLD}Accounts tab:${RESET}"
echo "  ${DIM}• Lists all connected credentials (Google Calendar, Microsoft Calendar)${RESET}"
echo "  ${DIM}• Shows copyable OAuth connect URLs — visit from any device on the same network${RESET}"
echo "  ${DIM}  (wall displays don't have browsers; copy the URL to your phone/laptop)${RESET}"
echo ""
echo "  ${BOLD}Layout tab:${RESET}"
echo "  ${DIM}• Drag cards to move them anywhere in the 12×8 grid${RESET}"
echo "  ${DIM}• Tap a card to toggle its visibility (hidden cards keep their slot)${RESET}"
echo "  ${DIM}• Changes persist immediately — layout survives app restarts${RESET}"
echo "  ${DIM}• Drag corner handle to resize cards (columnSpan / rowSpan)${RESET}"
echo ""

# ── Step 13: Deployment ───────────────────────────────────────────────────
pause "Session 13 adds the full self-hosting story — Docker Compose, a Raspberry Pi image, and a Fire TV APK. Let's walk through how it all fits together."

step "Self-hosting overview (Session 13)"
echo ""
echo "  ${BOLD}Server stack (any Linux machine):${RESET}"
echo "  ${DIM}• docker compose -f deploy/docker-compose.prod.yml up -d${RESET}"
echo "  ${DIM}• Runs: Serverpod server, Postgres, Redis, Caddy (auto SSL)${RESET}"
echo "  ${DIM}• Postgres backups automatically at 2 AM, 7 days retained${RESET}"
echo "  ${DIM}• First-time setup:  bash deploy/scripts/setup.sh${RESET}"
echo "  ${DIM}  Generates all secrets, asks for your domain or IP${RESET}"
echo ""
echo "  ${BOLD}Display options:${RESET}"
echo "  ${DIM}• Fire TV / Android:  bash tools/scripts/build_apk.sh${RESET}"
echo "  ${DIM}  APK sideloaded via adb — no app store needed${RESET}"
echo "  ${DIM}• Raspberry Pi:       bash tools/scripts/build_linux.sh${RESET}"
echo "  ${DIM}  Flutter Linux binary, runs fullscreen on HDMI output${RESET}"
echo ""
echo "  ${BOLD}Raspberry Pi image (all-in-one):${RESET}"
echo "  ${DIM}• pi-gen builds a bootable .img.xz — flash, boot, done${RESET}"
echo "  ${DIM}• Server stack + display app both start automatically on boot${RESET}"
echo "  ${DIM}• Build:  bash tools/scripts/build_linux.sh --arch arm64${RESET}"
echo "  ${DIM}          bash deploy/pi-gen/build.sh${RESET}"
echo "  ${DIM}• Flash with Raspberry Pi Imager, configure .env over SSH${RESET}"
echo ""
echo "  ${BOLD}Nothing leaves your network:${RESET}"
echo "  ${DIM}• OAuth tokens stored encrypted on your own Postgres instance${RESET}"
echo "  ${DIM}• API keys never transmitted to the display client${RESET}"
echo "  ${DIM}• No telemetry, no external service dependency${RESET}"
echo ""
info "Full guides: docs/self_hosting_guide.md  •  docs/raspberry_pi_guide.md"

# ── Step 14: First-run wizard ─────────────────────────────────────────────
pause "Session 14 adds the first-run setup wizard — the guided path from 'Docker is up' to 'display is showing my data' without touching a config file."

step "First-run setup wizard (Session 14)"
echo ""
echo "  ${BOLD}What it does:${RESET}"
echo "  ${DIM}• Shown automatically when no server URL is configured (fresh install)${RESET}"
echo "  ${DIM}• Walks through 4 steps: Server URL, Location, Accounts overview, Done${RESET}"
echo "  ${DIM}• Server URL step pings the configured URL before accepting it — immediate${RESET}"
echo "  ${DIM}  feedback if the address is wrong or the server isn't running${RESET}"
echo "  ${DIM}• Partial completion is persisted — resume at the right step after a restart${RESET}"
echo "  ${DIM}• After completion, Settings → Setup & Onboarding re-runs the wizard${RESET}"
echo ""
echo "  ${BOLD}When the display launches below, the wizard will appear.${RESET}"
echo "  ${BOLD}Enter the following to continue the demo:${RESET}"
echo ""
echo "  ${CYAN}  Server URL:   http://localhost:8080/${RESET}"
echo "  ${CYAN}  Location:     any city name  (or skip)${RESET}"
echo "  ${CYAN}  Accounts:     tap 'Got it'   (connect later from Settings)${RESET}"
echo "  ${CYAN}  Done:         tap 'Launch Landfall'${RESET}"
echo ""
info "Tip: if the app was previously configured, the wizard will not appear."
info "Delete the app's local database to see it fresh:"
info "  rm ~/Library/Containers/com.example.display/Data/Library/Application\\ Support/landfall.db"
echo ""

# ── Step 15: Ghost ticker & interactive card actions ──────────────────────────
pause "Session 15 adds the ghost ticker — ambient agent heartbeats at the bottom of the display — and interactive action buttons on cards."

step "Ghost ticker (Session 15)"
echo ""
echo "  ${BOLD}Ghost ticker:${RESET}"
echo "  ${DIM}• Agents push ticker messages via  POST /agent/pushTicker${RESET}"
echo "  ${DIM}  or the new MCP tool  push_ticker${RESET}"
echo "  ${DIM}• Appears as a 28px strip at the bottom of the display — scrolls${RESET}"
echo "  ${DIM}  horizontally, crossfades between messages, zero height when empty${RESET}"
echo "  ${DIM}• layout: 'ticker'  routes a card to the strip; default TTL 30 seconds${RESET}"
echo "  ${DIM}• persistent: true  is rejected for ticker cards by design${RESET}"
echo ""
echo "  ${BOLD}Try it (needs the server and an API key):${RESET}"
echo ""
echo "  ${DIM}# push a ticker heartbeat (replaces the direct curl below when a key is ready)${RESET}"
echo "  ${DIM}curl -X POST ${SERVER_URL}/agent/pushTicker \\${RESET}"
echo "  ${DIM}    -H 'Content-Type: application/json' \\${RESET}"
echo "  ${DIM}    -d '{\"apiKey\":\"<key>\",\"source\":\"agent.demo\",\"message\":\"Researching session 15 features…\"}'${RESET}"
echo ""
echo "  ${BOLD}Interactive card actions:${RESET}"
echo "  ${DIM}• Cards can now carry  actions: [{ id, label, type, payload, requireConfirm }]${RESET}"
echo "  ${DIM}• Types: dismiss | openUrl | webhook | openSettings${RESET}"
echo "  ${DIM}• requireConfirm: true  shows a confirmation dialog before executing${RESET}"
echo "  ${DIM}• GenericAgentCard renders action buttons in a Wrap below the body${RESET}"
echo "  ${DIM}• actionsJson column stores actions in the cards DB table${RESET}"
echo ""

# ── Step 16: Layout presets, resize, server-side persistence ──────────────────
pause "Session 16 adds Weekday / Weekend / Night layout presets, resize handles in the layout editor, and server-side layout sync."

step "Layout presets & editor improvements (Session 16)"
echo ""
echo "  ${BOLD}Preset layouts:${RESET}"
echo "  ${DIM}• Three built-in presets: Weekday, Weekend, Night${RESET}"
echo "  ${DIM}• Weekday  — clock, weather, forecast strip, calendar${RESET}"
echo "  ${DIM}• Weekend  — clock, weather, calendar, photos (family-focused)${RESET}"
echo "  ${DIM}• Night    — clock only, minimal display for nightstand mode${RESET}"
echo "  ${DIM}• Presets are customisable — changes persist per preset independently${RESET}"
echo "  ${DIM}• Settings → Layout tab shows the preset switcher (3 chips)${RESET}"
echo ""
echo "  ${BOLD}Layout editor improvements:${RESET}"
echo "  ${DIM}• Each card now has a bottom-right resize handle${RESET}"
echo "  ${DIM}• Drag the handle to change columnSpan / rowSpan — snaps to grid cells${RESET}"
echo "  ${DIM}• Ghost outline shows the new size before release${RESET}"
echo "  ${DIM}• Move and resize gestures are independent — no accidental triggers${RESET}"
echo ""
echo "  ${BOLD}Server-side layout persistence:${RESET}"
echo "  ${DIM}• Layouts are stored in  layout_configs  table on the Serverpod server${RESET}"
echo "  ${DIM}• LayoutEndpoint: getLayouts, saveLayout, setActiveLayout, deleteLayout${RESET}"
echo "  ${DIM}• All displays sharing a server instance stay in sync automatically${RESET}"
echo "  ${DIM}• Drift (local SQLite) is kept as an offline fallback${RESET}"
echo ""

# ── Step 17: Monetization — license system + pack marketplace ─────────────────
pause "Session 17 adds the one-time license system and integration pack marketplace."

step "Monetization: License System & Pack Marketplace (Session 17)"
echo ""
echo "  ${BOLD}License tiers:${RESET}"
echo "  ${DIM}• Free  — standard rate limits (500 API pushes/day), 7-day card history${RESET}"
echo "  ${DIM}• Pro   — unlimited API rate limits, 90-day history, multi-display sync${RESET}"
echo "  ${DIM}• Founding Member — Pro + all packs released in first 18 months${RESET}"
echo ""
echo "  ${BOLD}License key flow:${RESET}"
echo "  ${DIM}• User purchases via Stripe payment link (one-time, no subscription)${RESET}"
echo "  ${DIM}• Stripe webhook  POST /stripe/webhook  receives confirmation${RESET}"
echo "  ${DIM}• Server generates  LF-PRO-XXXX-XXXX  key and emails it to buyer${RESET}"
echo "  ${DIM}• User activates in app: Settings → License → Activate a Key${RESET}"
echo "  ${DIM}• License is tied to the Serverpod account — survives reinstalls${RESET}"
echo ""
echo "  ${BOLD}Server demo — check license status:${RESET}"
echo "  ${DIM}# LicenseEndpoint.getLicenseStatus() — returns free for new users${RESET}"
echo "  ${DIM}# LicenseEndpoint.activateLicense(key) — ties key to account, returns tier${RESET}"
echo ""
echo "  ${BOLD}Integration pack marketplace:${RESET}"
echo "  ${DIM}• 6 packs seeded in the database:${RESET}"
echo "  ${DIM}  — Sports Scores (\$5)     • Home Assistant (\$7)${RESET}"
echo "  ${DIM}  — Todoist / Tasks (\$5)   • RSS Headlines (\$5)${RESET}"
echo "  ${DIM}  — Countdown Timers (\$5)  • Stocks & Crypto (\$8)${RESET}"
echo "  ${DIM}• Stripe webhook grants packs to users on purchase${RESET}"
echo "  ${DIM}• PackEndpoint: listPacks (with isOwned flag), getOwnedPacks${RESET}"
echo "  ${DIM}• Settings → License → Browse Integration Packs opens pack browser${RESET}"
echo ""
echo "  ${BOLD}Check pack catalog via server:${RESET}"
echo ""

# ── Step 18: Theme Engine ────────────────────────────────────────────────────
pause "Phase 14 adds the theme engine — five built-in themes seeded on startup, a validator that checks every token at upload time, and a REST-style endpoint for applying themes per-profile."

step "Theme Engine (Phase 14)"
echo ""
echo "  ${BOLD}Built-in themes (seeded automatically on server start):${RESET}"
echo "  ${DIM}• Default Dark     — clean dark, the factory default for every new display${RESET}"
echo "  ${DIM}• Default Light    — bright environment variant${RESET}"
echo "  ${DIM}• Neon Arcade      — high-contrast neon on deep black, high energy${RESET}"
echo "  ${DIM}• Deep Blue        — calm navy palette with cyan accent${RESET}"
echo "  ${DIM}• Warm Editorial   — off-white print/magazine aesthetic${RESET}"
echo ""
echo "  ${BOLD}Theme token vocabulary (ThemeSchema v1.0):${RESET}"
echo "  ${DIM}• surface  — background type/value, card fill/border/radius/blur/shadow${RESET}"
echo "  ${DIM}• typography — font family, scale, heading/body weight, letter spacing${RESET}"
echo "  ${DIM}• color     — accent, text.primary/secondary/tertiary, success/warning/alert${RESET}"
echo "  ${DIM}• animation — transition, speed, cardEntry, tickerScroll${RESET}"
echo "  ${DIM}• moods     — urgent, muted, celebratory, success overrides per-card${RESET}"
echo ""
echo "  ${BOLD}Derived tokens (resolved at upload time, never stored raw):${RESET}"
echo "  ${DIM}• color.accentMuted   — accent at 15% opacity (auto-derived from accent)${RESET}"
echo "  ${DIM}• color.divider       — text.primary at 10% opacity${RESET}"
echo "  ${DIM}• color.agent.border  — accent at 30% opacity${RESET}"
echo ""

step "Listing built-in themes from the running server"
THEME_RESPONSE=$(curl -sf \
  -X POST "${SERVER_URL}/theme/listThemes" \
  -H "Content-Type: application/json" \
  -d '{}' 2>/dev/null || echo "[]")

THEME_COUNT=$(echo "${THEME_RESPONSE}" | python3 -c \
  "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "?")

echo "${THEME_RESPONSE}" | python3 -c "
import sys, json
themes = json.load(sys.stdin)
for t in themes:
    marker = '★' if t.get('isBuiltIn') else '○'
    print(f'   {marker} [{t[\"slug\"]}]  {t[\"name\"]}')
" 2>/dev/null || true

ok "${THEME_COUNT} theme(s) available"

pause "Themes are validated at upload time — every token is type-checked, enum values are enforced, numeric ranges are bounded. Here's a live custom theme upload."

step "Uploading a custom theme"
CUSTOM_THEME_YAML='version: "1.0"
meta:
  name: "Demo Custom"
  author: "demo"
  description: "A minimal demo theme uploaded live."
  tags: [demo, minimal]
color:
  accent: "#FF6B6B"
  text:
    primary: "#FFFFFF"
surface:
  background:
    type: solid
    value: "#1A1A2E"
  card:
    fill: "rgba(255,255,255,0.05)"
    border:
      color: "rgba(255,107,107,0.3)"
      width: 1.0
      style: solid
    radius: 6
animation:
  transition: fade
  speed: normal
  cardEntry: fade
  tickerScroll: normal'

UPLOAD_RESPONSE=$(curl -sf \
  -X POST "${SERVER_URL}/theme/uploadTheme" \
  -H "Content-Type: application/json" \
  -d "{\"yaml\":$(echo "${CUSTOM_THEME_YAML}" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')}" \
  2>/dev/null || echo '{"errors":[{"message":"server not ready"}]}')

UPLOAD_OK=$(echo "${UPLOAD_RESPONSE}" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print('yes' if d.get('theme') else 'no')" 2>/dev/null || echo "no")

if [[ "${UPLOAD_OK}" == "yes" ]]; then
  UPLOADED_SLUG=$(echo "${UPLOAD_RESPONSE}" | python3 -c \
    "import sys,json; print(json.load(sys.stdin)['theme']['slug'])" 2>/dev/null || echo "unknown")
  ok "Custom theme uploaded — slug: ${UPLOADED_SLUG}"
  info "Resolved tokens (accentMuted, divider, agent.border) were derived automatically."
else
  warn "Upload skipped — server may not be running or endpoint needs auth."
fi

echo ""
echo "  ${BOLD}ThemeEndpoint — full surface area:${RESET}"
echo "  ${DIM}• listThemes()               — all available themes, ordered by name${RESET}"
echo "  ${DIM}• uploadTheme(yaml)          — validate + store; returns errors on failure${RESET}"
echo "  ${DIM}• importTheme(url)           — HTTPS fetch + validate + store (10 s timeout)${RESET}"
echo "  ${DIM}• previewTheme(id)           — returns the resolved token JSON string${RESET}"
echo "  ${DIM}• applyTheme(themeId,        — links theme to a named profile${RESET}"
echo "  ${DIM}             profileId)${RESET}"
echo "  ${DIM}• deleteTheme(id)            — removes imported themes; built-ins are protected${RESET}"
echo ""

# ── Step 19: Display ────────────────────────────────────────────────────────
pause "Ready to launch. The wizard will appear on a fresh install — walk through it, then the full display loads with all the demo cards we pushed."

step "Launching Landfall display (macOS)"  # Step 19
info "The app will open in a new window. Press Cmd+Q to quit when done."
echo ""

(cd "${DISPLAY_DIR}" && flutter run -d macos lib/main.dart)

# flutter run is blocking — script resumes (and cleanup fires) when the app quits
