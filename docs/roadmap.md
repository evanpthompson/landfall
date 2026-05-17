# Landfall Roadmap

Things known to be deferred, with the reason and the rough trigger for picking
them up. Items here are intentionally not blockers for beta — they're either
post-beta scope, follow-ups to features that shipped in a minimal form, or
require product decisions before engineering work makes sense.

Status legend:

- 🟢 **Ready to start** — design + product decisions are made, just needs engineering time.
- 🟡 **Needs design** — engineering knows what to do but design / UX work is required first.
- 🔴 **Needs decision** — product or policy decisions are blocking implementation.

---

## Pre-beta blockers

Items that must land before beta. Unlike the rest of this file these are not
deferred — they are concrete work with known implementations.

### ✅ Remove `/app` route (no real web UI yet) — DONE

The Serverpod scaffold registered `/app/*` and `/app/assets/assets/config.json`
to serve a Flutter web admin UI that doesn't exist in this project. The only
Flutter web build we produce is the companion bundle, which is served at
`/c/<displayId>/` by `CompanionPageRoute` (with display-ID injection). Routing
`/app/*` to the same bundle would serve a half-broken UI with no injected
display ID and confuse anyone who opened the URL.

Resolution: removed the `/app/*` Serverpod routes, the matching Caddyfile
reverse-proxy line, and `AppConfigRoute`. Regression guard at
`deploy/tests/test_app_route_absent.sh`. The real web admin UI is a separate
post-beta phase — see "Web admin UI" under "Bigger features" below.

### ✅ Push-server deploy script — DONE

