# Landfall Documentation Index

The canonical map of every doc in the repo. If you add a new doc, add it here in the same commit — see [CLAUDE.md](../CLAUDE.md) for the rule.

## Start here

- [Project README](../README.md) — what Landfall is, REST API, monorepo layout
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
- [Manual smoke test](manual_smoke_test.md) — runnable cold checklist for a build
- [Beta launch checklist](beta_launch_checklist.md) — pre-flight before public beta image

## For agent integrators

- [Agent integration guide](agent_integration_guide.md) — pushing cards from any agent or automation
- [MCP setup guide](mcp_setup_guide.md) — connect Claude Desktop / Cursor / any MCP agent
- [Integrations registry](integrations.md) — community integrations directory
- [Agent SDK README](../packages/agent_sdk/README.md) — Dart SDK (`landfall_agent_sdk`)
- [Agent SDK changelog](../packages/agent_sdk/CHANGELOG.md)

## For theme authors

- [Theme submission guide](theme-submission-guide.md) — write, submit, and earn from a theme
- [Theme marketplace launch (draft blog)](blog-theme-marketplace-launch.md) — narrative walkthrough
- [Themes directory README](../themes/README.md) — community + marketplace YAML themes

## Schemas and design

- [Card schema](card-schema.md) — the Card model
- [Theme schema](theme-schema.md) — Theme tokens
- [Layout schema](layout-schema.md) — Layout schema
- [Companion card design](companion_card_design.md) — companion UX

## Developer reference

- [Build defines](build_defines.md) — `--dart-define` reference
- [Dependency policy](dependency_policy.md) — pubspec and lock-file rules
- [End-to-end test plan](e2e-test-plan.md) — authoritative E2E task list
- [Control app plan](control_app_plan.md) — sibling Flutter app (`apps/control/`) for setup, settings, API keys, themes; web-first, deferred mobile/desktop builds
- [Roadmap](roadmap.md) — deferred follow-ups, post-beta plans, blockers

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
