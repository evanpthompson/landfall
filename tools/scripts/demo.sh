#!/usr/bin/env bash
# Landfall interactive demo launcher.
# Starts the full stack, pushes demo cards, and launches the display.
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

push_card() {
  local source="$1"
  local title="$2"
  local body="${3:-}"
  local layout="${4:-medium}"
  local priority="${5:-normal}"

  local payload
  payload=$(printf '{"__className__":"CardPushRequest","source":"%s","title":"%s","layout":"%s","priority":"%s"' \
    "${source}" "${title}" "${layout}" "${priority}")
  if [[ -n "${body}" ]]; then
    payload+=,"\"body\":\"${body}\""
  fi
  payload+="}"

  curl -sf \
    -X POST "${SERVER_URL}/card/pushCard" \
    -H "Content-Type: application/json" \
    -d "${payload}" \
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

pause "Welcome to the Landfall demo. We'll start the server, launch the display, and push some live cards."

# Check prerequisites
step "Checking prerequisites"
command -v docker   > /dev/null || die "Docker is not installed or not in PATH"
command -v dart     > /dev/null || die "Dart SDK is not installed or not in PATH"
command -v flutter  > /dev/null || die "Flutter SDK is not installed or not in PATH"
command -v curl     > /dev/null || die "curl is not installed"
ok "All prerequisites found"

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

# ── Step 3: Demo cards ─────────────────────────────────────────────────────
pause "Server is running. Now let's push a few demo cards — these simulate what AI agents will push to the display."

step "Pushing demo cards"

push_card \
  "agent.flights" \
  "Flight DEN→LAX dropped to \$287" \
  "Round trip, departing June 14. Book before midnight." \
  "medium" "normal"
ok "Card 1 — flight deal alert"

push_card \
  "agent.claude" \
  "3 items need attention before your 2 PM meeting" \
  "Reply to Sarah, review Q2 budget doc, and confirm dinner reservation." \
  "medium" "normal"
ok "Card 2 — pre-meeting briefing"

push_card \
  "agent.home" \
  "Front door left unlocked" \
  "Detected 8 minutes ago. Tap to lock remotely." \
  "medium" "normal"
ok "Card 3 — smart home alert"

info "Cards will appear on the display within a few seconds of launch."

# ── Step 4: Display ────────────────────────────────────────────────────────
pause "Cards are queued. Let's launch the display."

step "Launching Landfall display (macOS)"
info "The app will open in a new window. Press Cmd+Q to quit when you're done."
echo ""

(cd "${DISPLAY_DIR}" && flutter run -d macos lib/main.dart)

# flutter run is blocking — script resumes (and cleanup fires) when the app quits
