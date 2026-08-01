# Manual Smoke Test

Runnable cold. Every section is a checklist — work top-to-bottom, tick
each box, record the build SHA in the sign-off table at the bottom.
Anything that fails is a beta blocker until fixed or explicitly
deferred.

> **Scope.** This document validates a release candidate end-to-end
> across the three supported display targets (macOS desktop, Raspberry
> Pi appliance image, Fire TV / Android sideload) and the Serverpod
> backend they all talk to. It is **not** a unit-test substitute —
> `deploy/tests/run_deploy_tests.sh` plus the `flutter test` /
> `dart test` suites cover that. This is the user-visible behaviour
> pass.

> **Time budget.** ~3 hours when nothing breaks. Plan for a half-day
> if you are also flashing an SD card and sideloading APKs from scratch.

---

## Pre-flight (do once)

### Tools

- [ ] `dart --version` ≥ 3.5
- [ ] `flutter --version` ≥ 3.27 (stable channel)
- [ ] `docker --version` and `docker compose version`
- [ ] `adb` on PATH (Android platform tools)
- [ ] `serverpod --version` (only if you intend to regenerate code)
- [ ] A phone with a working camera + a QR scanner (built-in iOS / Android camera is fine)
- [ ] A second laptop or terminal you can `curl` from — for the agent-API tests

### Accounts (optional, only if you are validating these features)

- [ ] Google account with at least one calendar event in the next 7 days
- [ ] Google Drive folder with 3+ photos
- [ ] Microsoft 365 account with at least one calendar event (if testing Microsoft Calendar)
- [ ] SMTP credentials for the OTP test (any provider — Gmail App Password, SendGrid, AWS SES)
- [ ] OpenWeatherMap API key

### Hardware

- [ ] macOS host for the desktop test
- [ ] Raspberry Pi 4 (4 GB+) or Pi 5 with HDMI display, SD card, power supply
- [ ] Fire TV Stick (or any Android TV / Android phone) reachable over `adb`
- [ ] All three devices on the same WiFi (mDNS / LAN IP resolution depends on it)

### Build artifacts

```bash
# From repo root, on the dev host:
melos bootstrap                              # one-time setup
melos run analyze                            # must be clean
melos run test                               # must be green
```

- [ ] `analyze` clean
- [ ] `test` green

Record the build SHA you are validating:

```
RC SHA: ____________________________________
Date  : ____________________________________
Tester: ____________________________________
```

---

## Part 1 — Backend (run once, shared across all displays)

The Pi image bundles its own server. For the **macOS + Fire TV** tests
below you'll point them at a single backend. The easiest option for
the smoke test is to run that backend on the macOS host.

```bash
bash tools/scripts/start_mac.sh --server
```

- [ ] `curl http://localhost:8080/card/getCards -X POST -H 'Content-Type: application/json' -d '{}'` returns `[]`
- [ ] `docker compose ps` (or equivalent) shows postgres + redis healthy
- [ ] `tail -f /tmp/landfall-server.log` shows no startup errors

### Generate an API key (used by the agent-push tests)

The setup-token gate guards key minting. On dev/macOS the token is in `.env` as `API_KEY_MANAGEMENT_TOKEN`.

```bash
SETUP_TOKEN=$(grep ^API_KEY_MANAGEMENT_TOKEN server/landfall_server/config/passwords.yaml | cut -d"'" -f2)
# Use the appropriate endpoint to mint a key — record the plaintext value:
echo "Plaintext API key: lf_____________________________"
```

- [ ] Key minted; plaintext recorded (it will only be shown once)
- [ ] `curl http://localhost:8080/api/v1/cards -H "Authorization: Bearer $KEY"` returns `[]` (200)
- [ ] `curl http://localhost:8080/api/v1/cards` **without** the header returns 401

---

## Part 2 — macOS display

### 2.1 Build + launch

```bash
bash tools/scripts/start_mac.sh --build
```

