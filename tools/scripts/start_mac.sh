#!/usr/bin/env bash
# Start the full Landfall stack for local macOS development.
#
# Usage:
#   bash tools/scripts/start_mac.sh           # start backend + open existing build
#   bash tools/scripts/start_mac.sh --build   # rebuild the macOS app first, then launch
#   bash tools/scripts/start_mac.sh --reset   # clear profile data + rebuild app + fresh start
#   bash tools/scripts/start_mac.sh --server  # start backend only (no app launch)
#   bash tools/scripts/start_mac.sh --debug   # start backend + `flutter run -d macos`
#                                             # (foreground, streams Flutter logs to terminal)
#
# --reset truncates dashboard_profiles and clears the app's local SQLite so the
# display client re-seeds all three default profiles (Weekday/Weekend/Night) on
# next launch using the current DashboardLayout definitions in landfall_shared.
# Use this whenever layouts have changed and you want a clean slate.
#
# Logs from the Serverpod server are written to:
#   /tmp/landfall-server.log

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SERVER_DIR="${REPO_ROOT}/server/landfall_server"
DISPLAY_DIR="${REPO_ROOT}/apps/display"
APP_DEBUG="${DISPLAY_DIR}/build/macos/Build/Products/Debug/Landfall.app"
APP_RELEASE="${DISPLAY_DIR}/build/macos/Build/Products/Release/Landfall.app"
SERVER_LOG="/tmp/landfall-server.log"
APP_SQLITE="${HOME}/Library/Containers/com.example.display/Data/Documents/landfall.db"

BOLD=$'\033[1m'
GREEN=$'\033[1;32m'
CYAN=$'\033[1;36m'
YELLOW=$'\033[1;33m'
RED=$'\033[1;31m'
RESET=$'\033[0m'

ok()   { echo "${GREEN}✓  $*${RESET}"; }
info() { echo "   $*"; }
warn() { echo "${YELLOW}⚠  $*${RESET}"; }
fail() { echo "${RED}✗  $*${RESET}"; exit 1; }

MODE_BUILD=false
MODE_SERVER_ONLY=false
MODE_RESET=false
MODE_DEBUG=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build)  MODE_BUILD=true; shift ;;
    --server) MODE_SERVER_ONLY=true; shift ;;
    --reset)  MODE_RESET=true; MODE_BUILD=true; shift ;;
    --debug)  MODE_DEBUG=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo ""
echo "${CYAN}${BOLD}Landfall — local macOS launcher${RESET}"
echo ""

# ── 1. Prerequisites ────────────────────────────────────────────────────────

if ! command -v docker > /dev/null; then
  fail "Docker not found. Install Docker Desktop from https://www.docker.com/products/docker-desktop/"
fi

if ! docker info > /dev/null 2>&1; then
  fail "Docker is not running. Start Docker Desktop and try again."
fi

if ! command -v dart > /dev/null; then
  fail "dart not found. Install Flutter/Dart from https://docs.flutter.dev/get-started/install/macos"
fi

# ── 2. Docker dev containers (Postgres + Redis) ──────────────────────────────

cd "${SERVER_DIR}"

if [[ "${MODE_RESET}" == true ]]; then
  warn "RESET: clearing profile data for fresh seed..."

  # Stop the server if running so nothing holds DB connections
  if lsof -i :8080 > /dev/null 2>&1; then
    kill "$(lsof -ti :8080)" 2>/dev/null || true
    sleep 1
  fi

  # Ensure containers are up
  docker compose up -d postgres redis > /dev/null 2>&1
  until docker compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
    sleep 1
  done

  # Clear display data — profiles and agent cards. Migrations, themes, users
  # and calendar/photo credentials are untouched.
  # The display client re-seeds Weekday/Weekend/Night on next launch via _seedDefaults().
  docker compose exec -T postgres psql -U postgres -d landfall -c "
    TRUNCATE TABLE dashboard_profiles RESTART IDENTITY;
    TRUNCATE TABLE cards RESTART IDENTITY;
  " > /dev/null
  ok "dashboard_profiles and cards cleared"

  # Reset wizard_complete so the app re-links its account, but keep server_url
  # and other settings so you don't have to re-enter the server address.
  if [[ -f "${APP_SQLITE}" ]]; then
    sqlite3 "${APP_SQLITE}" \
      "UPDATE display_settings_entries SET wizard_complete = 0;" 2>/dev/null \
      && ok "App wizard state reset (server URL preserved)" \
      || warn "Could not update app local settings (sqlite3 not found?)"
  fi
