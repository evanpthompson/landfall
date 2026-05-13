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

---

## How to use this list

- When you pick up an item, **convert the entry into a phase plan** before
  writing code. The bullet points here are the *what*, not the *how*.
- When you decide an item is no longer worth doing, **leave it here with a
  "DROPPED:" prefix and the reason** so the next person doesn't re-litigate.
- Move shipped items into `docs/updating.md` (if user-facing) or strike
  them through here with a commit reference.
