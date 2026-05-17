#!/usr/bin/env bash
# Asserts that the `/app/*` route is not wired up — neither in the Caddyfile
# nor in the Serverpod web server registration.
#
# Why: /app/ used to serve the companion Flutter bundle without the display-ID
# injection the companion route does, so opening /app on a phone would load a
# half-broken UI. Until the post-beta "web admin UI" phase lands (see
# docs/roadmap.md, "Web admin UI" backlog item), the route should be absent so
# requests fail fast with 404 instead of serving a misleading bundle.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CADDYFILE="${REPO_ROOT}/deploy/Caddyfile"
SERVER_DART="${REPO_ROOT}/server/landfall_server/lib/server.dart"

[[ -f "${CADDYFILE}" ]]   || { echo "Caddyfile not found at ${CADDYFILE}" >&2; exit 1; }
[[ -f "${SERVER_DART}" ]] || { echo "server.dart not found at ${SERVER_DART}" >&2; exit 1; }

fail=0

# 1. Caddyfile must not reverse-proxy /app or /app/*.
if grep -E '^[[:space:]]*reverse_proxy[[:space:]]+/app([[:space:]/]|$)' "${CADDYFILE}" >/dev/null; then
  echo "FAIL: Caddyfile still contains a reverse_proxy for /app or /app/*" >&2
  grep -nE '^[[:space:]]*reverse_proxy[[:space:]]+/app' "${CADDYFILE}" >&2
  echo "      Remove until the post-beta web admin UI lands." >&2
  fail=1
fi

# 2. server.dart must not register any /app or /app/** route.
if grep -E "'/app['/]" "${SERVER_DART}" >/dev/null; then
  echo "FAIL: server.dart still registers a /app route" >&2
  grep -nE "'/app['/]" "${SERVER_DART}" >&2
  echo "      Remove pod.webServer.addRoute(... '/app...') registrations." >&2
  fail=1
fi

# 3. AppConfigRoute should be removed (it only existed to serve /app config.json).
if [[ -f "${REPO_ROOT}/server/landfall_server/lib/src/web/routes/app_config_route.dart" ]]; then
  echo "FAIL: app_config_route.dart still exists — delete it; nothing else uses it." >&2
  fail=1
fi

if (( fail == 1 )); then
  exit 1
fi

echo "OK: /app route is absent (Caddyfile, server.dart, app_config_route.dart)"