else
  info "Checking dev containers..."
  POSTGRES_RUNNING=$(docker compose ps --status running postgres 2>/dev/null | grep -c "postgres" || true)
  REDIS_RUNNING=$(docker compose ps --status running redis 2>/dev/null | grep -c "redis" || true)

  if [[ "${POSTGRES_RUNNING}" -eq 0 || "${REDIS_RUNNING}" -eq 0 ]]; then
    info "Starting Postgres and Redis..."
    docker compose up -d postgres redis
    until docker compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
      sleep 1
    done
    ok "Postgres and Redis ready"
  else
    ok "Postgres and Redis already running"
  fi
fi

# ── 3. Serverpod server ───────────────────────────────────────────────────────

if lsof -i :8080 > /dev/null 2>&1; then
  ok "Server already listening on port 8080"
else
  info "Starting Serverpod server (logs → ${SERVER_LOG})..."
  dart run bin/main.dart --apply-migrations > "${SERVER_LOG}" 2>&1 &

  for i in $(seq 1 30); do
    if lsof -i :8080 > /dev/null 2>&1; then
      break
    fi
    sleep 1
  done

  if ! lsof -i :8080 > /dev/null 2>&1; then
    fail "Server did not start within 30s. Check ${SERVER_LOG} for errors."
  fi

  ok "Server listening on http://localhost:8080  (PID $(lsof -ti :8080))"
fi

echo ""

if [[ "${MODE_SERVER_ONLY}" == true ]]; then
  info "Backend is up. Skipping app launch (--server mode)."
  echo ""
  exit 0
fi

# ── 4a. Debug mode — `flutter run` in foreground ────────────────────────────

if [[ "${MODE_DEBUG}" == true ]]; then
  if ! command -v flutter > /dev/null; then
    fail "flutter not found. Install it from https://docs.flutter.dev/get-started/install/macos"
  fi

  # Quit any running release build so flutter run can take the slot.
  osascript -e 'quit app "Landfall"' > /dev/null 2>&1 || true
  sleep 1

  echo "${CYAN}${BOLD}Launching debug build via flutter run...${RESET}"
  info "Client logs will stream to this terminal. Server log: ${SERVER_LOG}"
  echo ""
  cd "${DISPLAY_DIR}"
  exec flutter run -d macos \
    --dart-define=LANDFALL_DEFAULT_SERVER_URL=http://localhost:8080/
fi

# ── 4b. Build macOS app (optional) ───────────────────────────────────────────

if [[ "${MODE_BUILD}" == true ]]; then
  if ! command -v flutter > /dev/null; then
    fail "flutter not found. Install it from https://docs.flutter.dev/get-started/install/macos"
  fi

  echo "${CYAN}${BOLD}Building macOS app...${RESET}"
  cd "${DISPLAY_DIR}"
  flutter build macos --release
  echo ""
  ok "Build complete"
fi

# ── 5. Launch the app ────────────────────────────────────────────────────────

if [[ -d "${APP_RELEASE}" ]]; then
  APP_PATH="${APP_RELEASE}"
elif [[ -d "${APP_DEBUG}" ]]; then
  APP_PATH="${APP_DEBUG}"
  warn "No release build found — launching debug build. Run with --build to create a release build."
else
  fail "No macOS app found. Run with --build to build it first."
fi

info "Launching ${APP_PATH##*/build/macos/Build/Products/}..."
# Quit any running instance first so macOS opens the freshly built binary
osascript -e 'quit app "Landfall"' > /dev/null 2>&1 || true
sleep 1
open -n "${APP_PATH}"
ok "Display launched"
echo ""
info "Server log:  ${SERVER_LOG}"
info "To stop:     kill \$(lsof -ti :8080)"
echo ""
