#!/usr/bin/env bash
# Push a demo agent card to the Landfall display.
#
# Usage:
#   ./tools/scripts/demo_push_card.sh [SERVER_URL]
#
# Defaults to http://localhost:8080 if SERVER_URL is not provided.
#
# The card will appear in the agent feed on the right side of the display
# within 30 seconds (next poll cycle). To see it immediately, restart the
# display app or wait for the next refresh.

set -euo pipefail

SERVER="${1:-http://localhost:8080}"
ENDPOINT="${SERVER}/card/pushCard"

curl -sf \
  -X POST "${ENDPOINT}" \
  -H "Content-Type: application/json" \
  -d '{
    "request": {
      "__className__": "CardPushRequest",
      "source":   "agent.demo",
      "title":    "Flight DEN→LAX dropped to $287",
      "body":     "Round trip, departing June 14. Book before midnight.",
      "layout":   "medium",
      "priority": "normal"
    }
  }' \
| python3 -m json.tool

echo ""
echo "Card pushed. It will appear on the display within 30 seconds."
