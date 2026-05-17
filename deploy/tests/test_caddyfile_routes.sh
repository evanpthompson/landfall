#!/usr/bin/env bash
# Verifies that the Caddyfile routes every API endpoint Serverpod's client
# POSTs to as both the bare path and the /* glob.
#
# Regression guard: a previous Caddyfile listed only `/companion/*`, which
# does not match `/companion` (no trailing slash). The Serverpod client POSTs
# to the bare `/companion`, so the request fell to the catch-all webserver
# and returned 405 Method Not Allowed, breaking the companion page.

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
  # Match a reverse_proxy line that contains both /<ep> as a standalone token
  # and the /<ep>/* glob. The bare path must appear with a trailing space or
  # tab so we don't accidentally match /<ep>/* as fulfilling /<ep>.
  if ! grep -E "reverse_proxy[[:space:]]+([^[:space:]]+[[:space:]]+)*/${ep}([[:space:]]|$)" "${CADDYFILE}" \
        | grep -qE "/${ep}/\*"; then
    echo "FAIL: Caddyfile does not route both /${ep} and /${ep}/* together" >&2
    echo "      Serverpod POSTs to the bare /${ep} — the /* glob alone returns 405." >&2
    fail=1
  fi
done

if (( fail == 1 )); then
  exit 1
fi

echo "OK: Caddyfile routes all required endpoints"