- [ ] `.app` launches fullscreen (or in a window if your debug binding overrides)
- [ ] Setup wizard appears on first launch (or `--reset` for a fresh run)
- [ ] Server URL field auto-detects `http://localhost:8080/` or accepts manual entry
- [ ] Wizard advances through location → calendar (skippable) → API key → done

### 2.2 Sign-in (OTP)

If SMTP isn't configured on dev, `OTP_LOG_CODES=true` writes codes to the server log.

```bash
grep -i otp /tmp/landfall-server.log | tail -5
```

- [ ] Email entry → "Send code" button works
- [ ] OTP code arrives in email **or** appears in server log within 5 seconds
- [ ] Entering the code unlocks the display

### 2.3 System cards

Each system card must render correctly. Allow up to 1 minute for first-load fetches.

- [ ] **ClockCard** — shows correct local time, updates every second, no per-tick rescale (BUG-04 regression)
- [ ] **ClockCard** — date line shows today's day-of-week + month + day
- [ ] **CurrentWeatherCard** — shows current conditions for the configured location (or hides gracefully if OWM not set); the condition icon is **full-colour** (Meteocons), with the correct **day vs night** variant
- [ ] **ForecastStripCard** — 5 day columns with high/low; full-colour weather icons; no overflow (BUG-05 regression)
- [ ] **CalendarCard (daily)** — events from the linked Google account appear
- [ ] **CalendarCard (daily, no events)** — with no events today the card still shows today's date headline + "No events scheduled today" (never a bare heading)
- [ ] **CalendarCard (2-week)** — toggle via Card HUD; the full 14-day scaffold renders with each day's date/label, events bucketed under their day
- [ ] **CalendarCard (2-week, no events)** — with no events in the window the 14 day rows (Today, Tomorrow, …) are still visible
- [ ] **CalendarCard (weekly)** — toggle via Card HUD; 7-column grid renders
- [ ] **CalendarCard (monthly)** — toggle via Card HUD; month grid + event dots render
- [ ] **PhotoFrameCard** — cycles through photos from the configured Drive folder; transitions are smooth
- [ ] **TickerStrip** — empty by default; runs `curl` from Part 1 with `layout=ticker` to push one and watch it appear at the bottom

### 2.4 Theme switching (BUG-06 regression)

- [ ] Settings → Theme → pick a non-default theme → tap Apply
- [ ] Every system card's border / fill / text color changes
- [ ] Restart the app → theme persists

### 2.5 Profile switching

- [ ] Settings → Profiles → at least 3 seed profiles present
- [ ] Tap a different profile → display recomposes; card visibility / layout changes
- [ ] Create a new profile → save → activate → confirm layout matches

### 2.6 Layout editor

- [ ] Tap a card → selection HUD appears (UX-01/02 regression)
- [ ] Drag a card to a new slot → drops with spring animation
- [ ] Resize handles work
- [ ] Lock toggle in HUD prevents drag/resize when on
- [ ] Long-press an empty slot → card library / quick-add (if implemented)

### 2.7 Companion (the IP-discovery acid test)

- [ ] Companion card visible on the display
- [ ] QR code in the bottom-right corner of the companion card
- [ ] Scan the QR with your phone — companion page **loads** (this is the critical one)
- [ ] URL bar on the phone shows `http://<mac-lan-ip>:8082/c/<uuid>` (not `127.0.0.1`)
- [ ] Tap **Pet** on the phone → TV companion plays its pet animation within 2 seconds
- [ ] Tap **Play** on the phone → TV companion plays its play animation
- [ ] Tap **Feed** on the phone → TV companion plays its feed animation
- [ ] Disconnect the phone from WiFi, scan again → graceful failure (phone says "can't reach")
- [ ] Reconnect, scan again → working

### 2.8 Agent card push (REST)

From the second laptop / terminal:

```bash
curl -X POST http://<mac-lan-ip>:8080/api/v1/cards \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "source": "agent.smoketest",
    "title": "Smoke test card",
    "body": "If you see this on your display, the agent API works.",
    "layout": "medium",
    "priority": "ephemeral"
  }'
```

