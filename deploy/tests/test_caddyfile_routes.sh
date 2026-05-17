#!/usr/bin/env bash
# Verifies that the Caddyfile routes every companion endpoint via a named
# matcher that covers both the bare path and the /* glob.
#
# Regression guard A (original): /companion/* alone does not match /companion
# (no trailing slash). The Serverpod client POSTs to the bare path, so the
# request fell to the catch-all webserver and returned 405.
#
# Regression guard B (this session): inline multi-path syntax
# "reverse_proxy /companion /companion/* server:8080" is invalid — Caddy
# treats the second path token as a second upstream address, causing intermittent
# 502s via round-robin against an invalid dial target. The fix is a named
# matcher: "@companion path /companion /companion/*"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CADDYFILE="${SCRIPT_DIR}/../Caddyfile"

[[ -f "${CADDYFILE}" ]] || { echo "Caddyfile not found at ${CADDYFILE}" >&2; exit 1; }

# Endpoints exposed through Caddy that are POSTed to by the companion (mobile
# web) client. The display app talks directly to Serverpod on localhost and
# does not pass through Caddy, so endpoints used only by display are excluded.
required_endpoints=(
  companion
)

fail=0
for ep in "${required_endpoints[@]}"; do
  # Find any named matcher declaration that includes both bare /<ep> and /<ep>/*.
  # Pattern: "@<name> path ... /<ep> ... /<ep>/*" or "/<ep>/* ... /<ep>"
  # We require both tokens to appear on the same matcher line.
  matcher_line=$(grep -E "@[a-z_]+[[:space:]]+path[[:space:]]" "${CADDYFILE}" \
    | grep -E "(^|[[:space:]])/${ep}([[:space:]]|$)" \
    | grep -E "(^|[[:space:]])/${ep}/\*([[:space:]]|$)" || true)

  if [[ -z "${matcher_line}" ]]; then
    echo "FAIL: No named matcher covers both /${ep} and /${ep}/*" >&2
    echo "      Use: @${ep} path /${ep} /${ep}/*" >&2
    echo "      Then: reverse_proxy @${ep} server:8080" >&2
    echo "      (Inline 'reverse_proxy /a /b upstream' is invalid — Caddy treats" >&2
    echo "       extra path tokens as additional upstream addresses.)" >&2
    fail=1
    continue
  fi

  # Extract the matcher name (@foo) and verify a reverse_proxy uses it.
  matcher_name=$(echo "${matcher_line}" | grep -oE "@[a-z_]+" | head -1)
  if ! grep -qE "reverse_proxy[[:space:]]+${matcher_name}([[:space:]]|$)" "${CADDYFILE}"; then
    echo "FAIL: Named matcher '${matcher_name}' declared but never used in reverse_proxy" >&2
    fail=1
  fi
done

if (( fail == 1 )); then
  exit 1
fi

echo "OK: Caddyfile routes all required endpoints via named matchers"
