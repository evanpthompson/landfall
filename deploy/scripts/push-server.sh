#!/usr/bin/env bash
# Push a freshly-built Landfall server image to a Pi.
#
# Replaces the manual "in-place server-only update" steps documented in
# docs/updating.md. One command rebuilds the arm64 image, copies it to the
# Pi, loads it into Docker, and restarts the server service. Postgres,
# Redis, and Caddy stay up.
#
# Usage:
#   bash deploy/scripts/push-server.sh [PI_IP]
#   bash deploy/scripts/push-server.sh --dry-run [PI_IP]
#   bash deploy/scripts/push-server.sh --help
#
# PI resolution order (first match wins):
#   1. Positional argument
#   2. LANDFALL_PI_IP environment variable
#   3. LANDFALL_PI_IP= line in deploy/.env
#
# Examples:
#   LANDFALL_PI_IP=192.168.1.130 bash deploy/scripts/push-server.sh
#   bash deploy/scripts/push-server.sh 192.168.1.130
#   bash deploy/scripts/push-server.sh --dry-run 192.168.1.130
#
# Tests:  bash deploy/scripts/test_push_server.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# DEPLOY_DIR_OVERRIDE lets tests redirect .env lookup to a temp directory.
DEPLOY_DIR="${DEPLOY_DIR_OVERRIDE:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ENV_FILE="${DEPLOY_DIR}/.env"

IMAGE_TAG="landfall-server:latest"
# Where on the Pi the gzipped tarball lands en route to `docker load`.
PI_STAGING_PATH="/tmp/landfall-server.tar.gz"
# Pi SSH user. The pi-gen image creates this account by default.
PI_USER="${LANDFALL_PI_USER:-landfall}"
# Path on the Pi where the deploy stack lives.
PI_DEPLOY_PATH="${LANDFALL_PI_DEPLOY_PATH:-/home/landfall/landfall/deploy}"

BOLD=$'\033[1m'
GREEN=$'\033[1;32m'
CYAN=$'\033[1;36m'
YELLOW=$'\033[1;33m'
RED=$'\033[1;31m'
RESET=$'\033[0m'

ok()    { echo "${GREEN}✓  $*${RESET}"; }
info()  { echo "   $*"; }
warn()  { echo "${YELLOW}⚠  $*${RESET}" >&2; }
error() { echo "${RED}✗  $*${RESET}" >&2; }

usage() {
  cat <<'USAGE'
Usage: push-server.sh [--dry-run] [PI_IP]
       push-server.sh --help

Build the Landfall server image for arm64, copy it to a Pi, load it into
Docker, and restart the server service.

Options:
  --dry-run       Print the commands that would run; do not execute them.
  --help          Print this message and exit.

PI_IP resolution order (first match wins):
  1. Positional argument
  2. LANDFALL_PI_IP environment variable
  3. LANDFALL_PI_IP= line in deploy/.env

Environment variables:
  LANDFALL_PI_IP             Target Pi host or IP.
  LANDFALL_PI_USER           SSH user on the Pi (default: landfall).
  LANDFALL_PI_DEPLOY_PATH    Deploy dir on the Pi
                             (default: /home/landfall/landfall/deploy).
USAGE
}

# ── Argument parsing ─────────────────────────────────────────────────────────

DRY_RUN=0
POSITIONAL_PI=""

for arg in "$@"; do
  case "${arg}" in
    --help|-h)
      usage
      exit 0
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    --*)
      error "Unknown option: ${arg}"
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "${POSITIONAL_PI}" ]]; then
        error "Too many positional arguments. Pass one PI_IP only."
        exit 2
      fi
      POSITIONAL_PI="${arg}"
      ;;
  esac
done

# ── Resolve PI_IP ────────────────────────────────────────────────────────────

PI_IP=""
if [[ -n "${POSITIONAL_PI}" ]]; then
  PI_IP="${POSITIONAL_PI}"
elif [[ -n "${LANDFALL_PI_IP:-}" ]]; then
  PI_IP="${LANDFALL_PI_IP}"
elif [[ -f "${ENV_FILE}" ]]; then
  PI_IP="$(grep -E '^LANDFALL_PI_IP=' "${ENV_FILE}" 2>/dev/null \
            | head -1 | cut -d= -f2- | tr -d '\r"' || true)"
fi

if [[ -z "${PI_IP}" ]]; then
  error "Pi IP/host not set."
  info "Provide one of:"
  info "  - pass as the first argument:  push-server.sh 192.168.1.130"
  info "  - export LANDFALL_PI_IP:       LANDFALL_PI_IP=192.168.1.130 push-server.sh"
  info "  - add to ${ENV_FILE}:          LANDFALL_PI_IP=192.168.1.130"
  exit 1
