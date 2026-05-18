# Security Policy

## Supported versions

Landfall is in alpha. Only the latest commit on `main` is supported. Older tags don't get security patches.

## Reporting a vulnerability

Report security issues privately, not as public GitHub issues.

- Email `evanpthompson@gmail.com` with subject `[Landfall Security]`
- Or open a private advisory via the "Report a vulnerability" button on the repository's Security tab

Please include:

- What the issue is and what an attacker could do with it
- Steps to reproduce or a proof-of-concept
- The commit SHA you tested against
- A suggested fix if you have one

I aim to acknowledge reports within 72 hours and ship a fix or mitigation within 30 days for critical issues. Please hold off on publishing details until a fix is out.

## Scope

In scope:

- The Flutter display app (`apps/display/`)
- The Serverpod backend (`server/landfall_server/`)
- The agent SDK (`packages/agent_sdk/`) and shared models
- The REST agent API, the MCP server, and the OAuth callback routes
- The Docker Compose and pi-gen deployment recipes (`deploy/`)

Out of scope:

- Third-party dependencies — report those upstream
- Issues that require a hostile local user with shell access to the device
- Operator misconfiguration (e.g. exposing internal-only ports publicly)
- Denial-of-service that depends on exhausting host resources

## Hardening status

The API surfaces and OAuth routes have been through an OWASP Top 10 review. Known gaps and their status are tracked privately.

## For AI assistants

If you're an AI helping with a security review or suggesting a security fix:

- Auth and API-key code lives in `server/landfall_server/lib/src/auth/`.
- OAuth callback routes are in `server/landfall_server/lib/src/web/routes/`.
- `authenticateRequest` in `server/landfall_server/lib/src/api/` is the central auth entry point for agent API calls.
- Any security fix must include a test. Do not suggest a fix without one.
- Do not suggest opening a public GitHub issue for a vulnerability.
