# Landfall

**The ambient display layer for the agentic era.**

Landfall is an open-source, self-hosted platform that makes your AI-assisted life visible. A beautiful ambient display for your home — calendar, weather, photos, clock — running on Fire TV or any Android device. And the place where agent output lands instead of disappearing into chat windows.

## What it does

- Displays a live family dashboard: clock, weather, calendar, photos
- Exposes an Agent API — any agent, automation, or script can push cards to the display
- Exposes an MCP server — AI agents with MCP support (Claude Desktop, Cursor) can push cards natively
- Self-hosted: your data stays on your server

## Monorepo structure

```
apps/display/             # Flutter client (Fire TV, Android)
server/landfall_server/   # Serverpod backend
server/landfall_client/   # Generated Serverpod client
packages/landfall_shared/ # Shared Dart models
packages/ui_kit/          # Design system
infra/                    # OpenTofu infrastructure (DigitalOcean)
docs/                     # Architecture decisions, guides
```

## Getting started

See [docs/self_hosting_guide.md](docs/self_hosting_guide.md) for self-hosting instructions.

## Agent integration

See [docs/agent_integration_guide.md](docs/agent_integration_guide.md) for pushing cards from any agent or automation.

## License

MIT — see [LICENSE](LICENSE).
