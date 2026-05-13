# Security Policy

## Supported versions

Landfall is in alpha. Only the latest commit on `main` is supported. Older
tags do not receive security patches.

## Reporting a vulnerability

If you find a security issue, please report it privately rather than opening
a public GitHub issue.

- Email: `evanpthompson@gmail.com` with subject `[Landfall Security]`
- Or open a private security advisory via GitHub's "Report a vulnerability"
  button on the repository's Security tab

Please include:

- A description of the issue and its impact
- Steps to reproduce (or a proof-of-concept)
- The commit SHA you tested against
- Any suggested remediation, if you have one

We aim to acknowledge reports within 72 hours and to ship a fix or
mitigation within 30 days for critical issues. Coordinated disclosure is
preferred — please do not publish details before a fix is available.

## Scope

In scope:

- The Flutter display app (`apps/display/`)
- The Serverpod backend (`server/landfall_server/`)
- The agent SDK (`packages/agent_sdk/`) and shared models
- The REST agent API, the MCP server, and the OAuth callback routes
- The Docker Compose and pi-gen deployment recipes (`deploy/`)

Out of scope:

- Third-party dependencies — please report upstream
- Issues that require a hostile local user with shell access to the device
- Self-host operator misconfiguration (e.g., exposing internal-only ports)
- Denial of service that depends on exhausting host resources

## Hardening status

Landfall has gone through a structured OWASP Top 10 hardening pass.
See [`docs/`](docs/) for guides; security architecture is documented in the
project's architecture decisions record.
