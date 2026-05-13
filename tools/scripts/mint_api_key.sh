#!/usr/bin/env bash
# Mint a new Landfall API key against a running dev server.
#
# Usage:
#   bash tools/scripts/mint_api_key.sh                   # localhost:8080, auto-named
#   bash tools/scripts/mint_api_key.sh --name debug-pi-1
#   bash tools/scripts/mint_api_key.sh --server http://192.168.1.42:8080 --name pi-debug
#
# Reads `apiKeyManagementToken` from server/landfall_server/config/passwords.yaml
# (the setup token added in the OWASP A01 hardening) so you don't have to
# remember where it lives. The plaintext key is printed to stdout — paste it
# into passwords.yaml as `landfallTelemetryApiKey` (under production:) and
# it persists across rebuilds of the dev server, debug Pi images, etc.
#
# Requires: curl, python3 (for JSON pretty-print).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PW_FILE="${REPO_ROOT}/server/landfall_server/config/passwords.yaml"

SERVER="http://localhost:8080"
NAME="debug-pi-$(date +%Y%m%d-%H%M%S)"
SECTION="development"   # which top-level section in passwords.yaml to read from

while [[ $# -gt 0 ]]; do
  case "$1" in
    --server)   SERVER="${2%/}"; shift 2 ;;
    --name)     NAME="$2";       shift 2 ;;
    --section)  SECTION="$2";    shift 2 ;;
    -h|--help)
      sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "${PW_FILE}" ]]; then
  echo "✗  passwords.yaml not found at ${PW_FILE}" >&2
  echo "   Run from repo root, or set up the dev server first." >&2
  exit 1
fi

# Pull apiKeyManagementToken from the chosen section. AWK walks the file,
# tracks which top-level section we're in, and prints the value when it
# finds the key inside the right section. Single-quoted values only — that's
# the only format passwords.yaml uses for secrets.
TOKEN="$(awk -v target="${SECTION}" '
  /^[a-zA-Z]/ { section = $1; gsub(":", "", section); next }
  section == target && /apiKeyManagementToken:/ {
    if (match($0, /'\''([^'\'']+)'\''/, m)) { print m[1]; exit }
  }
' "${PW_FILE}")"

if [[ -z "${TOKEN}" ]]; then
  echo "✗  apiKeyManagementToken not found in ${SECTION}: section of ${PW_FILE}" >&2
  echo "   Sections found:" >&2
  grep -E '^[a-zA-Z][a-zA-Z]*:' "${PW_FILE}" | sed 's/^/     /' >&2
  exit 1
fi

# Probe the server first so we fail fast with a clear error.
if ! curl -fsS -m 5 -o /dev/null "${SERVER}/"; then
  echo "✗  Server not reachable at ${SERVER}" >&2
  echo "   Start it with:  bash tools/scripts/start_mac.sh --server" >&2
  exit 1
fi

RESPONSE="$(
  curl -fsS -X POST "${SERVER}/apiKey/generateKey" \
    -H 'Content-Type: application/json' \
    -d "$(python3 -c '
import json, sys
print(json.dumps({"name": sys.argv[1], "setupToken": sys.argv[2]}))
' "${NAME}" "${TOKEN}")"
)"

PLAINTEXT="$(python3 -c '
import json, sys
print(json.loads(sys.stdin.read()).get("plainTextKey", ""))
' <<< "${RESPONSE}")"

if [[ -z "${PLAINTEXT}" ]]; then
  echo "✗  Server returned no plainTextKey. Raw response:" >&2
  echo "${RESPONSE}" | python3 -m json.tool >&2 || echo "${RESPONSE}" >&2
  exit 1
fi

cat <<EOF

✓  API key minted

   name:   ${NAME}
   key:    ${PLAINTEXT}
   server: ${SERVER}

To use for dev-image telemetry, add to ${PW_FILE}
under the production: section (or whichever section your Pi image reads):

   landfallTelemetryEndpoint: '${SERVER}/api/v1/telemetry/event'
   landfallTelemetryApiKey:   '${PLAINTEXT}'

passwords.yaml is gitignored — this is the persistent home for the key.
Mint once, reuse across every debug Pi image build. The key only stops
working if you wipe the dev server's Postgres volume.

EOF