fi

# ── Execution helper ─────────────────────────────────────────────────────────

# run "label" cmd args...   — print and execute (or just print in dry-run)
run() {
  local label="$1"; shift
  echo "${CYAN}→ ${label}${RESET}"
  printf '   '
  # Print the command with shell-friendly quoting for visibility.
  printf '%q ' "$@"
  printf '\n'
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    return 0
  fi
  "$@"
}

# Some steps are pipelines that printf can't represent cleanly. For those we
# print a representative command line for the user, then run the pipeline.
run_shell() {
  local label="$1"; shift
  local rendered="$1"; shift
  echo "${CYAN}→ ${label}${RESET}"
  echo "   ${rendered}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    return 0
  fi
  bash -c "$@"
}

# ── Plan ─────────────────────────────────────────────────────────────────────

echo ""
echo "${CYAN}${BOLD}push-server.sh${RESET}   target: ${PI_USER}@${PI_IP}"
[[ "${DRY_RUN}" -eq 1 ]] && echo "${YELLOW}(dry-run — no commands will execute)${RESET}"
echo ""

# 1. Build companion web app (must run before Docker so the image contains fresh
#    assets). web/app is gitignored — it is a build artifact that must be
#    regenerated from source. Skipping this step would bake stale companion UI
#    into the image.
echo "${CYAN}→ Build companion web app${RESET}"
if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo "   flutter build web --release --target lib/companion_web_main.dart --no-web-resources-cdn"
else
  if ! command -v flutter > /dev/null; then
    error "flutter not found — required to build the companion web app."
    error "Install Flutter from https://docs.flutter.dev/get-started/install"
    exit 1
  fi
  (
    cd "${REPO_ROOT}/apps/display"
    # --no-web-resources-cdn: serve CanvasKit locally to match the canonical
    # server/pi-gen build; otherwise the Caddyfile CSP blocks the gstatic fetch.
    flutter build web --release --target lib/companion_web_main.dart --no-web-resources-cdn
  )
  rm -rf "${REPO_ROOT}/server/landfall_server/web/app"
  cp -r "${REPO_ROOT}/apps/display/build/web" \
        "${REPO_ROOT}/server/landfall_server/web/app"
  ok "Companion web built and staged"
fi

# 2. Build the arm64 image. --platform is non-negotiable: an amd64 build on a
#    dev Mac will load successfully on the Pi but fail at runtime with
#    "exec format error".
#    Build context must be the repo root (Dockerfile COPY paths are relative
#    to it) and -f points explicitly at the Dockerfile location.
run "Build arm64 image" \
  docker buildx build \
    --platform linux/arm64 \
    --load \
    -t "${IMAGE_TAG}" \
    -f "${REPO_ROOT}/server/landfall_server/Dockerfile" \
    "${REPO_ROOT}"

# 2. Save + gzip locally. Kept in /tmp on the dev machine so failed pushes
#    don't litter the repo.
LOCAL_TAR="/tmp/landfall-server-$(date +%s).tar.gz"
run_shell "Save image to ${LOCAL_TAR}" \
  "docker save ${IMAGE_TAG} | gzip > ${LOCAL_TAR}" \
  "docker save '${IMAGE_TAG}' | gzip > '${LOCAL_TAR}'"

# 3. Copy to Pi.
run "Copy to Pi" \
  scp "${LOCAL_TAR}" "${PI_USER}@${PI_IP}:${PI_STAGING_PATH}"

# 4. Load on Pi + restart server service + clean up the staging tarball.
REMOTE_CMD="set -euo pipefail; \
gunzip -c '${PI_STAGING_PATH}' | docker load; \
cd '${PI_DEPLOY_PATH}'; \
docker compose -f docker-compose.prod.yml up -d --no-deps server; \
rm -f '${PI_STAGING_PATH}'"

# Print the remote command in a readable form (printf %q would escape every
# space and obscure 'docker compose ...').
echo "${CYAN}→ Load image and restart server on Pi${RESET}"
echo "   ssh ${PI_USER}@${PI_IP} '${REMOTE_CMD}'"
if [[ "${DRY_RUN}" -ne 1 ]]; then
  ssh "${PI_USER}@${PI_IP}" "${REMOTE_CMD}"
fi

# 5. Local cleanup.
run "Remove local tarball ${LOCAL_TAR}" \
  rm -f "${LOCAL_TAR}"

echo ""
if [[ "${DRY_RUN}" -eq 1 ]]; then
  ok "Dry-run complete. No changes were made."
else
  ok "Server image pushed and restarted."
  info "Health check:  ssh ${PI_USER}@${PI_IP} 'landfall-doctor'"
fi
echo ""
