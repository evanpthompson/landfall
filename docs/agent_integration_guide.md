# Landfall Agent Integration Guide

Push content from any agent, script, or automation onto your Landfall display.

---

## How It Works

Landfall exposes a simple HTTP API. You authenticate with an API key and `POST` a card payload. The card appears on the display within 30 seconds (next poll cycle).

That's it. No SDK required. Any language, any automation platform, any agent that can make an HTTP request can push cards.

---

## Quick Start (5 minutes)

### 1. Generate an API key

```bash
curl -s -X POST http://localhost:8080/apiKey/generateKey \
  -H "Content-Type: application/json" \
  -d '{"name": "my-first-key"}' \
  | python3 -m json.tool
```

Response:
```json
{
  "key": { "id": 1, "name": "my-first-key", "prefix": "lf_a3f8b2c1", ... },
  "plainTextKey": "lf_a3f8b2c1d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3"
}
```

**Copy the `plainTextKey` now — it is shown exactly once and cannot be recovered.**

Set it in your environment:
```bash
export LANDFALL_API_KEY="lf_a3f8b2c1d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3"
export LANDFALL_URL="http://localhost:8080"  # or your server's address
```

### 2. Push a card

```bash
curl -s -X POST $LANDFALL_URL/agent/pushCard \
  -H "Content-Type: application/json" \
  -d "{
    \"apiKey\": \"$LANDFALL_API_KEY\",
    \"request\": {
      \"__className__\": \"CardPushRequest\",
      \"source\":   \"agent.quickstart\",
      \"title\":    \"Hello from the Agent API\",
      \"body\":     \"Your first card is on the display.\",
      \"layout\":   \"medium\",
      \"priority\": \"normal\"
    }
  }" | python3 -m json.tool
```

The card appears on the display within 30 seconds.

---

## API Reference

**Base URL:** `http://<your-server>:8080`

All requests are `POST` with `Content-Type: application/json`. All responses are JSON.

### Key Management

#### `POST /apiKey/generateKey`

Generate a new API key.

**Body:**
```json
{ "name": "descriptive-name" }
```

**Response:**
```json
{
  "key": {
    "id": 1,
    "name": "descriptive-name",
    "prefix": "lf_a3f8b2c1",
    "createdAt": "2026-04-19T12:00:00.000Z",
    "dailyLimit": 500,
    "usageCount": 0
  },
  "plainTextKey": "lf_..."
}
```

`plainTextKey` is returned **once only**. Store it securely — it cannot be retrieved again.

---

#### `POST /apiKey/listKeys`

List all active (non-revoked) keys. Metadata only — no hashes or plaintext keys.

**Body:** `{}`

---

#### `POST /apiKey/revokeKey`

Revoke a key by its numeric ID. Takes effect immediately — in-flight requests using this key will be rejected.

**Body:**
```json
{ "id": 1 }
```

**Response:** `true` if revoked, `false` if not found or already revoked.

---

### Agent Endpoints

All agent endpoints require `"apiKey"` in the request body.

#### `POST /agent/pushCard`

Push a card to the display. If `externalId` matches an existing card, the card is updated in-place and un-dismissed.

**Body:**
```json
{
  "apiKey": "lf_...",
  "request": {
    "__className__": "CardPushRequest",
    "source":     "agent.myapp",
    "title":      "Card title",
    "body":       "Optional body text.",
    "layout":     "medium",
    "priority":   "normal",
    "externalId": "myapp.unique-slot-id"
  }
}
```

**Response:** The created or updated card row.

See [card-schema.md](card-schema.md) for all request fields and validation rules.

---

#### `POST /agent/updateCard`

Update an existing card by `externalId`. Throws if no card with that ID exists.

**Body:**
```json
{
  "apiKey": "lf_...",
  "externalId": "myapp.unique-slot-id",
  "request": {
    "__className__": "CardPushRequest",
    "source": "agent.myapp",
    "title":  "Updated title"
  }
}
```

---

#### `POST /agent/dismissCard`

Dismiss a card by `externalId`. The card is retained in the database for history.

**Body:**
```json
{
  "apiKey":     "lf_...",
  "externalId": "myapp.unique-slot-id"
}
```

**Response:** `true` if dismissed, `false` if not found.

---

#### `POST /agent/listCards`

Return all active (non-dismissed, non-expired) cards, newest first.

**Body:**
```json
{ "apiKey": "lf_..." }
```

---

## Rate Limits

Each API key has a daily push limit (default: **500 pushes/day**, reset at UTC midnight). `listCards`, `updateCard`, and `dismissCard` do not count against the limit.

If the limit is exceeded, the server returns an error with a message indicating the limit and reset time.

---

## Error Handling

All errors return a JSON object with a `"message"` field:

```json
{ "message": "Invalid card payload: title must not be empty." }
```

| Cause | Message pattern |
|---|---|
| Invalid or revoked API key | `"Invalid or revoked API key."` |
| Rate limit exceeded | `"Rate limit exceeded. Limit: 500, resets at <time>."` |
| Validation failure | `"Invalid card payload: <details>"` |
| Card not found | `"No card found with externalId \"<id>\"."` |

Your integration should treat any non-success response as a hard failure — Landfall does not silently drop cards.

---

## In-Place Updates

Use a stable `externalId` to update a card rather than accumulating duplicates. Pick an ID that reflects the "slot" the card occupies on your display:

```
agent.github.open-prs          # always shows current open PR count
agent.claude.daily-summary     # replaced each morning
skill.home_assistant.front-door  # live sensor state
```

