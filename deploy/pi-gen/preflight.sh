#!/usr/bin/env bash
# Verify that everything required for build.sh is ready.
# Run this before build.sh to catch problems without waiting 20–40 minutes.
#
# Usage: bash deploy/pi-gen/preflight.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WORK_DIR="${SCRIPT_DIR}/work"

GREEN=$'\033[1;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[1;31m'
CYAN=$'\033[1;36m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

PASS=0
WARN=0
FAIL=0

pass() { echo "${GREEN}  ✓  $*${RESET}";  ((PASS++)); }
warn() { echo "${YELLOW}  ⚠  $*${RESET}"; ((WARN++)); }
fail() { echo "${RED}  ✗  $*${RESET}";   ((FAIL++)); }
info() { echo "${DIM}     $*${RESET}"; }
section() { echo ""; echo "${CYAN}${BOLD}$*${RESET}"; }

HOST_OS="$(uname -s)"

echo ""
echo "${CYAN}${BOLD}Landfall — Pi image build preflight check${RESET}"
echo ""

# ── Docker ────────────────────────────────────────────────────────────────────
section "Docker"

if command -v docker > /dev/null 2>&1; then
  pass "Docker installed: $(docker --version | head -1)"
else
  fail "Docker not found — install Docker Desktop from docker.com"
fi

if docker info > /dev/null 2>&1; then
  pass "Docker daemon is running"
else
  fail "Docker daemon is not running — start Docker Desktop"
fi

if docker buildx version > /dev/null 2>&1; then
  pass "Docker buildx available"
else
  fail "Docker buildx not available — update Docker Desktop to a recent version"
fi

# ── QEMU / arm64 emulation ────────────────────────────────────────────────────
section "arm64 emulation (QEMU)"

if [[ "${HOST_OS}" == "Linux" ]]; then
  if command -v qemu-aarch64 > /dev/null 2>&1 || \
     [[ -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ]]; then
    pass "QEMU arm64 binfmt registered"
  else
    fail "QEMU arm64 not registered — run: sudo apt-get install qemu-user-binfmt"
  fi
else
  # macOS: check whether Docker Desktop can run arm64 containers
  if docker run --rm --platform linux/arm64 --entrypoint uname \
       alpine:latest -m 2>/dev/null | grep -q "aarch64"; then
    pass "Docker Desktop can run arm64 containers"
  else
    warn "arm64 test container failed — build.sh will attempt to register QEMU binfmt"
    info "If the build fails, run: docker run --privileged --rm tonistiigi/binfmt --install arm"
  fi
fi

# ── Disk space ────────────────────────────────────────────────────────────────
section "Disk space"

AVAIL_GB=$(df -g "${REPO_ROOT}" 2>/dev/null | awk 'NR==2{print $4}' || \
           df -BG "${REPO_ROOT}" 2>/dev/null | awk 'NR==2{gsub(/G/,"",$4); print $4}')
if [[ -n "${AVAIL_GB}" ]]; then
  if (( AVAIL_GB >= 15 )); then
    pass "${AVAIL_GB} GB free (need ~15 GB for a full build)"
  elif (( AVAIL_GB >= 8 )); then
    warn "${AVAIL_GB} GB free — enough if server image and Flutter bundle are already cached"
  else
    fail "${AVAIL_GB} GB free — need at least 8 GB (15 GB for a fresh build)"
  fi
else
  warn "Could not determine available disk space"
fi

# ── Source files ──────────────────────────────────────────────────────────────
section "Source files"

if [[ -f "${REPO_ROOT}/server/landfall_server/Dockerfile" ]]; then
  pass "server/landfall_server/Dockerfile"
else
  fail "server/landfall_server/Dockerfile not found"
fi

if [[ -f "${REPO_ROOT}/server/pubspec.yaml" ]]; then
  pass "server/pubspec.yaml (workspace root)"
else
  fail "server/pubspec.yaml not found — Docker build will fail"
fi

if [[ -d "${REPO_ROOT}/packages/landfall_shared" ]]; then
  pass "packages/landfall_shared/ (server path dependency)"
else
  fail "packages/landfall_shared/ not found — server Docker build will fail"
fi

if [[ -f "${REPO_ROOT}/deploy/docker-compose.prod.yml" ]]; then
  pass "deploy/docker-compose.prod.yml"
else
  fail "deploy/docker-compose.prod.yml not found"
fi

if [[ -d "${SCRIPT_DIR}/stage2-landfall" ]]; then
  pass "deploy/pi-gen/stage2-landfall/ (pi-gen stage)"
else
  fail "deploy/pi-gen/stage2-landfall/ not found"
fi

if [[ -f "${SCRIPT_DIR}/config" ]]; then
  pass "deploy/pi-gen/config"
else
  fail "deploy/pi-gen/config not found"
fi

