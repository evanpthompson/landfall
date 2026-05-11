#!/usr/bin/env bash
# Start the full Landfall stack for local macOS development.
#
# Usage:
#   bash tools/scripts/start_mac.sh           # start backend + open existing build
#   bash tools/scripts/start_mac.sh --build   # rebuild the macOS app first, then launch
#   bash tools/scripts/start_mac.sh --server  # start backend only (no app launch)
#
# Logs from the Serverpod server are written to:
#   /tmp/landfall-server.log

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SERVER_DIR="${REPO_ROOT}/server/landfall_server"
DISPLAY_DIR="${REPO_ROOT}/apps/display"
APP_DEBUG="${DISPLAY_DIR}/build/macos/Build/Products/Debug/display.app"
APP_RELEASE="${DISPLAY_DIR}/build/macos/Build/Products/Release/display.app"
SERVER_LOG="/tmp/landfall-server.log"

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

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build)  MODE_BUILD=true; shift ;;
    --server) MODE_SERVER_ONLY=true; shift ;;
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

info "Checking dev containers..."
cd "${SERVER_DIR}"

POSTGRES_RUNNING=$(docker compose ps --status running postgres 2>/dev/null | grep -c "postgres" || true)
REDIS_RUNNING=$(docker compose ps --status running redis 2>/dev/null | grep -c "redis" || true)

if [[ "${POSTGRES_RUNNING}" -eq 0 || "${REDIS_RUNNING}" -eq 0 ]]; then
  info "Starting Postgres and Redis..."
  docker compose up -d postgres redis
  info "Waiting for Postgres to be ready..."
  until docker compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
    sleep 1
  done
  ok "Postgres and Redis ready"
else
  ok "Postgres and Redis already running"
fi

# ── 3. Serverpod server ───────────────────────────────────────────────────────

SERVER_PID=""
if lsof -i :8080 > /dev/null 2>&1; then
  ok "Server already listening on port 8080"
else
  info "Starting Serverpod server (logs → ${SERVER_LOG})..."
  dart run bin/main.dart --apply-migrations > "${SERVER_LOG}" 2>&1 &
  SERVER_PID=$!

  # Wait up to 15s for the server to bind port 8080
  for i in $(seq 1 15); do
    if lsof -i :8080 > /dev/null 2>&1; then
      break
    fi
    sleep 1
  done

  if ! lsof -i :8080 > /dev/null 2>&1; then
    fail "Server did not start within 15s. Check ${SERVER_LOG} for errors."
  fi

  ok "Server listening on http://localhost:8080  (PID ${SERVER_PID})"
fi

echo ""

if [[ "${MODE_SERVER_ONLY}" == true ]]; then
  info "Backend is up. Skipping app launch (--server mode)."
  echo ""
  exit 0
fi

# ── 4. Build macOS app (optional) ────────────────────────────────────────────

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
open "${APP_PATH}"
ok "Display launched"
echo ""
info "Server log:  ${SERVER_LOG}"
info "To stop:     kill \$(lsof -ti :8080)"
echo ""
