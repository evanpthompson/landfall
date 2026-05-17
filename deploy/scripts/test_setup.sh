#!/usr/bin/env bash
# Tests for setup.sh — verifies all required secrets are generated.
# Run from repo root: bash deploy/scripts/test_setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_SCRIPT="${SCRIPT_DIR}/setup.sh"

PASS=0
FAIL=0

ok()   { echo "  PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $*"; FAIL=$((FAIL + 1)); }

# ── Fixture ───────────────────────────────────────────────────────────────────

TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "${TMPDIR_TEST}"' EXIT

ENV_EXAMPLE="${TMPDIR_TEST}/.env.example"
ENV_OUT="${TMPDIR_TEST}/.env"

cp "${SCRIPT_DIR}/../.env.example" "${ENV_EXAMPLE}"

# Run non-interactively: blank domain (accepts default) and no optional keys
DEPLOY_DIR_OVERRIDE="${TMPDIR_TEST}" bash "${SETUP_SCRIPT}" --non-interactive \
  < /dev/null 2>/dev/null || true

# ── Assertions ────────────────────────────────────────────────────────────────

echo ""
echo "deploy/scripts/setup.sh — secret generation"
echo ""

assert_generated() {
  local key="$1"
  local value
  value="$(grep "^${key}=" "${ENV_OUT}" 2>/dev/null | cut -d= -f2-)"
  if [[ -n "${value}" && "${value}" != "replace_with_generated_secret" ]]; then
    ok "${key} generated (${#value} chars)"
  else
    fail "${key} missing or still a placeholder"
  fi
}

assert_empty() {
  local key="$1"
  local value
  value="$(grep "^${key}=" "${ENV_OUT}" 2>/dev/null | cut -d= -f2-)"
  if [[ -z "${value}" ]]; then
    ok "${key} left empty (external secret — correct)"
  else
    fail "${key} should be empty but got: ${value:0:20}..."
  fi
}

assert_generated DB_PASSWORD
assert_generated REDIS_PASSWORD
assert_generated SERVERPOD_SERVICE_SECRET
assert_generated JWT_HMAC_KEY
assert_generated JWT_REFRESH_PEPPER
assert_generated API_KEY_MANAGEMENT_TOKEN
assert_generated API_KEY_HMAC_SECRET
assert_generated PHOTO_SIGNING_SECRET
assert_generated OAUTH_TOKEN_ENCRYPTION_KEY
assert_empty     STRIPE_WEBHOOK_SECRET
assert_empty     OWM_API_KEY
# Google Drive service account: external secrets, never auto-generated.
# The user fills these in from a Google Cloud service account JSON key.
assert_empty     GOOGLE_SERVICE_ACCOUNT_EMAIL
assert_empty     GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
echo ""

[[ "${FAIL}" -eq 0 ]]