# ── Cached build artifacts (slow steps that can be skipped) ──────────────────
section "Cached build artifacts"

LINUX_BUNDLE="${REPO_ROOT}/apps/display/build/linux/arm64/release/bundle"
if [[ -d "${LINUX_BUNDLE}" ]]; then
  BUNDLE_SIZE=$(du -sh "${LINUX_BUNDLE}" 2>/dev/null | cut -f1)
  pass "Flutter arm64 bundle already built (${BUNDLE_SIZE}) — Step 1 will be skipped"
else
  warn "Flutter arm64 bundle not found — Step 1 will build it (~20 min)"
  info "Location when built: ${LINUX_BUNDLE}"
fi

STAGE_FILES="${WORK_DIR}/pi-gen/stage2-landfall/00-landfall/files"
SERVER_TARBALL="${STAGE_FILES}/landfall-server.tar.gz"
if [[ -f "${SERVER_TARBALL}" ]]; then
  TARBALL_SIZE=$(du -sh "${SERVER_TARBALL}" 2>/dev/null | cut -f1)
  pass "Server Docker image already staged (${TARBALL_SIZE}) — Step 2 will be skipped"
else
  warn "Server image not staged — Step 2 will cross-compile it (~20–40 min)"
  info "Location when built: ${SERVER_TARBALL}"
fi

# ── pi-gen ────────────────────────────────────────────────────────────────────
section "pi-gen"

PI_GEN_DIR="${WORK_DIR}/pi-gen"
if [[ -d "${PI_GEN_DIR}" ]]; then
  BRANCH="$(git -C "${PI_GEN_DIR}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  if [[ "${BRANCH}" == "arm64" ]]; then
    pass "pi-gen already cloned (arm64 branch)"
  else
    warn "pi-gen cloned but on branch '${BRANCH}' — build.sh will re-clone on arm64"
  fi
else
  warn "pi-gen not yet cloned — build.sh will clone it (needs internet)"
fi

# Check git for cloning
if command -v git > /dev/null 2>&1; then
  pass "git available"
else
  fail "git not found — required to clone pi-gen"
fi

# ── Optional: integration credentials ────────────────────────────────────────
section "Integration credentials (optional)"

CONF_FILE="${SCRIPT_DIR}/landfall-build.conf"
if [[ -f "${CONF_FILE}" ]]; then
  pass "landfall-build.conf found — integration credentials will be baked in"
  # shellcheck disable=SC1090
  source "${CONF_FILE}" 2>/dev/null || true
  [[ -n "${OWM_API_KEY:-}" ]]         && info "  Weather API key: set" \
                                       || info "  Weather API key: not set"
  [[ -n "${GOOGLE_CLIENT_ID:-}" ]]    && info "  Google OAuth:    set" \
                                       || info "  Google OAuth:    not set"
  [[ -n "${MICROSOFT_CLIENT_ID:-}" ]] && info "  Microsoft OAuth: set" \
                                       || info "  Microsoft OAuth: not set"
  [[ -n "${STRIPE_WEBHOOK_SECRET:-}" ]] && info "  Stripe:          set" \
                                         || info "  Stripe:          not set"
else
  pass "No landfall-build.conf — image will boot without integration credentials"
  info "Run configure.sh first if you need Google/Microsoft/weather/Stripe"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────"
TOTAL=$((PASS + WARN + FAIL))
echo "  ${GREEN}${PASS} passed${RESET}   ${YELLOW}${WARN} warnings${RESET}   ${RED}${FAIL} failed${RESET}"
echo ""

if (( FAIL > 0 )); then
  echo "${RED}${BOLD}Not ready.${RESET} Fix the failures above before running build.sh."
  echo ""
  exit 1
elif (( WARN > 0 )); then
  SLOW_STEPS=0
  [[ ! -d "${LINUX_BUNDLE}" ]] && ((SLOW_STEPS++))
  [[ ! -f "${SERVER_TARBALL}" ]] && ((SLOW_STEPS++))
  if (( SLOW_STEPS > 0 )); then
    echo "${YELLOW}${BOLD}Ready, but ${SLOW_STEPS} slow build step(s) will run.${RESET}"
    echo "  Estimated time: $((SLOW_STEPS * 25 + 20))–$((SLOW_STEPS * 40 + 20)) minutes"
  else
    echo "${YELLOW}${BOLD}Ready with warnings.${RESET} Review the warnings above."
  fi
  echo ""
  echo "  Run:  bash deploy/pi-gen/build.sh"
else
  echo "${GREEN}${BOLD}All checks passed.${RESET}"
  echo ""
  echo "  Run:  bash deploy/pi-gen/build.sh"
  [[ -f "${SERVER_TARBALL}" ]] && [[ -d "${LINUX_BUNDLE}" ]] && \
    echo "  Estimated time: ~20 minutes (pi-gen only — all artifacts cached)"
fi
echo ""
