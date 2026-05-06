#!/usr/bin/env bash
# Push a demo agent card to the Landfall display via the authenticated Agent API.
#
# Usage:
#   ./tools/scripts/demo_push_card.sh [SERVER_URL]
#
# Defaults to http://localhost:8080 if SERVER_URL is not provided.
#
# The script:
#   1. Generates a new API key via ApiKeyEndpoint.generateKey
#   2. Pushes a card via AgentEndpoint.pushCard using that key
#
# The card will appear in the agent feed on the right side of the display
# within 30 seconds (next poll cycle). To see it immediately, restart the
# display app or wait for the next refresh.

set -euo pipefail

SERVER="${1:-http://localhost:8080}"

command -v curl   > /dev/null || { echo "curl is required but not installed"; exit 1; }
command -v python3 > /dev/null || { echo "python3 is required but not installed"; exit 1; }

echo "→ Generating API key..."
KEY_RESPONSE=$(curl -sf \
  -X POST "${SERVER}/apiKey/generateKey" \
  -H "Content-Type: application/json" \
  -d '{"name": "demo-script"}') || {
  echo ""
  echo "✗  Could not reach ${SERVER}"
  echo "   Is the Landfall server running? Try:"
  echo "     cd deploy && docker compose -f docker-compose.prod.yml up -d"
  echo "   Or pass a custom server URL as the first argument:"
  echo "     bash tools/scripts/demo_push_card.sh http://<SERVER_IP>:8080"
  exit 1
}

API_KEY=$(echo "${KEY_RESPONSE}" | python3 -c "import json,sys; print(json.load(sys.stdin)['plainTextKey'])")
echo "  Key: ${API_KEY:0:11}..."

echo ""
echo "→ Pushing card..."
PUSH_RESPONSE=$(curl -sf \
  -X POST "${SERVER}/agent/pushCard" \
  -H "Content-Type: application/json" \
  -d "{
    \"apiKey\": \"${API_KEY}\",
    \"request\": {
      \"__className__\": \"CardPushRequest\",
      \"source\":   \"agent.demo\",
      \"title\":    \"Flight DEN→LAX dropped to \$287\",
      \"body\":     \"Round trip, departing June 14. Book before midnight.\",
      \"layout\":   \"medium\",
      \"priority\": \"normal\"
    }
  }") || {
  echo ""
  echo "✗  Push failed — server was reachable but rejected the request."
  echo "   Check server logs: docker compose -f deploy/docker-compose.prod.yml logs server"
  exit 1
}

echo "${PUSH_RESPONSE}" | python3 -m json.tool

echo ""
echo "Card pushed. It will appear on the display within 30 seconds."
