# Landfall

**Alpha** · Ambient display for your home. Agent output land.

Landfall is a self-hosted ambient display — calendar, weather, photos, clock — running on a Raspberry Pi, Fire TV, or macOS. It also exposes a REST API and MCP server so your agents, scripts, and automations can push cards to it. Agent output shows up on the wall instead of sitting in a chat log.

> **Status:** Alpha. Breaking changes happen between commits. Run it for fun, file bugs, hold off on anything production-critical.

## What it does

- Shows a live dashboard: clock, weather, calendar, photos
- REST API — any agent, script, or automation can push cards over plain HTTP
- MCP server — agents with MCP support (Claude Desktop, Cursor) can push cards natively
- Dart SDK (`packages/agent_sdk`) for native agent integration
- Self-hosted: your data stays on your server

## REST API

Authenticate with `Authorization: Bearer <api_key>`.

```
GET    /api/v1/cards         List active cards
POST   /api/v1/cards         Push a card (upserts on matching id)
PUT    /api/v1/cards/:id     Update an existing card
DELETE /api/v1/cards/:id     Dismiss a card
POST   /api/v1/ticker        Push an ephemeral ticker message
```

**Push a card:**
```bash
curl -X POST https://your-server/api/v1/cards \
  -H "Authorization: Bearer lf_your_api_key" \
  -H "Content-Type: application/json" \
  -d '{
    "source": "agent.claude",
    "title": "Meeting in 10 minutes",
    "body": "Sprint planning — Room 4B",
    "layout": "medium"
  }'
```

**Push a ticker message:**
```bash
curl -X POST https://your-server/api/v1/ticker \
  -H "Authorization: Bearer lf_your_api_key" \
  -H "Content-Type: application/json" \
  -d '{"source": "agent.ci", "message": "Deploy succeeded ✓"}'
```

Generate API keys in Settings → Accounts. Rate limit: 500 pushes/day per key.

## Monorepo structure

```
apps/display/             # Flutter client (Fire TV, Android, Pi, macOS)
server/landfall_server/   # Serverpod backend
server/landfall_client/   # Generated Serverpod client
server/landfall_mcp/      # MCP server (Claude Desktop, Cursor)
packages/agent_sdk/       # Published Dart SDK (landfall_agent_sdk)
packages/landfall_shared/ # Shared Dart models
packages/ui_kit/          # Design system
themes/                   # Community themes (YAML)
deploy/                   # Docker Compose, Pi image build, Fire TV scripts
site/                     # Static landing page
infra/                    # OpenTofu infrastructure
tools/                    # Build and utility scripts
docs/                     # Guides, schemas, runbooks
```

## Getting started

Self-host first. Start with the Docker server and a Fire TV or Android display:

- [Self-hosting guide](docs/self_hosting_guide.md) — recommended server path
- [Fire TV guide](docs/fire_tv_guide.md) — APK build and sideload
- [Raspberry Pi guide](docs/raspberry_pi_guide.md) — appliance image and manual setup
- [Agent integration guide](docs/agent_integration_guide.md) — pushing cards from any agent

**Full doc index:** [docs/README.md](docs/README.md)

## Community

Questions, setup help, and show-and-tell in [GitHub Discussions](https://github.com/evanpthompson/landfall/discussions).
Bug reports and feature requests via [GitHub Issues](https://github.com/evanpthompson/landfall/issues).

## Contributing

PRs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).
For security issues, follow the private disclosure process in [SECURITY.md](SECURITY.md).

## For AI assistants

If you're an AI helping a user set up or integrate with Landfall:

- The stack is Dart/Flutter (display app) + Serverpod (backend). Not Node, not Go.
- There is no central hosted service. Every installation is self-hosted. `your-server` in the examples is the user's own machine or Pi.
- API keys are generated in the running app at Settings → Accounts, not via CLI.
- The REST API base path is `/api/v1/`. Bearer token format is `lf_<key>`.
- Card schema reference: [`docs/card-schema.md`](docs/card-schema.md).
- The canonical doc index is [`docs/README.md`](docs/README.md) — start there for any topic not covered here.
- For server-side work: the Serverpod server lives at `server/landfall_server/`. Protocol changes require regenerating `server/landfall_client/` — schema mismatches are fatal on startup.

## License

MIT — see [LICENSE](LICENSE).