- [ ] Card appears on the display within 2 seconds
- [ ] Title + body render correctly
- [ ] Dismiss the card via long-press / dismiss button → it disappears
- [ ] Push the same card again → it returns
- [ ] Push with `"actions":[{"type":"openUrl","label":"Open","payload":"https://example.com"}]` → action button appears, tapping opens the browser
- [ ] Push with `"actions":[{"type":"openUrl","label":"X","payload":"javascript:alert(1)"}]` → server rejects with 400 (A05 regression)

### 2.9 Window resize stability (BUG-05 regression)

- [ ] Drag the window edge down to roughly half the design size (about 960×540)
- [ ] No Flutter overflow warnings in the terminal
- [ ] All cards still render legibly (some text may scale; nothing should clip)

### 2.10 Settings → Accounts

- [ ] Linked Accounts list shows the Google account from the wizard
- [ ] Connect tiles show "Copy URL"; buttons are **enabled** (a ticket minter is wired)
- [ ] Tap **Copy URL** for Google → the copied URL targets the **web server** port (`:8082` on direct-port, or the bare domain behind Caddy) and contains `?ticket=…` — **not** `:8080` and **not** `authUserId=`
- [ ] Open the copied URL within a few minutes on a phone/browser → reaches Google consent (not a 404 or "Authentication required")
- [ ] Reusing the same copied URL a second time fails (single-use ticket) — re-copy to retry
- [ ] Add a Microsoft account (if testing) → same ticket-based flow works
- [ ] Revoke an account → it disappears from the list; calendar card shows "Reconnect" prompt

**macOS pass:** [ ] all of 2.x ticked.

---

## Part 3 — Raspberry Pi (appliance image)

### 3.1 Build the image

```bash
bash deploy/pi-gen/configure.sh        # answer hostname, WiFi, timezone, etc.
bash deploy/pi-gen/build.sh
```

- [ ] `configure.sh` asks for **timezone** (new in this release)
- [ ] `landfall-build.conf` includes `PI_TIMEZONE=...`
- [ ] `build.sh` completes; `.img` file present under `deploy/pi-gen/work/pi-gen/deploy/`

### 3.2 Flash + boot

Flash with Raspberry Pi Imager or `dd`. Boot the Pi.

- [ ] **Boot 1** (Pi Imager firstrun): hostname is set, Pi reboots automatically
- [ ] **Boot 2** (`landfall-firstboot.service`): kiosk shows splash → display launches within ~2 minutes
- [ ] `ssh landfall@<hostname>.local` works (mDNS resolution)
- [ ] On the Pi: `timedatectl` shows the timezone you configured and `NTP synchronized: yes`
- [ ] `docker compose ps` (in `/home/landfall/landfall/deploy/`) shows all services `healthy` (4d regression — no `unhealthy` after start_period)
- [ ] `journalctl -u landfall-firstboot` shows the unit gated on `systemd-time-wait-sync.service` (4c regression)

### 3.3 Display

Repeat the entire **Part 2** card-by-card validation (2.3 through 2.9) on the Pi display. Skip 2.1, 2.2, 2.10 — those were already covered on macOS.

- [ ] All system cards render (2.3)
- [ ] Theme switching works (2.4)
- [ ] Profile switching works (2.5)
- [ ] Layout editor works (2.6)
- [ ] Companion QR scans from phone (2.7) — **URL must show `https://<hostname>.local/c/<uuid>`** (Caddy + LANDFALL_DOMAIN), not the Pi's raw IP
- [ ] Agent card push from another machine works (2.8) — target `http://<hostname>.local:8080/api/v1/cards`
- [ ] Window resize doesn't apply on kiosk (full-screen) — skip 2.9

### 3.4 Service recovery (Phase 4d acid test)

```bash
ssh landfall@<hostname>.local
cd ~/landfall/deploy
docker compose kill server
# Wait 30 seconds.
docker compose ps
```

- [ ] `server` shows `restarting` or `running` (not `dead`)
- [ ] Display continues to function — may show "offline" briefly then recover
- [ ] `docker compose kill redis` → same recovery behaviour
- [ ] `docker compose kill caddy` → same