Shipped as `deploy/scripts/push-server.sh` with `--platform linux/arm64`
enforced. Tests in `deploy/scripts/test_push_server.sh`; documented in
[`docs/updating.md`](updating.md#in-place-server-only-update-fast-path).

### 🟢 Google OAuth permanent setup (replace ngrok + setup token)

The setup token bypass added tonight was a one-time workaround. The permanent
fix has two parts:

1. **Real domain as redirect URI.** Register
   `https://<real-domain>/calendar/oauth/callback` in Google Console (e.g.
   `makefastlandfall.dev`). Update Pi `.env` `GOOGLE_REDIRECT_URI` to match.
   With a real domain, the `/app` web UI (once the base-href is fixed) lets
   users sign in normally — no setup token needed.

2. **Self-hoster documentation.** Write `docs/google-integration-setup.md`
   covering: create a Google Cloud project, enable Calendar + Drive APIs,
   create an OAuth client (Web application), register the redirect URI as
   `https://<LANDFALL_DOMAIN>/calendar/oauth/callback`, set the three env
   vars. This is the standard self-hosted pattern (Home Assistant, Nextcloud,
   etc.) — each installer uses their own credentials.

The `calendarOauthSetupToken` feature can stay in the codebase as a safety
valve for `.local` / IP-only installs, but it should not be the documented
primary path.

### ✅ Google Drive photos — service account (replace OAuth) — DONE

Service account path shipped. `GoogleServiceAccountAuth` mints self-signed
JWTs (RS256, pointycastle) and exchanges them for access tokens via the
`urn:ietf:params:oauth:grant-type:jwt-bearer` grant.
`GoogleDriveServiceAccountPhotoService` is a parallel `PhotoService`
implementation; `photoServiceFor()` picks the right one based on
`LinkedCredential.provider` (`google-sa` vs `google`). OAuth path is
preserved as a fallback — see [architecture decision §27](../../files/automation/landfall/architecture_decisions.md#27-google-drive-photos--service-account-not-user-oauth)
for the full rationale and migration story.

Backlog follow-up: "Re-link card UI for failed credentials" is now optional
for Google Drive photos (service account credentials don't expire). Still
useful for Microsoft Calendar OAuth.

### ✅ UUID format alignment (`authUserId`) — DONE

Three call sites (`settings_endpoint.dart`, `calendar_oauth_route.dart`,
`microsoft_calendar_oauth_route.dart`) now all call a single canonical
function `authUserIdFromIdentifier` in `lib/src/auth/auth_user_id.dart`.
Canonical format is RFC 4122 v4 (`00000000-0000-4000-8000-<padded>`) —
matches what's already in the database. Already-UUID inputs are returned
verbatim, so Serverpod's newer UUID-based auth path also works. Unit tests
at `test/unit/auth/auth_user_id_test.dart`.

---

## Integration expansion (pre-beta planning)

### 🔴 Evaluate and expand photo + calendar integrations

Before locking the integration surface for beta, decide which additional
providers to support and in what priority order. The goal is both broader
coverage and higher-quality options than the current Google-only story.

**Calendar candidates to evaluate**:

| Provider | Protocol | Notes |
|---|---|---|
| Apple Calendar / iCloud | CalDAV | Self-hosted friendly; works without Apple ID if calendar is CalDAV-exported |
| Nextcloud Calendar | CalDAV | Natural fit — many Landfall users may already self-host Nextcloud |
| Exchange / Outlook (direct) | EWS or Graph API | Already have Microsoft OAuth stub; Graph is the clean path |
| CalDAV (generic) | CalDAV | One implementation covers Nextcloud, Radicale, Baikal, Fastmail, Proton |
| Local `.ics` file | iCal file | Zero-auth; user drops a file or provides a URL |

A single CalDAV implementation would cover Nextcloud, iCloud, Fastmail,
Proton, and any self-hosted CalDAV server — higher value-per-line-of-code
than adding each provider individually.

**Photo candidates to evaluate**:

| Provider | Notes |
|---|---|
| Local folder / NAS (SMB/NFS) | Zero cloud dependency; natural for self-hosters with a NAS |
| Immich | Self-hosted photo library, REST API, growing community |
| Nextcloud Photos | Same credentials as Nextcloud Calendar; WebDAV or API |
| Apple Photos (iCloud shared album) | Public shared album URLs are stable; no auth needed |
| Flickr | Public album URL; API or RSS feed |
| Local SD card / USB | Purely offline option for air-gapped installs |

**Decisions to make before implementing**:
- Which providers are in-scope for beta vs. post-beta?
- Do we implement CalDAV as a generic provider and let users configure the
  server URL, or do we have named presets (Nextcloud, iCloud, etc.)?
- For local/NAS photos: does the Pi mount the share, or does the user point
  to a folder that is already mounted?
- For Immich: does it warrant a first-class integration (dedicated card type,
  album picker UI) or a generic "photo feed URL" approach?

---

## Reliability / self-healing follow-ups

These are direct follow-ups to the Tier 1–3 operator tooling that shipped in
the beta-prep work. Each one has a minimal-viable version already in place; the
items here are the richer next step.

### 🟢 Crash-bundle auto-ship

**Trigger:** the first time we get a Pi field report we can't diagnose from
the existing telemetry events alone.

Today the Pi posts a `display_crash_loop` telemetry event when the openbox
autostart trips its 3-fast-crash threshold. That tells us **when** but not
**why** — the full diagnostic context (journal tails, compose state, GL info)
lives in the `landfall-bug-report` bundle which still has to be pulled off
the Pi manually.

**Plan**:

1. New server endpoint `POST /api/v1/telemetry/crash` that accepts a multipart
   upload of the `.tgz` bundle. Auth via the same `authenticateRequest` flow
   as `/api/v1/telemetry/event`.
2. Server stores bundles in a Docker named volume (`landfall_crash_bundles`)
   with a ring-buffer cap (last 50 bundles or 500 MB, whichever is hit first).
3. The Pi's autostart crash path (currently in `00-run.sh`) calls
   `landfall-bug-report --auto-ship` after the existing telemetry event fires.
4. `landfall-bug-report --auto-ship` reads `LANDFALL_TELEMETRY_ENDPOINT` from
   `.env`, derives the bundle endpoint, and POSTs. Empty endpoint → no-op.

**Constraints to think through during implementation**:

- Bundle sizes can be 1–5 MB. Make sure the rate limit on the route is
  generous enough not to drop the bundle that matters most.
- Compression already happens client-side (the `.tgz` is gzipped); don't
  double-compress server-side.
- Dev-build-only must still hold: the entire ship path must be gated on
  `LANDFALL_TELEMETRY_ENDPOINT` being non-empty in the runtime `.env`.

### 🟡 Re-link card UI for failed credentials

**Trigger:** beta users start losing Google/Microsoft calendar data
silently. Or: someone explicitly asks "why did my calendar stop?"

The server already emits a structured `LANDFALL_CREDENTIAL_REFRESH_FAILED`
marker when a token refresh fails (Phase 3.5). `landfall-doctor` parses it.
But the display **shows nothing** to a non-SSH user — calendar/photo cards
just go quietly stale.

**Plan**:

1. Schema additions to `LinkedCredential`:
   - `consecutiveRefreshFailures: int, default=0`
   - `lastRefreshErrorAt: DateTime?`
   - `lastRefreshErrorKind: String?` (e.g. `revoked`, `network`, `unknown`)
2. `CalendarRefreshCall` increments on failure, resets on success.
3. When `consecutiveRefreshFailures >= 3`, push a system card with action
   `openUrl` → the existing OAuth start URL for that provider. The user
   scans the QR or opens the link on their phone to re-grant consent.
4. Display: clear the card automatically once the credential resyncs OK
   (the next successful refresh emits a "card_dismiss" event for that
   credential's card source).

**Design questions before coding**:

- What does the card *say*? "Google calendar disconnected. Tap to reconnect."?
- Should it be persistent or expiring? Persistent — silent failure is worse
  than a slightly-too-visible nudge.
- Per-credential or grouped? Per-credential, with the email address visible.
  Multiple Google accounts is a real case.

### 🟡 Health admin card (in-display diagnostics)

**Trigger:** operators ask "how's the Pi doing?" without wanting to SSH.

Adds a Health card type that fetches from a new
`GET /api/v1/health/summary` endpoint and renders the most useful subset of
`landfall-doctor`'s output: uptime, server status, integration health,
recent crashes. Card is hidden by default and shows up in the Card Library
once it lands.

**Why deferred**: the operator already has `landfall-doctor` over SSH and
the diagnostic fallback screen on real failures. A pretty in-display health
card is nice-to-have for non-technical operators, not a blocker.

---

## Update path

### 🔴 OTA updates

**Trigger:** post-beta. Until decided, every update is a manual procedure
documented in [`docs/updating.md`](updating.md).

**Decisions blocking implementation:**

1. **Signing key custody.** Whoever holds the release private key can push
   code to every Pi in the wild. Hardware-backed storage (Yubikey / HSM)?
   Single-person vs. quorum sign-off? Rotation cadence?
2. **A/B partitioning.** The current pi-gen image layout doesn't have a B
   partition. Adding one means re-designing how `/boot/firmware/` and the
   root fs map to physical partitions. The alternative (in-place update +
   `apt`-style rollback) trades complexity for risk — bad update = bricked
   Pi, with no remote recovery.
3. **Release infrastructure.** Where do signed image manifests live? Static
   bucket + CDN? Self-hosted? What's the SLA?
4. **Rollback policy.** What does the Pi do on the third failed boot of a
   new image? Auto-fall-back to B partition? Stay broken and show the
   diagnostic screen with a manual recovery path?

**What exists today:**

- `landfall-update` CLI placeholder prints the manual-update doc URL so
  operators don't get "command not found".
- The pi-gen build supports `--from-env` / `--from-yaml`, which makes
  reproducible builds straightforward — a prerequisite for OTA.

---

## OAuth / credential management

### 🟢 Pre-emptive token refresh

The existing `CalendarRefreshCall` runs every 15 minutes and refreshes
tokens implicitly when fetching events. That works as long as the user's
account is "warm." For users with no events in the lookahead window, the
token can silently expire between fetches.

**Plan**: a small `CredentialMaintenanceCall` future call that runs every
6 hours, finds credentials whose `tokenExpiresAt < now + 24h`, and triggers
a refresh. Reuses existing refresh code.

### 🟢 Per-API-key scopes

Originally Phase 2 of the security hardening — deferred to post-alpha. Add
`scope` enum to `ApiKey`: `push_only`, `push_and_dismiss`, `admin`. Enforce
in `authenticateRequest`. Schema migration + endpoint check.

### 🟢 API key expiry

`ApiKey.expiresAt: DateTime?`. Reject in `authenticate()` when set and past.
Schema migration + endpoint check.

---

## Telemetry follow-ups (dev-build only)

The minimum viable shipped in Phase 3:

- Display fires `app_launched` events when built with
  `LANDFALL_TELEMETRY_ENDPOINT`.
- Pi autostart fires `display_crash_loop` events when the 3-fast-crash
  threshold trips.
- Server logs structured `[LANDFALL_TELEMETRY]` markers for each event.

**Follow-ups that need product alignment** (none of these are blockers):

### 🟡 Event aggregation / dashboard

The structured markers are grep-able but not aggregated. Options:

1. Read markers into a Postgres `telemetry_events` table via a future call.
2. Pipe journald directly into Loki / Grafana / similar.
3. Self-hosted PostHog or Plausible.

### 🟡 Card-render performance events

`Telemetry.event('card_rendered', {source, duration_ms})` — useful for
catching slow integrations but only meaningful with aggregation.

### 🟡 Server-side request-tracing events

Not the same as application logs — structured events with request IDs that
can be joined across display + server.

---

## Bigger features (not beta-blockers)

### 🟡 Web admin UI (`/app`)

A browser-based admin surface for first-run sign-in, connecting OAuth
accounts, and basic configuration without needing physical access to the
display. Today every admin action requires either the on-Pi Flutter app,
SSH, or the one-time setup-token bypass on the companion route.

**Scope at MVP:**

- Email/passkey sign-in mirroring the display app's flow
- "Connect Google Calendar" button that triggers `/calendar/oauth/start`
  with a real authenticated session (replaces the setup-token bypass)
- "Connect Microsoft Calendar" — same shape
- Linked-credentials list with re-link buttons when a credential has gone
  stale (ties in with the credential-refresh follow-up below)
- Photo source picker once the photo abstraction lands

**Implementation notes:**

- New Flutter web entry `apps/display/lib/web_admin_main.dart` (separate
  from `companion_web_main.dart` — the companion is a device-pairing
  surface, not an admin one)
- Build target: `--base-href /app/`, output to a new
  `server/landfall_server/web/admin/` directory so it doesn't collide with
  the companion build
- New `/app/*` Serverpod route + Caddyfile reverse-proxy (currently
  deliberately absent — see the resolved blocker above)
- CSP additions for the admin bundle's needs

**Why deferred:** the setup-token bypass + the on-Pi display app cover the
beta admin surface adequately. A real web UI is multi-session work
(sign-in flow, OAuth wiring, link management screens, tests, end-to-end on
hardware) and is not on the critical path to first beta.

### 🟡 Card Library UI (Phase 22 from the original plan)

Browsable catalog of available card types with one-tap "add to layout."
Today, card visibility toggles in Settings serve as a stand-in.

### 🟡 Companion Cute Mode + Hybrid / Full Pet tiers (Phase 21)

The MVP Companion (Phase 13) ships with rarity tiers, names, evolution, and
pet/play/feed animations driven by phone QR. The expanded Companion design
(`docs/companion_card_design.md`) defines two further tiers — Cute mode
(more expressive personality) and Hybrid / Full Pet (richer interaction
loop). Deferred to a dedicated phase post-beta.

### 🔴 `landfall_agent_sdk` pub.dev publish

The SDK exists at `packages/agent_sdk/` with 30 tests and is documented in
`docs/integrations.md`. Publishing it to pub.dev is a growth task, not a
beta-readiness one. Needs decisions on the package name, publisher org,
versioning policy, and release cadence before we publish 0.1.0.

### 🟡 Per-platform CI matrix

Today CI runs analyzer + unit tests on Linux. Real builds (Pi image, Fire TV
APK, macOS dmg) happen locally. A matrix would catch platform-specific
build breakage earlier. Cost (CI minutes) is low; mostly a sequencing
question relative to other infra work.

### 🟢 Flutter SDK upgrade — drop `Intl.v8BreakIterator` warning

The companion page logs a Chrome deprecation warning sourced from
`main.dart.js` (Dart's `Intl` runtime calls `Intl.v8BreakIterator`, which
Chrome is removing in favour of `Intl.Segmenter`). It's a console warning
only — rendering and text segmentation still work today. Fixed upstream in
newer Flutter engine builds; pinned tracker is
[flutter/flutter#147369](https://github.com/flutter/flutter/issues/147369).

**Why deferred**: current Flutter is `3.41.6` (engine `5cdd3277...`,
March 2026). A bump should be a dedicated change with a full test pass and
Pi-image rebuild, not folded into unrelated debugging.

**Trigger**: next planned dependency-policy bump (`docs/dependency_policy.md`)
or when Chrome promotes the warning to an error.

---

## Licensed-tier features

Features in this section require cloud infrastructure managed by Landfall and
are therefore gated on the licensed (non-self-hosted) tier. Self-hosted and
unlicensed Pi builds continue to work without them.

### 🔴 Companion HTTPS — per-device subdomain

**Tier:** Licensed  
**Trigger:** Companion page confirmed stable; HTTPS wired up as part of the
licensed onboarding flow.

**Current state:** The companion page (scanned via QR code on the Pi display)
is served over HTTP on the local network. Browsers show a "Not Secure"
indicator. Functionally fine for LAN use; blocked for any future feature that
requires a secure context (WebAuthn, camera, etc.).

**Why not self-signed or mkcert:** Self-signed certs produce a blocking browser
warning on every new device. `mkcert`-style local CAs require installing a root
cert on every phone that scans the QR — unacceptable for a consumer product.

**Architecture decision — per-device subdomain with dynamic DNS:**

This is the standard approach used by Plex, Synology, and similar LAN-server
products. Each Pi gets a stable HTTPS URL that resolves on the public internet
but routes connections to the device's LAN IP. Data never leaves the network.

1. **Subdomain:** `{serial}.connect.landfall.app` — `serial` is the Pi's
   hardware serial number (or a UUID assigned at first boot).
2. **DNS:** Landfall cloud infra maintains an A record for each serial,
   updated whenever the Pi registers its current LAN IP.
3. **Registration:** On boot and periodically, the Pi POSTs its LAN IP to
   `api.landfall.app/devices/{serial}/ip`. Auth via a device secret baked into
   the image at manufacture time (or generated at first boot and pinned on
   first registration).
4. **Certificate:** Issued per-device by Landfall cloud infra using DNS-01
   ACME (Let's Encrypt). Pushed to the Pi as part of the registration
   response. Renewed by the cloud infra on a schedule; the Pi receives the new
   cert on its next registration heartbeat.
5. **QR code:** Updated to contain
   `https://{serial}.connect.landfall.app/c/{uuid}` instead of the current
   `http://{hostname}.local/c/{uuid}`.
6. **TTL:** DNS records use a short TTL (60 s) so IP changes propagate quickly
   after the Pi re-registers.

**Failure modes and mitigations:**

| Failure | Behaviour | Mitigation |
|---------|-----------|------------|
| Pi IP changes (router reassigns) | Old DNS record cached until TTL expires | Short TTL (60 s); Pi re-registers on every boot and every 15 min |
| Pi offline / no internet | Cannot reach companion page | Expected — companion requires LAN; no degradation in display function |
| Cloud DNS infra down | Cannot update IP; cert renewal blocked | Cert has 90-day validity; short outage has no user impact |

**Unlicensed path stays HTTP:** Self-hosted and unlicensed Pi builds serve the
companion page over HTTP on the LAN. No change to that path.

---

## How to use this list

- When you pick up an item, **convert the entry into a phase plan** before
  writing code. The bullet points here are the *what*, not the *how*.
- When you decide an item is no longer worth doing, **leave it here with a
  "DROPPED:" prefix and the reason** so the next person doesn't re-litigate.
- Move shipped items into `docs/updating.md` (if user-facing) or strike
  them through here with a commit reference.
