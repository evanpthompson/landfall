# Landfall Roadmap

Near-term work that is scoped, planned, and owned. Items here are commitments
we expect to ship; longer-term exploration is tracked separately and will
surface here once scoped.

Status legend:

- 🟢 **Ready to start** — design + product decisions are made, just needs engineering time.
- 🟡 **Needs design** — engineering knows what to do but design / UX work is required first.

---

## Recently shipped (pre-beta)

All five originally-tracked pre-beta blockers landed in commits between
`9c26604` and `3d0e84f`:

- `/app` route removed (no real web admin UI shipped yet — see backlog below).
- Push-server deploy script — `deploy/scripts/push-server.sh` with arm64 enforcement.
- Google OAuth — real-domain redirect documented as the primary path; setup-token
  fallback preserved and reframed as advanced.
- Google Drive photos — service account auth is the default; OAuth is the fallback.
- `authUserId` canonical derivation — single source of truth at
  `server/landfall_server/lib/src/auth/auth_user_id.dart`.

---

## Reliability follow-ups

These extend the operator tooling that shipped in the beta-prep work. Each has
a minimal-viable version already in place; the items here are the next step.

### 🟢 Crash-bundle auto-ship

**Trigger:** the first Pi field report we can't diagnose from the existing
telemetry events alone.

The Pi posts a `display_crash_loop` telemetry event when the openbox autostart
trips its 3-fast-crash threshold. That tells us **when** but not **why** — the
full diagnostic context (journal tails, compose state, GL info) lives in the
`landfall-bug-report` bundle which has to be pulled off the Pi manually.

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

**Constraints**:

- Bundles run 1–5 MB. Set the rate limit on the route generously so the bundle
  that matters most is not the one that gets dropped.
- Compression already happens client-side (`.tgz` is gzipped); do not
  double-compress server-side.
- Dev-build-only must still hold: the entire ship path is gated on
  `LANDFALL_TELEMETRY_ENDPOINT` being non-empty in the runtime `.env`.

### 🟡 Re-link card UI for failed credentials

**Trigger:** beta users start losing Microsoft calendar data silently, or
someone asks "why did my calendar stop?"

The server already emits a structured `LANDFALL_CREDENTIAL_REFRESH_FAILED`
marker when a token refresh fails (Phase 3.5). `landfall-doctor` parses it.
But the display **shows nothing** to a non-SSH user — calendar cards just go
quietly stale. (Google photos use a service account so this is less acute on
the Google side; Microsoft OAuth still needs it.)

**Plan**:

1. Schema additions to `LinkedCredential`:
   - `consecutiveRefreshFailures: int, default=0`
   - `lastRefreshErrorAt: DateTime?`
   - `lastRefreshErrorKind: String?` (e.g. `revoked`, `network`, `unknown`)
2. `CalendarRefreshCall` increments on failure, resets on success.
3. When `consecutiveRefreshFailures >= 3`, push a system card with action
   `openUrl` → the existing OAuth start URL for that provider. The user
   scans the QR or opens the link on their phone to re-grant consent.
4. Display: clear the card once the credential resyncs OK (the next successful
   refresh emits a `card_dismiss` event for the credential's card source).

**Design questions before coding**:

- Card copy: "Microsoft calendar disconnected. Tap to reconnect."?
- Persistent or expiring? Persistent — silent failure is worse than a
  slightly-too-visible nudge.
- Per-credential or grouped? Per-credential, with the email visible. Multiple
  accounts is a real case.

---

## OAuth / credential management

### 🟢 Pre-emptive token refresh

`CalendarRefreshCall` runs every 15 minutes and refreshes tokens implicitly
when fetching events. That works as long as the account stays "warm." For
accounts with no events in the lookahead window, the token can silently expire
between fetches.

**Plan**: a small `CredentialMaintenanceCall` future call that runs every
6 hours, finds credentials whose `tokenExpiresAt < now + 24h`, and triggers a
refresh. Reuses existing refresh code.

### 🟢 Per-API-key scopes

Originally Phase 2 of the security hardening — deferred to post-alpha. Add a
`scope` enum to `ApiKey`: `push_only`, `push_and_dismiss`, `admin`. Enforce in
`authenticateRequest`. Schema migration + endpoint check.

### 🟢 API key expiry

`ApiKey.expiresAt: DateTime?`. Reject in `authenticate()` when set and past.
Schema migration + endpoint check.

---

## Dependency hygiene

### 🟢 Flutter SDK upgrade — drop `Intl.v8BreakIterator` warning

The companion page logs a Chrome deprecation warning sourced from
`main.dart.js` (Dart's `Intl` runtime calls `Intl.v8BreakIterator`, which
Chrome is removing in favour of `Intl.Segmenter`). It's a console warning
only — rendering and text segmentation still work today. Fixed upstream in
newer Flutter engine builds; pinned tracker is
[flutter/flutter#147369](https://github.com/flutter/flutter/issues/147369).

Current Flutter is `3.41.6` (engine `5cdd3277...`, March 2026). A bump should
be a dedicated change with a full test pass and Pi-image rebuild, not folded
into unrelated debugging.

**Trigger**: next planned dependency-policy bump
([`docs/dependency_policy.md`](dependency_policy.md)) or when Chrome promotes
the warning to an error.

---

## How to use this list

- When you pick up an item, **convert the entry into a phase plan** before
  writing code. The bullet points here are the *what*, not the *how*.
- When you decide an item is no longer worth doing, **leave it here with a
  "DROPPED:" prefix and the reason** so the next person doesn't re-litigate.
- Move shipped items into [`docs/updating.md`](updating.md) (if user-facing) or
  strike them through here with a commit reference.

Longer-term exploration (cloud-tier services, integration breadth,
layout-editor UI, additional companion tiers) is tracked privately and will
surface here once scoped and committed to.

For user-facing limitations that ship with the public beta (Fire TV IME,
display goldens, prior-server card bleed-through, focus widget adoption),
see [`beta_known_limitations.md`](beta_known_limitations.md).

---

## Backlog / Under consideration

Items here are not committed — no design decisions made, no timeline. They
exist so ideas don't get lost. Move to the main roadmap when scoped.

### OTA update tool/script

A mechanism to push a new APK or Pi image to deployed devices without
requiring physical access or manual sideloading. Useful for beta users running
Fire TV or Pi builds who can't easily plug in a laptop. Scope TBD — could be
as simple as a shell script that pulls and installs a new build from the
server, or as involved as a background update daemon. Not blocking beta launch.

---

## For AI assistants

This file is the near-term committed roadmap — items here are planned and owned,
not a wishlist. A few things worth knowing:

- **Recently shipped** is the canonical summary of what landed in pre-beta.
  For commit-level detail, use `git log`.
- **Status icons** tell you what's blocked on what. 🟢 = engineering can start.
  🟡 = design questions listed inline must be answered first.
- **If a feature isn't here**, it either shipped, was dropped, or is longer-term
  work tracked privately. Don't infer planned features from docs unless they
  appear in this file.
- **When helping with a roadmap item**, read the "Plan" and "Constraints"
  bullets before writing code — they capture decisions already made.