### 3.5 Power-cycle test

- [ ] Pull power on the Pi → wait 30 s → reapply
- [ ] Pi boots, display app comes up to its previous state within ~90 s
- [ ] No re-prompt for setup wizard (state persisted)
- [ ] Clock shows correct local time **immediately** (no UTC blink — 4c regression)

**Pi pass:** [ ] all of 3.x ticked.

---

## Part 4 — Fire TV / Android

### 4.1 Build + sideload

```bash
bash tools/scripts/build_apk.sh
adb connect <fire-tv-ip>:5555
adb install -r apps/display/build/app/outputs/flutter-apk/app-release.apk
```

- [ ] APK build succeeds
- [ ] `adb install` reports `Success`
- [ ] App appears in the Fire TV "Your Apps" row

### 4.2 First launch

- [ ] App launches in landscape, fullscreen
- [ ] Setup wizard appears
- [ ] Enter the **macOS or Pi backend URL** (e.g. `http://landfall.local:8080`)
- [ ] Wizard advances; remote D-pad nav works through every screen

### 4.3 Cards

Repeat **Part 2** card-by-card validation (2.3, 2.4, 2.5, 2.7, 2.8) on the Fire TV. Skip:
- 2.6 layout editor — confirm it's at least navigable with the remote; deep edits are macOS / mouse territory
- 2.9 resize — Fire TV doesn't resize
- 2.10 — covered on macOS

- [ ] All system cards render correctly on the TV
- [ ] D-pad navigation reaches every interactive element (cards, dismiss buttons, action buttons)
- [ ] Theme switching applies
- [ ] Profile switching applies
- [ ] Companion QR scans — **URL points at the backend host, not 127.0.0.1** (4b regression)
- [ ] Companion interactions trigger animations on the TV

### 4.4 Remote-only navigation sanity

- [ ] Settings reachable from the remote (long-press a card or use the gear pill)
- [ ] OAuth account linking — copy the URL (carries a single-use `?ticket=`), open it on a phone within a few minutes, complete consent
- [ ] Calendar card refreshes within 1 minute of linking

### 4.5 Resilience

- [ ] Kill the backend on the Pi/macOS → Fire TV display shows cached state with an offline indicator
- [ ] Restart the backend → display reconnects within 30 s; cards refresh

**Fire TV pass:** [ ] all of 4.x ticked.

---

## Part 5 — Cross-platform feature parity

These checks compare behaviour across platforms to catch silent
divergence. Use the same backend for all three displays.

- [ ] Same agent card pushed from `curl` appears on **all three** displays within 2 s
- [ ] Theme change on one display → others reflect within ~5 s (server-driven theme cubit)
- [ ] Profile activated on one display → others switch
- [ ] Companion entity is **per display** — each platform has its own `displayId` and its own companion (rarity, name, evolution)
- [ ] Calendar event count matches across all three displays (same backend → same data)
- [ ] Photo card cycles the same images on all three (same Drive source)

---

## Part 6 — Security spot-checks (alpha hardening regressions)

Quick post-Phase-2 verification. The full hardening audit lives in the
maintainer's private notes (see [`SECURITY.md`](../SECURITY.md) for
scope and disclosure process); these are the user-visible ones.

- [ ] **CORS**: From a browser console on `https://example.com`, `fetch('http://<backend>:8080/api/v1/cards', {headers: {Authorization: 'Bearer XXX'}})` returns 401 with no `Access-Control-*` headers (commit `1928faf`)
- [ ] **SSRF**: Settings → Theme → Import → enter `https://192.168.0.1/x.yaml` → error: "URL refers to a restricted host" (commit `7ced66b`)
- [ ] **Rate limit**: Push 501 cards rapidly with the same key → 502nd returns `429` with body `{"error":"Rate limit exceeded."}` — no leaked reset time
- [ ] **Webhook silent error**: Push a card with an action whose `payload` is an unreachable URL → tap action → on the device, `flutter logs` shows the failure (no longer silently swallowed; commit `d93d1a5`)
- [ ] **actionsJson versioning**: Push `actions: {"schemaVersion":99,"actions":[]}` → 400 with `schemaVersion=99 is not supported` (commit `1e44e6e`)

