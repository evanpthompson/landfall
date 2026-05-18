# Landfall MCP Server Setup Guide

Connect Landfall to Claude Desktop, Cursor, or any MCP-compatible agent so it can push cards directly to your display.

---

## What This Gives You

Once configured, your AI agent can call five tools:

| Tool | What it does |
|---|---|
| `push_card` | Push (or update) a card on the display |
| `update_card` | Update an existing card by ID |
| `dismiss_card` | Remove a card from the display |
| `get_cards` | List everything currently showing |
| `get_display_status` | Check server connectivity and card inventory |

Two readable resources are also available:

| Resource | Contents |
|---|---|
| `landfall://cards` | All active cards, full detail |
| `landfall://status` | Server health + active source namespaces |

---

## Prerequisites

- Dart SDK 3.8+ installed (`dart --version`)
- A running Landfall server (local or remote)
- An API key (see below)

---

## Step 1 — Generate an API Key

Replace `your-server` with the hostname or IP of your Landfall server (e.g. `192.168.1.42` or `landfall.local`). The `API_KEY_MANAGEMENT_TOKEN` value is in your `deploy/.env` file.

```bash
curl -s -X POST http://your-server:8080/apiKey/generateKey \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <API_KEY_MANAGEMENT_TOKEN>" \
  -d '{"name": "claude-desktop"}' \
  | python3 -m json.tool
```

Copy the `plainTextKey` — it is shown exactly once.

---

## Step 2 — Build the MCP Server Binary

From the repo root:

```bash
dart compile exe server/landfall_mcp/bin/landfall_mcp.dart \
  -o server/landfall_mcp/bin/landfall_mcp
```

This produces a self-contained binary. If `dart` is not found, install the Dart SDK from [dart.dev/get-dart](https://dart.dev/get-dart) (version 3.8+; check with `dart --version`).

Or run directly with `dart run` if you prefer not to compile:

```bash
dart run server/landfall_mcp/bin/landfall_mcp.dart
```

---

## Step 3 — Configure Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or
`%APPDATA%\Claude\claude_desktop_config.json` (Windows):

The `command` field must be an **absolute path** — Claude Desktop does not resolve relative paths or `~`. To get the correct path, run `pwd` in the repo root and append `/server/landfall_mcp/bin/landfall_mcp`.

```json
{
  "mcpServers": {
    "landfall": {
      "command": "/absolute/path/to/server/landfall_mcp/bin/landfall_mcp",
      "env": {
        "LANDFALL_URL": "http://your-server:8080",
        "LANDFALL_API_KEY": "lf_..."
      }
    }
  }
}
```

If running via `dart run` instead of a compiled binary:

```json
{
  "mcpServers": {
    "landfall": {
      "command": "dart",
      "args": ["/absolute/path/to/server/landfall_mcp/bin/landfall_mcp.dart"],
      "env": {
        "LANDFALL_URL": "http://your-server:8080",
        "LANDFALL_API_KEY": "lf_..."
      }
    }
  }
}
```

Restart Claude Desktop after editing the config.

---

## Step 4 — Configure Cursor

Add to your Cursor MCP settings (`.cursor/mcp.json` in your project, or the global Cursor config at `~/.cursor/mcp.json`). The `command` field must be an absolute path, same as Step 3.

```json
{
  "mcpServers": {
    "landfall": {
      "command": "/absolute/path/to/server/landfall_mcp/bin/landfall_mcp",
      "env": {
        "LANDFALL_URL": "http://your-server:8080",
        "LANDFALL_API_KEY": "lf_..."
      }
    }
  }
}
```

---

## Step 5 — Verify

In Claude Desktop, open a new conversation and ask:

> "What's on my Landfall display right now?"

Claude will call `get_display_status` and report back. If the server is unreachable it will say so — check `LANDFALL_URL` and that the server is running.

---

## Usage Examples

**Push a summary card after a research task:**

> "Research the latest developments in MCP and push a summary card to my display with source 'agent.claude', a descriptive title, and a 2-sentence body."

**Keep a card updated:**

> "Push a card with externalId 'agent.claude.daily-focus' and update it each time I ask you to set my focus for the day."

**Dismiss a card:**

> "Dismiss the card with externalId 'agent.claude.daily-focus'."

**Check what's showing:**

> "List everything currently on my Landfall display."

---

## Troubleshooting

**Server starts but tools fail immediately**

Check that `LANDFALL_URL` is reachable from the machine running Claude Desktop:
```bash
curl http://your-server:8080/agent/listCards \
  -H "Content-Type: application/json" \
  -d '{"apiKey": "lf_..."}'
```

**"Invalid or revoked API key"**

The key may have been revoked. Generate a new one (Step 1) and update the config.

**MCP server doesn't appear in Claude Desktop**

- Confirm the path in `command` is absolute and the binary is executable
- Check Claude Desktop logs: `~/Library/Logs/Claude/` on macOS
- Try `dart run` instead of the compiled binary to rule out build issues

**Cards don't appear on the display**

The display polls every 30 seconds. Either wait for the next cycle or restart the display app.

---

## Security Notes

- The API key authenticates the MCP server to Landfall. Treat it like a password.
- The key is stored in the MCP config file — ensure that file is not world-readable.
- To rotate the key: generate a new one, update the config, then revoke the old one via `POST /apiKey/revokeKey`.
- The MCP server process has no network access beyond the Landfall API — it does not make any other outbound connections.

---

## For AI assistants

Key facts for helping users configure and use the Landfall MCP server:

- **Binary path must be absolute** in Claude Desktop / Cursor config. `~` and relative paths are not resolved. Get the correct path with `pwd` in the repo root and append `/server/landfall_mcp/bin/landfall_mcp`.
- **Two startup options:** compiled binary (`dart compile exe`) or `dart run`. Use `dart run` to rule out binary build issues during troubleshooting.
- **MCP tools available:** `push_card`, `update_card`, `dismiss_card`, `get_cards`, `get_display_status`. Two readable resources: `landfall://cards`, `landfall://status`.
- **API key** goes in `env.LANDFALL_API_KEY` in the MCP config. It's the same key used for the REST API — generated via `POST /apiKey/generateKey` with the management token from `deploy/.env`.
- **Cards appear on the next 30-second poll** — not instant. If a card doesn't show up immediately, wait up to 30 seconds before concluding something is broken.
- **Claude Desktop logs:** `~/Library/Logs/Claude/` on macOS. Check here first if the MCP server doesn't appear in Claude Desktop.
- **`LANDFALL_URL`** in the MCP config should be `http://<server>:8080` — the API port. Not `:8082` (web server) and not a trailing slash required.

## See Also

- [Card Schema Spec](card-schema.md)
- [Agent Integration Guide](agent_integration_guide.md) — REST API, curl, n8n, Home Assistant
