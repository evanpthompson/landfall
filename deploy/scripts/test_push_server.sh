#!/usr/bin/env bash
# Tests for push-server.sh — verifies CLI surface, error handling, and dry-run
# output. Does not exercise the real Docker build or SSH path; those are
# covered by manual end-to-end runs against the Pi (documented in
# docs/updating.md).
#
# Run from repo root: bash deploy/scripts/test_push_server.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PUSH_SCRIPT="${SCRIPT_DIR}/push-server.sh"

PASS=0
FAIL=0

ok()   { echo "  PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $*"; FAIL=$((FAIL + 1)); }

# ── Assertions ───────────────────────────────────────────────────────────────

echo ""
echo "deploy/scripts/push-server.sh — surface tests"
echo ""

# 1. File exists and is executable.
if [[ -x "${PUSH_SCRIPT}" ]]; then
  ok "push-server.sh exists and is executable"
else
  fail "push-server.sh missing or not executable"
fi

# 2. Bash syntax is valid.
if bash -n "${PUSH_SCRIPT}" 2>/dev/null; then
  ok "bash -n parses cleanly"
else
  fail "bash -n reported syntax errors"
fi

# 3. --help prints usage and exits 0 without side effects.
if "${PUSH_SCRIPT}" --help >/dev/null 2>&1; then
  ok "--help exits 0"
else
  fail "--help did not exit 0"
fi

HELP_OUT="$("${PUSH_SCRIPT}" --help 2>&1 || true)"
if echo "${HELP_OUT}" | grep -q "Usage:"; then
  ok "--help output includes 'Usage:'"
else
  fail "--help output missing 'Usage:' line"
fi

# 4. Missing PI_IP (no arg, no env var, no .env entry) fails with a clear
#    message and non-zero exit. Use an isolated empty .env so test machine
#    state doesn't leak in.
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "${TMPDIR_TEST}"' EXIT

touch "${TMPDIR_TEST}/.env"
ERR_OUT="$(LANDFALL_PI_IP="" \
  DEPLOY_DIR_OVERRIDE="${TMPDIR_TEST}" \
  "${PUSH_SCRIPT}" --dry-run 2>&1 || true)"
ERR_CODE="$(LANDFALL_PI_IP="" \
  DEPLOY_DIR_OVERRIDE="${TMPDIR_TEST}" \
  "${PUSH_SCRIPT}" --dry-run >/dev/null 2>&1; echo $?)"

if [[ "${ERR_CODE}" -ne 0 ]]; then
  ok "missing PI_IP exits non-zero"
else
  fail "missing PI_IP should exit non-zero (got 0)"
fi

if echo "${ERR_OUT}" | grep -qi "pi.*ip\|host\|landfall_pi_ip"; then
  ok "missing PI_IP error mentions the missing setting"
else
  fail "missing PI_IP error message is unclear: ${ERR_OUT}"
fi

# 5. --dry-run with a PI_IP prints the commands it would run, exits 0, and
#    does not invoke docker/scp/ssh for real.
DRY_OUT="$(LANDFALL_PI_IP="192.0.2.42" \
  DEPLOY_DIR_OVERRIDE="${TMPDIR_TEST}" \
  "${PUSH_SCRIPT}" --dry-run 2>&1 || true)"
DRY_CODE="$(LANDFALL_PI_IP="192.0.2.42" \
  DEPLOY_DIR_OVERRIDE="${TMPDIR_TEST}" \
  "${PUSH_SCRIPT}" --dry-run >/dev/null 2>&1; echo $?)"

if [[ "${DRY_CODE}" -eq 0 ]]; then
  ok "--dry-run exits 0 when PI_IP is set"
else
  fail "--dry-run should exit 0 (got ${DRY_CODE})"
fi

# Each required step must appear in dry-run output so reviewers can verify
# the plan without running it.
for needle in "docker buildx build" "--platform linux/arm64" "docker save" "scp" "ssh" "docker compose"; do
  if echo "${DRY_OUT}" | grep -qF -- "${needle}"; then
    ok "--dry-run lists '${needle}'"
  else
    fail "--dry-run missing expected step '${needle}'"
  fi
done

# 6. Positional arg overrides LANDFALL_PI_IP.
OVERRIDE_OUT="$(LANDFALL_PI_IP="192.0.2.42" \
  DEPLOY_DIR_OVERRIDE="${TMPDIR_TEST}" \
  "${PUSH_SCRIPT}" --dry-run 192.0.2.99 2>&1 || true)"
if echo "${OVERRIDE_OUT}" | grep -q "192.0.2.99" && \
   ! echo "${OVERRIDE_OUT}" | grep -q "192.0.2.42"; then
  ok "positional arg overrides LANDFALL_PI_IP"
else
  fail "positional arg did not override LANDFALL_PI_IP"
fi

# 7. PI_IP from .env file is picked up when env var is unset.
echo "LANDFALL_PI_IP=192.0.2.55" > "${TMPDIR_TEST}/.env"
ENV_OUT="$(LANDFALL_PI_IP="" \
  DEPLOY_DIR_OVERRIDE="${TMPDIR_TEST}" \
  "${PUSH_SCRIPT}" --dry-run 2>&1 || true)"
if echo "${ENV_OUT}" | grep -q "192.0.2.55"; then
  ok ".env LANDFALL_PI_IP is read when env var unset"
else
  fail ".env LANDFALL_PI_IP not picked up: ${ENV_OUT}"
fi

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
echo ""

[[ "${FAIL}" -eq 0 ]]
