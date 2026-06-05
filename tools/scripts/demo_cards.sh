#!/usr/bin/env bash
# Push a curated set of demo cards to a running Landfall server for screenshots.
#
# These are REAL agent pushes over the real Agent Push API — nothing faked.
# They just give an empty display a believable, populated agent feed.
#
# Usage:
#   1. Generate a key in the app: Settings → API Keys → Generate (copy the lf_… value)
#   2. Run:
#        LANDFALL_API_KEY=lf_xxx bash tools/scripts/demo_cards.sh
#
#   Optional: LANDFALL_SERVER=http://192.168.1.167:8080  (defaults to localhost:8080)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PASSWORDS="${REPO_ROOT}/server/landfall_server/config/passwords.yaml"

SERVER="${LANDFALL_SERVER:-http://localhost:8080}"
KEY="${LANDFALL_API_KEY:-}"

# If no key was supplied, mint one against the local server using the
# apiKeyManagementToken from passwords.yaml (never printed).
if [[ -z "${KEY}" ]]; then
  echo "No LANDFALL_API_KEY set — minting one from the local server…"
  TOKEN=$(grep -m1 'apiKeyManagementToken:' "${PASSWORDS}" | sed -E "s/.*: *'([^']+)'.*/\1/")
  if [[ -z "${TOKEN}" ]]; then
    echo "✗ Could not read apiKeyManagementToken from ${PASSWORDS}." >&2
    exit 1
  fi
  KEY=$(TOKEN="${TOKEN}" SERVER="${SERVER}" python3 -c '
import json, os, urllib.request
body = json.dumps({"name": "Demo cards", "setupToken": os.environ["TOKEN"]}).encode()
req = urllib.request.Request(
    os.environ["SERVER"] + "/apiKey/generateKey",
    data=body, headers={"Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=8) as r:
    print(json.load(r)["plainTextKey"])')
  if [[ -z "${KEY}" ]]; then
    echo "✗ Key generation failed (is the server running on ${SERVER}?)." >&2
    exit 1
  fi
  echo "Minted a key (prefix ${KEY:0:8}…)."
fi

# push <source> <layout> <priority> <title> <body>
push() {
  local source="$1" layout="$2" priority="$3" title="$4" body="$5"
  local payload
  payload=$(KEY="$KEY" SRC="$source" LO="$layout" PR="$priority" TI="$title" BO="$body" \
    python3 -c '
import json, os
print(json.dumps({
  "apiKey": os.environ["KEY"],
  "request": {
    "__className__": "CardPushRequest",
    "source": os.environ["SRC"],
    "title": os.environ["TI"],
    "body": os.environ["BO"],
    "layout": os.environ["LO"],
    "priority": os.environ["PR"],
  },
}))')
  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 \
    -X POST "${SERVER}/agent/pushCard" \
    -H 'Content-Type: application/json' --data-binary "${payload}")
  echo "  [${code}] ${title}"
}

echo "Pushing demo cards to ${SERVER} …"

push "agent.claude" "large" "normal" \
  "Good morning, Evan" \
  "3 meetings today, first at 9:30. Rain clears by noon — good window to walk the dog after lunch."

push "agent.claude" "medium" "ephemeral" \
  "Flight DEN→LAX dropped to \$287" \
  "Round trip June 14–18, about \$120 below average. Price probably holds a few hours."

push "skill.home_assistant" "small" "normal" \
  "Garage door closed" \
  "Was left open ~20 min. Closed it at 9:14 PM."

push "agent.claude" "medium" "normal" \
  "CI green on main" \
  "Build #482 passed in 6m 12s. 717 tests, 0 failures — safe to deploy."

push "skill.shipping" "small" "ephemeral" \
  "Package out for delivery" \
  "Arriving by 3 PM, 2 stops away."

echo "Done. The display refreshes its cards every ~30s."
