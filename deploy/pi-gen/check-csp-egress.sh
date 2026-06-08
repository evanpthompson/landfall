#!/usr/bin/env bash
# Assert the Caddyfile CSP connect-src is a superset of every absolute host the
# compiled companion web app (main.dart.js) can actually fetch at runtime.
#
# This is the single source of truth for the egress contract. It is called from
# two places so the same policy is enforced early and late:
#   - .github/workflows/ci.yml (companion_web job) against the fresh `flutter
#     build web` output — fails a PR the moment a fetchable absolute URL is
#     reintroduced into apps/display, instead of waiting for the image build.
#   - deploy/pi-gen/verify-artifact.sh (section 8) against the staged image
#     artifact — the final gate on what actually ships.
#
# Hosts that appear only as inert string literals (framework error messages,
# package-metadata constants) are suppressed via the allowlist
# `caddy.csp_connect_src_string_literal_hosts` in expected-components.yaml.
# Add to that list only after confirming (browser dev tools, no CSP violation
# logged) that the host is reference-only and never fetched.
#
# Usage:
#   bash check-csp-egress.sh --main-js <path> [--caddyfile <path>] [--expected <path>]
# Exits 0 if connect-src covers every fetchable host; nonzero otherwise.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

MAIN_JS=""
CADDYFILE="${REPO_ROOT}/deploy/Caddyfile"
EXPECTED="${SCRIPT_DIR}/expected-components.yaml"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --main-js)   MAIN_JS="$2"; shift 2 ;;
    --caddyfile) CADDYFILE="$2"; shift 2 ;;
    --expected)  EXPECTED="$2"; shift 2 ;;
    *) echo "check-csp-egress: unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -n "${MAIN_JS}"   ]] || { echo "check-csp-egress: --main-js required" >&2; exit 2; }
[[ -f "${MAIN_JS}"   ]] || { echo "check-csp-egress: main.dart.js not found: ${MAIN_JS}" >&2; exit 2; }
[[ -f "${CADDYFILE}" ]] || { echo "check-csp-egress: Caddyfile not found: ${CADDYFILE}" >&2; exit 2; }
[[ -f "${EXPECTED}"  ]] || { echo "check-csp-egress: expected file not found: ${EXPECTED}" >&2; exit 2; }

GREEN=$'\033[1;32m'; RED=$'\033[1;31m'; RESET=$'\033[0m'

FAILS=()
pass() { echo "${GREEN}✓${RESET} $*"; }
fail() { echo "${RED}✗${RESET} $*"; FAILS+=("$*"); }

# Read the 4-space `- item` entries under caddy.csp_connect_src_string_literal_hosts.
# Stdlib-only python so this runs on the build host and in CI without pyyaml.
ignore_hosts() {
  python3 - "${EXPECTED}" <<'PY'
import sys
in_caddy = in_list = False
with open(sys.argv[1]) as f:
    for raw in f:
        line = raw.rstrip('\n')
        stripped = line.lstrip()
        if not stripped or stripped.startswith('#'):
            continue
        indent = len(line) - len(line.lstrip())
        if indent == 0 and stripped.endswith(':'):
            in_caddy = stripped[:-1].strip() == 'caddy'
            in_list = False
        elif indent == 2 and in_caddy and ':' in stripped:
            in_list = stripped.split(':', 1)[0].strip() == 'csp_connect_src_string_literal_hosts'
        elif indent == 4 and in_list and stripped.startswith('- '):
            item = stripped[2:]
            if '#' in item:
                item = item.split('#', 1)[0]
            item = item.strip()
            if item:
                print(item)
PY
}

CSP_LINE="$(grep -E 'Content-Security-Policy' "${CADDYFILE}" || true)"
CONNECT_SRC="$(echo "${CSP_LINE}" | sed -nE 's/.*connect-src ([^;]*);.*/\1/p')"
IGNORE_HOSTS="$(ignore_hosts || true)"

# Extract scheme://host patterns from main.dart.js. We accept self-only builds;
# the check fires only when an absolute URL appears in the JS.
HOSTS="$(grep -oE 'https?://[a-zA-Z0-9_.-]+|wss?://[a-zA-Z0-9_.-]+' "${MAIN_JS}" \
          | sort -u || true)"

if [[ -z "${HOSTS}" ]]; then
  pass "main.dart.js references no absolute http(s)/ws(s) hosts"
else
  while IFS= read -r host; do
    [[ -z "${host}" ]] && continue
    origin="$(echo "${host}"   | sed -E 's#^(https?|wss?)://([^/]+).*#\1://\2#')"
    hostname="$(echo "${host}" | sed -E 's#^[a-z]+://([^/]+).*#\1#')"
    # Suppress string-literal-only hosts (framework error messages etc.).
    if [[ -n "${IGNORE_HOSTS}" ]] && \
       echo "${IGNORE_HOSTS}" | grep -qxF "${hostname}"; then
      pass "CSP ignores string-literal host: ${origin}"
      continue
    fi
    # Allow if the origin or hostname appears in connect-src verbatim, or if
    # connect-src includes 'self' and the host is localhost / 127.0.0.1.
    if echo "${CONNECT_SRC}" | grep -qE "(${hostname}|${origin})"; then
      pass "CSP allows host from main.dart.js: ${origin}"
    elif [[ "${hostname}" =~ ^(localhost|127\.0\.0\.1)$ ]] && \
         echo "${CONNECT_SRC}" | grep -q "'self'"; then
      pass "CSP 'self' covers loopback host: ${origin}"
    else
      fail "CSP connect-src missing host referenced from main.dart.js: ${origin}"
    fi
  done <<< "${HOSTS}"
fi

if (( ${#FAILS[@]} == 0 )); then
  exit 0
fi
echo "" >&2
echo "check-csp-egress: ${#FAILS[@]} failure(s):" >&2
for f in "${FAILS[@]}"; do echo "  • ${f}" >&2; done
exit 1
