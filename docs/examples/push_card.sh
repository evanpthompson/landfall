#!/usr/bin/env bash
# Push a card to your Landfall display.
#
# Usage:
#   export LANDFALL_URL="http://localhost:8080"
#   export LANDFALL_API_KEY="lf_..."
#   ./push_card.sh
#
# To generate an API key:
#   curl -s -X POST $LANDFALL_URL/apiKey/generateKey \
#     -H "Content-Type: application/json" \
#     -d '{"name": "my-key"}' | python3 -m json.tool

set -euo pipefail

: "${LANDFALL_URL:?Set LANDFALL_URL (e.g. http://localhost:8080)}"
: "${LANDFALL_API_KEY:?Set LANDFALL_API_KEY}"

curl -sf -X POST "$LANDFALL_URL/agent/pushCard" \
  -H "Content-Type: application/json" \
  -d "{
    \"apiKey\": \"$LANDFALL_API_KEY\",
    \"request\": {
      \"__className__\": \"CardPushRequest\",
      \"source\":     \"agent.shell\",
      \"title\":      \"Backup completed\",
      \"body\":       \"$(date -u '+%Y-%m-%d %H:%M UTC') — 4.2 GB, no errors.\",
      \"layout\":     \"small\",
      \"priority\":   \"normal\",
      \"externalId\": \"agent.shell.last-backup\"
    }
  }" | python3 -m json.tool

echo "Card pushed."