---

## Part 7 — Web Settings (companion app)

### 7.1 Open the companion settings screen

- [ ] On any display (macOS, Pi, or Fire TV), scan the QR code from the companion card — or navigate to `http://<host>/c/<displayId>` in a phone browser
- [ ] Settings gear icon (top-right of the companion page) is visible
- [ ] Tap the gear → login wall appears (not the settings screen itself)

### 7.2 OTP login

- [ ] Enter the email address associated with the display account
- [ ] Tap "Send code" → OTP arrives in email or appears in server log (`OTP_LOG_CODES=true`)
- [ ] Enter the code → settings screen opens, showing the "Layout" tab active by default

### 7.3 Tab navigation

- [ ] TabBar shows five tabs: **Layout**, **Themes**, **Accounts**, **Display**, **License**
- [ ] Each tab is tappable on a phone-sized viewport (375 px wide)
- [ ] Switching tabs does not lose unsaved changes in the previous tab (or shows a discard prompt if implemented)

### 7.4 Display tab

- [ ] Tap **Display** → tab loads with a brief loading indicator, then shows the form
- [ ] Three sections visible after scroll: **LOCATION**, **DIM**, **PHOTO SOURCE**
- [ ] **LOCATION** section shows the current timezone/location string

**Dim settings:**

- [ ] "Enable dimming" switch is present; toggling it shows/hides the hour pickers
- [ ] Hour pickers show 12-hour labels (e.g. "12:00 AM", "9:00 PM") for hours 0–23
- [ ] Brightness slider is present (0–100 range)

**Photo source:**

- [ ] "Landfall Server" chip is selected by default (for a freshly provisioned display)
- [ ] ⓘ info button on the Landfall Server chip opens an info sheet
- [ ] Info sheet names **Google Drive** explicitly
- [ ] Info sheet states that **Microsoft OneDrive is not yet supported**
- [ ] Dismiss the info sheet → returns to the tab form without losing state
- [ ] "Network URLs" chip is selectable
- [ ] Selecting Network URLs reveals a multiline text field for entering URLs (one per line)
- [ ] Entering no URLs → Save button is disabled
- [ ] Entering at least one URL → Save button becomes enabled

**Save and push:**

- [ ] Save the Display tab with dim changes → **no error**; a brief saving state appears and resolves
- [ ] Within ~5 seconds the TV display dims (or un-dims) per the new schedule without restarting the app
- [ ] Switch to Network URLs, enter 2–3 image URLs → save → TV photo source switches to those URLs within ~5 seconds
- [ ] Switch back to Landfall Server → save → TV reverts to Drive photos

### 7.5 Layout tab from web

- [ ] Tap **Layout** → card grid renders; cards are draggable with a mouse/finger
- [ ] Drag one card to a new slot → Save button appears (or auto-save fires)
- [ ] Save → within ~5 seconds the TV display recomposes to the new layout

### 7.5b Themes tab from web

- [ ] Tap **Themes** → tiles render; on a ≤390px phone viewport the **Apply** button is fully visible on each tile (not clipped) and the preview strips are not squished/overflowing
- [ ] Open **Browse Themes** → a single Themes list (no Installed/Marketplace tabs); **no prices, no Free/Owned badges, no Purchase button** anywhere — each theme has only **Apply**
- [ ] Apply a different theme from the companion → within ~5 seconds the **TV dashboard repaints** with the new theme (this is the profileId-persistence fix)
- [ ] The **companion card** on the TV uses the theme's card colour (not a fixed black) after the theme change

### 7.6 Accounts tab