Re-pushing with the same `externalId` replaces the card, resets its TTL, and clears any dismissal.

---

## Reference Integrations

### curl / Shell Script

The simplest possible integration — push a card from any shell script or cron job.

```bash
#!/usr/bin/env bash
# Push a card from a shell script.
# Requires: LANDFALL_API_KEY and LANDFALL_URL in environment.

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
  }"
```

A runnable demo is at [`tools/scripts/demo_push_card.sh`](../tools/scripts/demo_push_card.sh).

---

### Claude (Python)

Push a summary card after Claude completes a research task.

**File:** [`examples/claude_research.py`](examples/claude_research.py)

```python
#!/usr/bin/env python3
"""
Research a topic with Claude and push a summary card to Landfall.

Usage:
  python claude_research.py "What are the main risks of using LLMs in prod?"

Requires:
  pip install anthropic requests
  ANTHROPIC_API_KEY, LANDFALL_API_KEY, LANDFALL_URL in environment.
"""

import os
import sys
import json
import requests
import anthropic

LANDFALL_URL = os.environ["LANDFALL_URL"]
LANDFALL_API_KEY = os.environ["LANDFALL_API_KEY"]


def push_card(title: str, body: str, external_id: str) -> None:
    resp = requests.post(
        f"{LANDFALL_URL}/agent/pushCard",
        json={
            "apiKey": LANDFALL_API_KEY,
            "request": {
                "__className__": "CardPushRequest",
                "source": "agent.claude",
                "title": title,
                "body": body,
                "layout": "large",
                "priority": "normal",
                "externalId": external_id,
            },
        },
        timeout=10,
    )
    resp.raise_for_status()


def main():
    topic = " ".join(sys.argv[1:]) or "Summarize the current state of AI agents"

    client = anthropic.Anthropic()

    message = client.messages.create(
        model="claude-opus-4-7",
        max_tokens=300,
        system=(
            "You are a concise research assistant. "
            "Respond with a 2-3 sentence summary suitable for a display card. "
            "No markdown, no bullet points — plain prose only."
        ),
        messages=[{"role": "user", "content": topic}],
    )

    summary = message.content[0].text.strip()
    title = topic[:80] + ("..." if len(topic) > 80 else "")

    push_card(
        title=title,
        body=summary,
        external_id="agent.claude.research",
    )
    print(f"Card pushed: {title}")


if __name__ == "__main__":
    main()
```

---

### n8n / Make Webhook

Push a card from an n8n workflow or Make scenario using an HTTP Request node.

**n8n HTTP Request node config:**

| Setting | Value |
|---|---|
| Method | POST |
| URL | `{{ $env.LANDFALL_URL }}/agent/pushCard` |
| Authentication | None (API key in body) |
| Body Content Type | JSON |

**Body (JSON):**
```json
{
  "apiKey": "={{ $env.LANDFALL_API_KEY }}",
  "request": {
    "__className__": "CardPushRequest",
    "source": "agent.n8n",
    "title": "={{ $json.title }}",
    "body": "={{ $json.body }}",
    "layout": "medium",
    "priority": "normal",
    "externalId": "={{ 'agent.n8n.' + $json.workflow_id }}"
  }
}
```

Store `LANDFALL_URL` and `LANDFALL_API_KEY` as n8n credentials (Env vars). The `externalId` uses the workflow ID so each workflow owns a stable card slot.

A full importable workflow is at [`examples/n8n_workflow.json`](examples/n8n_workflow.json).

---

### Home Assistant

Push a card when a sensor fires — e.g. front door opened, motion detected, or a threshold crossed.

**`configuration.yaml` — shell command:**
```yaml
shell_command:
  push_landfall_card: >
    curl -sf -X POST $LANDFALL_URL/agent/pushCard
    -H "Content-Type: application/json"
    -d "{
      \"apiKey\": \"$LANDFALL_API_KEY\",
      \"request\": {
        \"__className__\": \"CardPushRequest\",
        \"source\": \"skill.home_assistant\",
        \"title\": \"{{ title }}\",
        \"body\": \"{{ body }}\",
        \"layout\": \"small\",
        \"priority\": \"ephemeral\",
        \"externalId\": \"skill.home_assistant.{{ entity_id }}\"
      }
    }"
```

Set `LANDFALL_URL` and `LANDFALL_API_KEY` in your Home Assistant environment (via `.env` file or the Secrets integration).

**`automations.yaml` — front door alert:**
```yaml
- alias: "Landfall: Front door opened"
  trigger:
    - platform: state
      entity_id: binary_sensor.front_door
      to: "on"
  action:
    - service: shell_command.push_landfall_card
      data:
        title: "Front door opened"
        body: "{{ now().strftime('%H:%M') }}"
        entity_id: "front_door"
```

The `externalId` uses the entity ID, so each sensor owns one stable card slot — a repeated trigger updates the existing card rather than stacking new ones.

A full example with multiple sensors is at [`examples/home_assistant.yaml`](examples/home_assistant.yaml).

---

## Publishing Your Integration

Built something useful? Submit it to the [integration registry](integrations.md) via pull request. Include:

- A short description (1–2 lines)
- Your `source` namespace (e.g. `skill.myapp`)
- Link to your repo or gist

---

## See Also

- [Card Schema Spec](card-schema.md) — all fields, validation rules, TTL behavior
- [Self-Hosting Guide](self_hosting_guide.md) — run your own Landfall server
- [examples/](examples/) — runnable code for all reference integrations
