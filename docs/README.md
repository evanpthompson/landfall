# Landfall Documentation Index

Every doc in the repo, in one place. Add a new `.md` file anywhere and it goes here in the same commit — see [CLAUDE.md](../CLAUDE.md) for why.

## Start here

- [Project README](../README.md) — what Landfall is, REST API, monorepo layout
- [Community](community.md) — GitHub Discussions, issue templates, where to ask for help
- [CONTRIBUTING](../CONTRIBUTING.md) — how to propose changes
- [SECURITY](../SECURITY.md) — private disclosure process for security issues
- [CLAUDE.md](../CLAUDE.md) — TDD rules and commit discipline (also applies to humans)

## For operators (self-hosting & devices)

- [Self-hosting guide](self_hosting_guide.md) — recommended Docker server path
- [Raspberry Pi guide](raspberry_pi_guide.md) — alpha appliance image and manual Pi setup
- [Fire TV guide](fire_tv_guide.md) — APK build and sideload
- [macOS local dev](macos_local_dev.md) — run the full stack on a Mac, no Pi required
- [Debugging a Pi image](debugging_pi.md) — SSH + dev telemetry baked in
- [Pi dev workflow](pi_dev_workflow.md) — hot reload against a live Pi server
- [Updating a Pi](updating.md) — default new-image path plus in-place edge cases
- [Deployment validation](deployment_validation.md) — checks before long image builds
- [Manual smoke test](manual_smoke_test.md) — runnable cold checklist for a build (release gate)
- [End-to-end feature test](e2e_feature_test.md) — exhaustive feature-by-feature regression sweep
- [Beta known limitations](beta_known_limitations.md) — intentionally-deferred items, workflows, and pointers to future work

## For agent integrators

- [Agent integration guide](agent_integration_guide.md) — pushing cards from any agent or automation
- [MCP setup guide](mcp_setup_guide.md) — connect Claude Desktop / Cursor / any MCP agent
- [Integrations registry](integrations.md) — community integrations directory
- [Agent SDK README](../packages/agent_sdk/README.md) — Dart SDK (`landfall_agent_sdk`)
- [Agent SDK changelog](../packages/agent_sdk/CHANGELOG.md)

## For theme authors

- [Themes directory README](../themes/README.md) — where community theme YAMLs live

## Schemas and design

- [Card schema](card-schema.md) — the Card model
- [Theme schema](theme-schema.md) — Theme tokens
- [Layout schema](layout-schema.md) — Layout schema

## Developer reference

- [Build defines](build_defines.md) — `--dart-define` reference
- [Dependency policy](dependency_policy.md) — pubspec and lock-file rules
- [Roadmap](roadmap.md) — near-term scoped work
- [Fire TV remote navigation plan](firetv_remote_nav_plan.md) — beta-scope phased plan for D-pad + remote-only UX

## Package READMEs

- [apps/display](../apps/display/README.md) — Flutter client (Fire TV, Android, Pi, macOS)
- [apps/display integration tests](../apps/display/integration_test/README.md)
- [server/landfall_server](../server/landfall_server/README.md) — Serverpod backend
- [server/landfall_server changelog](../server/landfall_server/CHANGELOG.md)
- [server/landfall_client](../server/landfall_client/README.md) — generated client
- [server/landfall_client endpoint reference](../server/landfall_client/doc/endpoint.md)
- [server/landfall_client changelog](../server/landfall_client/CHANGELOG.md)

## Repo infrastructure

- [.github/workflows README](../.github/workflows/README.md) — CI workflows
- [Pull request template](../.github/PULL_REQUEST_TEMPLATE.md)
- [Bug report template](../.github/ISSUE_TEMPLATE/bug_report.md)
- [Feature request template](../.github/ISSUE_TEMPLATE/feature_request.md)

## For AI assistants

This index is the right place to start when navigating the repo. A few things worth knowing:

- `docs/README.md` (this file) must be updated in the same commit as any `.md` add, rename, move, or delete anywhere in the repo.
- For setup help, start with [self_hosting_guide.md](self_hosting_guide.md) (Docker) or [raspberry_pi_guide.md](raspberry_pi_guide.md) (Pi image).
- For agent integration questions, [agent_integration_guide.md](agent_integration_guide.md) covers REST, MCP, and the Dart SDK with copy-paste examples.
- For server-side code questions, the Serverpod backend is at `server/landfall_server/`. Schema changes are in `server/landfall_server/lib/src/generated/` and are fatal on mismatch — always regenerate the client after changing endpoints.
- Card and theme schemas are machine-readable: [card-schema.md](card-schema.md), [theme-schema.md](theme-schema.md), [layout-schema.md](layout-schema.md).
