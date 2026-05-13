# Landfall

**Alpha** · The ambient display layer for the agentic era.

Landfall is an open-source, self-hosted platform that makes your AI-assisted life visible. A beautiful ambient display for your home — calendar, weather, photos, clock — running on macOS, Raspberry Pi, or Fire TV. And the place where agent output lands instead of disappearing into chat windows.

> **Project status:** Alpha. Expect breaking changes between commits. Run for fun, file bugs, hold off on production deployments.

## What it does

- Displays a live family dashboard: clock, weather, calendar, photos
- Exposes a **REST API** — any agent, automation, or script can push cards over plain HTTP
- Exposes an **MCP server** — AI agents with MCP support (Claude Desktop, Cursor) can push cards natively
- Exposes a **Dart SDK** (`packages/agent_sdk`) for native Dart/Flutter agent integration
- Self-hosted: your data stays on your server

## REST API

Push cards from any language or tool. Authenticate with `Authorization: Bearer <api_key>`.

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
themes/                   # Community and marketplace themes (YAML)
deploy/                   # Docker Compose, Pi image build, Fire TV scripts
site/                     # Static landing page
infra/                    # OpenTofu infrastructure (DigitalOcean)
tools/                    # Build and utility scripts
docs/                     # Architecture decisions, guides
```

## Getting started

Landfall is self-host first for alpha. Start with the Docker server and a Fire TV/Android display:

- [Self-hosting guide](docs/self_hosting_guide.md) - recommended server path
- [Fire TV guide](docs/fire_tv_guide.md) - APK build/sideload path
- [Raspberry Pi guide](docs/raspberry_pi_guide.md) - alpha all-in-one appliance image and manual Pi setup
- [Debugging a Pi image](docs/debugging_pi.md) - build a maximally-debuggable Pi (SSH + dev telemetry baked in)
- [Updating a Pi](docs/updating.md) - default beta path is build a new image + restore data; advanced in-place server/display updates documented as edge cases
- [Roadmap](docs/roadmap.md) - deferred follow-ups, post-beta plans, decisions blocking work
- [Deployment validation](docs/deployment_validation.md) - checks to run before long image builds

## Agent integration

See [docs/agent_integration_guide.md](docs/agent_integration_guide.md) for pushing cards from any agent or automation.

## Contributing

PRs and bug reports welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).
For security issues, please follow the private disclosure process in [SECURITY.md](SECURITY.md).

## License

MIT — see [LICENSE](LICENSE).