- [ ] **Accounts** tab loads the linked credentials list
- [ ] The Google account added during setup is listed
- [ ] Connect tiles show **Open** + **Copy URL**, both enabled
- [ ] Tap **Open** for Google → a new tab opens to the **web-server origin** (same origin as the companion page) with `?ticket=…` in the URL, and reaches Google consent — **not** a 404 or "Authentication required to connect a calendar"
  - This is the core end-to-end check for the OAuth ticket path: the companion mints a single-use ticket over its authenticated session, so no JWT/cookie is needed on the navigation. Requires a Google-resolvable redirect domain (see `self_hosting_guide.md` → "OAuth without a public domain").
- [ ] Complete consent → confirmation page shows the connected email
- [ ] Back in the Accounts list (Refresh) the new credential appears as **Connected**
- [ ] On the TV display, the calendar card pulls the account's events within ~1 minute (`CalendarRefreshCall`)

### 7.7 Sign-out

- [ ] Settings → Accounts (or a dedicated sign-out control) → sign out
- [ ] Page returns to the companion landing screen (not a blank page or error)
- [ ] Gear icon re-opens the login wall (session cleared)

**Web Settings pass:** [ ] all of 7.x ticked.

---

## Sign-off

Fill in once every platform has passed and the security spot-checks
are green.

| Platform | SHA | Tester | Date | Pass? | Notes |
|----------|-----|--------|------|-------|-------|
| macOS    |     |        |      |  / Y N |       |
| Pi (img) |     |        |      |  / Y N |       |
| Fire TV  |     |        |      |  / Y N |       |
| Cross-platform parity |  |  |  |  / Y N |       |
| Security spot-checks  |  |  |  |  / Y N |       |
| Web Settings (companion) |  |  |  |  / Y N |       |

If every row is `Y`, the build is releasable. Save the completed sign-off
table to the private repo for audit trail.

---

## Known issues / accepted alpha deferrals

These items are **expected** to be incomplete and should not block
release:

- Per-API-key scope (`push_only` / `admin`) — deferred post-alpha
- API key expiry — deferred post-alpha
- Card Library UI (Phase 22) — partial; visibility toggles serve this
  role for now
- Companion Hybrid / Full Pet tiers — deferred to Phase X
- Per-platform CI matrix (Linux/Android emulator) — nice-to-have

For user-facing limitations carried into the public beta (Fire TV IME,
display goldens, prior-server card bleed-through, etc.), see
[`beta_known_limitations.md`](beta_known_limitations.md). Behaviour
matching either list should be noted under "Notes" in the sign-off
table but does not fail the platform.

---

## For AI assistants

Key facts about this document:

- **This is the end-to-end human validation pass** — not a substitute for unit/widget/integration tests. Run it before any public release, not on every PR.
- **Time budget:** ~3 hours minimum when nothing breaks. Budget a half-day if building from scratch (Pi image build alone is 1–2h).
- **All three platforms must pass** (macOS, Pi, Fire TV) for a build to be releasable. Cross-platform parity checks (Part 5) and security spot-checks (Part 6) are also required.
- **Part 6 security checks** are regression tests tied to specific commits. If any fail, treat it as a blocker — they represent shipped security fixes that regressed.
- **Agent API key** for Part 1 and 2.8 tests: minted via `tools/scripts/mint_api_key.sh` or via the API endpoint using `API_KEY_MANAGEMENT_TOKEN`. The plaintext key is shown once — record it before moving on.
- **`OTP_LOG_CODES=true`** in `.env` lets you retrieve OTP codes from the server log during smoke testing without real SMTP configured.
- **Known deferrals in Part 7** should not cause a platform to fail — note them in the sign-off table instead.
- **Companion QR** is one of the harder tests to pass: the URL must resolve to the server's LAN address, not `127.0.0.1`. This is the "IP discovery acid test" mentioned in 2.7.
- **Part 7 (Web Settings)** tests the companion web app at `/c/{displayId}`. Requires a phone browser or desktop browser in mobile-viewport mode. The settings screen is behind OTP auth — use `OTP_LOG_CODES=true` in `.env` if SMTP is not configured. TV-side reflection checks (7.4 Save and push, 7.5) require an active display on the same backend.
