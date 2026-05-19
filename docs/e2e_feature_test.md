# End-to-End Feature Test

Every user-visible feature, exercised step-by-step, on every supported
display platform. This is the **regression sweep** — slower and more
exhaustive than [`manual_smoke_test.md`](manual_smoke_test.md), which
gates a release.

When to run this:

- Before a quarterly release branch is cut.
- After any change that touches more than one feature area (auth, theming,
  cards, layout, companion, agent API).
- When investigating a "something feels off but I can't pin it down" report.

When **not** to run this:

- On every PR. Use unit / widget / integration tests for that
  (`melos run test`).
- For release gating. Use [`manual_smoke_test.md`](manual_smoke_test.md).

> **Time budget.** A full sweep across macOS + Pi + Fire TV is ~6 hours
> when nothing breaks. Most testers split it into two or three sittings.

---

## How to read a test

Every test follows the same shape:

```
### 2.1 Feature name

**What it does.** One-line user-visible summary.

**Prerequisites.** What must already be true.

**Steps.**
1. Action.
2. Action.

**Expected.**
- Outcome on macOS.
- Outcome on Pi (only if it differs).
- Outcome on Fire TV (only if it differs).

**On failure.** Pointer to Appendix A (logging) and/or B (platform notes).
```

If a section omits the per-platform breakdown under **Expected**, the
behaviour is identical across platforms.

---

## Conventions

- `<server>` — the backend host:port your displays talk to. Default
  `http://localhost:8080` on macOS, `http://<hostname>.local:8080` on Pi.
- `<display-host>` — the LAN IP or mDNS hostname of the display under test.
- `$KEY` — a freshly minted plaintext API key (see § 7.1).
- "Display" is the kiosk / TV-facing app. "Companion" is the phone-facing
  web view served at `:8082`.
- Commits referenced as `abc1234` are real and grep-able in `git log`.

---

## Pre-flight

Run once per sweep.

### Tooling

- [ ] `dart --version` ≥ 3.5
- [ ] `flutter --version` ≥ 3.27
- [ ] `docker --version` + `docker compose version`
- [ ] `adb` on PATH
- [ ] Phone with working camera + QR scanner
- [ ] Second terminal for `curl` (the agent-API tests run from outside the display host)

### Accounts

- [ ] Google account with ≥ 1 event in the next 7 days
- [ ] Google Drive folder with ≥ 3 photos
- [ ] Microsoft 365 account with ≥ 1 calendar event (optional)
- [ ] SMTP creds (Gmail App Password works) **or** `OTP_LOG_CODES=true` in
      `.env` (see [build_defines.md](build_defines.md))
- [ ] OpenWeatherMap API key

### Hardware

- [ ] macOS host
- [ ] Raspberry Pi 4 (4 GB+) or Pi 5 + HDMI display + power
- [ ] Fire TV Stick (or Android TV / Android phone reachable via `adb`)
- [ ] All on the same WiFi (mDNS depends on it)

### Build state

```bash
melos bootstrap
melos run analyze        # must be clean
melos run test           # must be green
```

- [ ] `analyze` clean
- [ ] `test` green

Record:

```
RC SHA: ____________________________________
Date:   ____________________________________
Tester: ____________________________________
```

---

## 1. Setup & onboarding

### 1.1 First-run wizard appears

**What it does.** Displays a setup wizard on first boot when no
local profile exists.

**Prerequisites.** Fresh install — either first boot of a freshly
flashed device, or `--reset` flag on macOS, or `adb pm clear` on Android.

**Steps.**
1. Launch the display app cold.
2. Observe the first screen.

**Expected.**
- Wizard appears, not the dashboard.
- The first screen prompts for **Server URL** with a sensible default
  (`http://localhost:8080/` on macOS, blank on Pi and Fire TV).

**On failure.** App went straight to dashboard → local state not cleared.
See Appendix A.1 and A.2.

### 1.2 Server URL — auto-detect

**What it does.** macOS dev builds try `localhost:8080` automatically.

**Steps.**
1. With the server running on the same host, advance past the URL screen
   without typing anything.

**Expected.**
- macOS: accepts the default and advances.
- Pi: no auto-detect — manual entry required.
- Fire TV: no auto-detect — manual entry required.

**On failure.** Appendix A.1.

### 1.3 Server URL — manual entry

**Steps.**
1. Type `http://<server>` into the field.
2. Tap **Continue**.

**Expected.**
- The display contacts `<server>/card/getCards` and advances.
- A bad URL (`http://nope.invalid:8080`) shows a clear error and does not
  advance.

**On failure.** Appendix A.1, A.6 (network).

### 1.4 OTP sign-in — happy path

**Prerequisites.** SMTP configured in
`server/landfall_server/config/passwords.yaml` **or**
`OTP_LOG_CODES=true` in the runtime env.

**Steps.**
1. Enter an email address on the sign-in screen.
2. Tap **Send code**.
3. Retrieve the code (from your inbox or `grep -i otp /tmp/landfall-server.log`).
4. Enter the code.

**Expected.**
- "Send code" button transitions to a loading state for < 5 s.
- Code arrives in inbox within 30 s (when SMTP is real).
- Entering the correct code advances to account-linking.
- An incorrect code shows "Invalid code" without crashing.

**On failure.** Appendix A.3 (auth / OTP).

### 1.5 OTP sign-in — SMTP failure path

**Steps.**
1. Break SMTP: set `smtpFromEmail` to a clearly invalid value (e.g.
   `notarealdomain@example.invalid`) and restart the server.
2. Trigger an OTP from the display.

**Expected.**
- Server log emits a single `[OTP] SMTP delivery failed: <reason>` line
  with the actual Gmail / SES error (commit `cf56eb7` follow-up — surfaced
  via `print()` in `otp_email_sender.dart`).
- Display shows a non-crashing error toast.

**On failure.** Appendix A.3.

### 1.6 Account linking — Google calendar (OAuth)

**Steps.**
1. From the wizard or Settings → Accounts, tap **Link Google calendar**.
2. Copy the OAuth URL shown on-screen (or scan the QR if present).
3. Complete consent on a phone / laptop.
4. Return to the display.

**Expected.**
- Within ~30 s the linked account appears under Settings → Accounts with
  the email visible.
- CalendarCard (daily) refreshes within 1 min with real events.

**Per-platform notes.**
- macOS: callback hits `127.0.0.1:8082/calendar/oauth/callback` — must be
  registered in your Google Cloud OAuth client.
- Pi (image): callback hits `https://<hostname>.local/calendar/oauth/callback`
  via Caddy.
- Fire TV: copy-the-URL flow only — no in-app browser.

**On failure.** Appendix A.4 (calendar), A.5 (OAuth callbacks).

### 1.7 Account linking — Microsoft calendar

**Prerequisites.** `microsoftClientId` and `microsoftClientSecret` set in
`passwords.yaml`.

**Steps.**
1. Settings → Accounts → **Link Microsoft calendar**.
2. Complete the OAuth flow.

**Expected.**
- Account appears in the linked list with the @outlook.com / @hotmail.com / tenant email.
- CalendarCard merges Microsoft events with Google ones; both providers'
  events show side-by-side.

**On failure.** Appendix A.4, A.5.

### 1.8 Photo source — service account (default)

**What it does.** Pulls photos from a Drive folder using the server's
service account. No per-user OAuth needed.

**Prerequisites.** The Drive folder is shared with the SA email shown in
Settings → Photos.

**Steps.**
1. Settings → Photos → **Use shared Drive folder**.
2. Paste the folder ID or full Drive URL.
3. Tap **Save**.

**Expected.**
- PhotoFrameCard starts cycling within 60 s.
- `provider='google-sa'` in `photo_sources` (server-side check via
  `psql` — see Appendix A.8).

**On failure.** Appendix A.7 (photos).

### 1.9 Photo source — OAuth fallback

**Steps.**
1. Settings → Photos → **Use my own Google account** (advanced).
2. Complete OAuth.

**Expected.**
- `provider='google-oauth'` in `photo_sources`.
- PhotoFrameCard cycles within 60 s.

**On failure.** Appendix A.7.

### 1.10 Wizard — skip path

**Steps.**
1. On a wizard step that is marked "optional" (calendar, photos), tap
   **Skip**.

**Expected.**
- Wizard advances; that subsystem stays unconfigured but does not block
  the rest of setup.
- The relevant card hides itself (CalendarCard hides if no accounts;
  PhotoFrameCard hides if no source).

**On failure.** Appendix A.1.

### 1.11 Wizard — completion persists

**Steps.**
1. Complete the wizard.
2. Quit the app fully (Cmd-Q on macOS, kill on Pi, force-stop on Fire TV).
3. Relaunch.

**Expected.**
- App goes straight to the dashboard. No re-prompt.

**On failure.** Appendix A.2.

---

## 2. System cards

Every system card has its own test. Run all of these once per platform.

### 2.1 ClockCard

**Steps.**
1. Locate the ClockCard on the dashboard.
2. Watch for 90 s.

**Expected.**
- Time advances every second.
- Time matches `date` on macOS / `timedatectl` on Pi / Settings → Date &
  Time on Fire TV, within 2 s.
- Date line reads "<weekday> <month> <day>".
- No per-tick layout shift (BUG-04 regression).

**On failure.** Appendix A.1, A.9 (time sync).

### 2.2 CurrentWeatherCard

**Prerequisites.** OpenWeatherMap API key set in `passwords.yaml`;
location set in Settings → Location.

**Steps.**
1. Locate the CurrentWeatherCard.
2. Compare to a phone weather app for the same city.

**Expected.**
- Temperature within 2°F / 1°C of the phone reading.
- Condition icon matches (sunny / cloudy / rainy).
- Card hides itself gracefully if OWM key is unset.

**On failure.** Appendix A.10 (weather).

### 2.3 ForecastStripCard

**Steps.**
1. Locate the ForecastStripCard.

**Expected.**
- 5 day columns rendered.
- Each column has high / low temps and an icon.
- No layout overflow at 1920×1080 (BUG-05 regression).
- Day labels are localized (e.g. "Mon", "Tue").

**On failure.** Appendix A.10.

### 2.4 CalendarCard — daily

**Prerequisites.** At least one Google or Microsoft calendar linked
(§ 1.6 / 1.7).

**Steps.**
1. Locate the CalendarCard in daily mode (default).

**Expected.**
- Today's events listed with start time + title.
- All-day events grouped at the top.
- Empty state shows "Nothing scheduled today" (not a blank card).

**On failure.** Appendix A.4.

### 2.5 CalendarCard — weekly

**Steps.**
1. Open the Card HUD (long-press the CalendarCard).
2. Switch to **Weekly**.

**Expected.**
- 7-column grid renders.
- Events display as blocks scaled to their duration.
- Card HUD shows the toggle is active.

**On failure.** Appendix A.4.

### 2.6 CalendarCard — monthly

**Steps.**
1. Card HUD → **Monthly**.

**Expected.**
- Month grid with the current week highlighted.
- Days with events show a dot indicator.
- Tapping a day reveals that day's events.

**On failure.** Appendix A.4.

### 2.7 PhotoFrameCard

**Prerequisites.** Photo source configured (§ 1.8 or 1.9).

**Steps.**
1. Locate the PhotoFrameCard.
2. Watch for 3 minutes.

**Expected.**
- Photos cycle on a schedule (default ~30 s).
- Transitions are smooth (no flash of unstyled content).
- Card hides if the source folder has zero photos.

**On failure.** Appendix A.7.

### 2.8 TickerStrip

**Steps.**
1. Locate the TickerStrip at the bottom of the display.
2. From a second terminal:
   ```bash
   curl -X POST <server>/api/v1/cards \
     -H "Authorization: Bearer $KEY" \
     -H "Content-Type: application/json" \
     -d '{"source":"e2e.ticker","title":"Ticker test","body":"Hello","layout":"ticker","priority":"ephemeral"}'
   ```

**Expected.**
- Strip starts empty (no agent traffic yet).
- After the `curl`, the ticker scrolls "Ticker test — Hello" within 2 s.
- Strip is non-interactive (no tap target).

**On failure.** Appendix A.11 (agent push).

### 2.9 CompanionCard — display side

**Steps.**
1. Locate the CompanionCard.

**Expected.**
- An animated pet figure (sprite) is visible.
- A QR code is rendered in the bottom-right of the card.
- Below the QR: short instructions ("Scan to play").
- The pet animates idle / blinks / etc.

**On failure.** Appendix A.12 (companion).

---

## 3. Themes

### 3.1 Switch theme

**Steps.**
1. Settings → Theme.
2. Pick a non-default theme (e.g. **Sunset** or any preset).
3. Tap **Apply**.

**Expected.**
- Every card's accent / border / background updates within 2 s.
- The change persists after restart.

**On failure.** Appendix A.13 (themes).

### 3.2 Theme propagation across cards

**Steps.**
1. After § 3.1, visually scan every card.

**Expected.**
- All system cards (Clock, Weather, Forecast, Calendar, Photo, Companion)
  pick up the theme tokens.
- Custom agent-pushed cards also pick up the theme.

**On failure.** Appendix A.13.

### 3.3 Theme import — URL

**Steps.**
1. Settings → Theme → **Import**.
2. Paste a URL to a community theme YAML.

**Expected.**
- The server fetches and validates the YAML.
- On success: theme appears in the list and can be applied.
- On a private-network URL (`https://192.168.0.1/x.yaml`): error "URL refers
  to a restricted host" (SSRF guard, commit `7ced66b`).

**On failure.** Appendix A.13.

### 3.4 Theme persistence

**Steps.**
1. Apply a non-default theme.
2. Restart the app.

**Expected.**
- The same theme is active.

**On failure.** Appendix A.2.

---

## 4. Dashboard profiles

### 4.1 List profiles

**Steps.**
1. Settings → Profiles.

**Expected.**
- At least 3 seed profiles present (Home, Office, Family or similar — names depend on seed).
- The currently active profile is highlighted.

**On failure.** Appendix A.14 (profiles).

### 4.2 Switch profile

**Steps.**
1. Tap a different profile.

**Expected.**
- Dashboard recomposes within 2 s.
- Card visibility, layout, and theme may all change depending on the
  profile.

**On failure.** Appendix A.14.

### 4.3 Create profile

**Steps.**
1. Profiles → **New**.
2. Enter a name.
3. Save.

**Expected.**
- New profile appears in the list.
- Activating it switches the dashboard to its (default) layout.

**On failure.** Appendix A.14.

### 4.4 Delete profile

**Steps.**
1. Long-press a non-active profile → **Delete**.

**Expected.**
- Profile disappears from the list.
- Deleting the active profile is blocked with a clear error.

**On failure.** Appendix A.14.

### 4.5 Profile sync across displays

**Prerequisites.** Two displays signed in to the same backend.

**Steps.**
1. On display A, switch profiles.
2. Watch display B.

**Expected.**
- Display B follows within ~5 s (server-driven).
- Companion entity does **not** follow — each display has its own
  companion (per-display identity, see § 6.3).

**On failure.** Appendix A.14, A.15 (cross-display sync).

---

## 5. Layout editor

### 5.1 Selection HUD

**Steps.**
1. Tap any card (or long-press on Fire TV).

**Expected.**
- A floating HUD appears with: resize toggle, delete, lock, settings shortcut
  (UX-01 / UX-02 regression).
- Tapping elsewhere dismisses the HUD.

**On failure.** Appendix A.16 (layout).

### 5.2 Drag

**Steps.**
1. Select a card.
2. Drag to a new slot.

**Expected.**
- Card lifts visually during drag.
- Drops with a spring animation.
- Slot occupancy updates.

**Per-platform notes.**
- macOS: mouse drag.
- Pi (touchscreen): touch drag works; with a keyboard, no drag.
- Fire TV: D-pad-only drag is **not supported** (deep edit is macOS / mouse territory). Confirm at least navigation works.

**On failure.** Appendix A.16.

### 5.3 Resize

**Steps.**
1. Select a card → **Resize**.
2. Use the corner handles to grow/shrink.

**Expected.**
- Card snaps to grid as it resizes.
- Other cards reflow to make room.

**On failure.** Appendix A.16.

### 5.4 Lock toggle

**Steps.**
1. Select a card → **Lock**.
2. Try to drag.

**Expected.**
- Drag is blocked while locked.
- HUD shows the lock state.
- Unlock restores drag.

**On failure.** Appendix A.16.

### 5.5 Layout presets

**Steps.**
1. Settings → Layout → **Preset**.
2. Pick **Compact** or **Wide** or any non-current preset.

**Expected.**
- Dashboard recomposes to match the preset's slot template.
- Preset choice persists across restarts.

**On failure.** Appendix A.16.

### 5.6 Layout persistence

**Steps.**
1. After moving / resizing cards, restart the app.

**Expected.**
- Layout is preserved.
- Layout is per-profile (different profiles can have different layouts —
  see § 4).

**On failure.** Appendix A.2, A.16.

---

## 6. Companion

### 6.1 QR discovery

**Steps.**
1. With the display visible, get the phone QR scanner open.
2. Scan the CompanionCard QR.

**Expected.**
- Phone browser opens to `http://<display-host>:8082/c/<uuid>` (macOS)
  or `https://<hostname>.local/c/<uuid>` (Pi with Caddy + LANDFALL_DOMAIN).
- **URL must NOT be `127.0.0.1:8082`** — this is the "IP discovery acid
  test" (4b regression).
- Companion page loads and shows three buttons: **Pet**, **Play**, **Feed**.

**On failure.** Appendix A.12.

### 6.2 Pet / Play / Feed interactions

**Steps.**
1. Tap each of Pet, Play, Feed on the phone, one at a time, waiting for
   the animation to finish each time.

**Expected.**
- Each tap triggers the matching animation on the display within 2 s.
- Pet → affection animation.
- Play → playful animation; may award XP visible on the card.
- Feed → eating animation; hunger meter (if visible) decreases.

**On failure.** Appendix A.12.

### 6.3 Per-display identity

**Prerequisites.** Two displays online.

**Steps.**
1. Scan the QR on display A → companion page loads.
2. Scan the QR on display B → companion page loads.

**Expected.**
- The two companion pages have different `/c/<uuid>` paths.
- Each shows its own pet (potentially different rarity / name / level).
- Tapping Pet on phone A only affects display A.

**On failure.** Appendix A.12, A.15.

### 6.4 Network failure recovery

**Steps.**
1. Disconnect the phone from WiFi.
2. Reload the companion page.

**Expected.**
- Phone shows a clear "can't reach Landfall" message (not a generic
  Chrome "site can't be reached").
- Reconnecting and reloading restores function.

**On failure.** Appendix A.6, A.12.

---

## 7. Agent API

### 7.1 Mint API key

**Steps.**
1. On the server host, read the setup token:
   ```bash
   grep ^apiKeyManagementToken server/landfall_server/config/passwords.yaml
   ```
2. Mint a key (script or direct endpoint call — see
   [agent_integration_guide.md](agent_integration_guide.md)).

**Expected.**
- Plaintext key returned **once** in the response (`lf_...`).
- A `key_hash` (not plaintext) lands in `api_keys`. Verify with `psql`:
  ```sql
  SELECT key_prefix, scope FROM api_keys ORDER BY created_at DESC LIMIT 1;
  ```

**On failure.** Appendix A.11.

### 7.2 Push card

```bash
curl -X POST <server>/api/v1/cards \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "source":"e2e.basic",
    "title":"Test card",
    "body":"From E2E",
    "layout":"medium",
    "priority":"ephemeral"
  }'
```

**Expected.**
- HTTP 200 with the new card's `id`.
- Card appears on every signed-in display within 2 s.
- Title and body render correctly.

**On failure.** Appendix A.11.

### 7.3 Push card with actions

```bash
curl -X POST <server>/api/v1/cards \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "source":"e2e.actions",
    "title":"Action test",
    "body":"Tap me",
    "layout":"medium",
    "priority":"ephemeral",
    "actions":[{"type":"openUrl","label":"Open","payload":"https://example.com"}]
  }'
```

**Expected.**
- Card renders with an **Open** action button.
- Tapping opens `https://example.com` in the default browser.

**On failure.** Appendix A.11.

### 7.4 Push card with action — javascript: rejected

**Steps.**
```bash
curl -X POST <server>/api/v1/cards \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{"source":"e2e.xss","title":"XSS","body":"X","layout":"medium","priority":"ephemeral","actions":[{"type":"openUrl","label":"X","payload":"javascript:alert(1)"}]}'
```

**Expected.**
- HTTP 400 with a body indicating the URL scheme is not allowed (A05
  regression).
- No card appears on the display.

**On failure.** Appendix A.11.

### 7.5 actionsJson schema versioning

```bash
curl -X POST <server>/api/v1/cards \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{"source":"e2e.schema","title":"Schema","body":"X","layout":"medium","priority":"ephemeral","actions":{"schemaVersion":99,"actions":[]}}'
```

**Expected.**
- HTTP 400 with body `schemaVersion=99 is not supported` (commit `1e44e6e`).

**On failure.** Appendix A.11.

### 7.6 Dismiss card

**Steps.**
1. Push a card (§ 7.2).
2. Note its `id` from the response.
3. ```bash
   curl -X DELETE <server>/api/v1/cards/<id> \
     -H "Authorization: Bearer $KEY"
   ```

**Expected.**
- HTTP 200.
- Card disappears from every display within 2 s.

**On failure.** Appendix A.11.

### 7.7 Rate limit

**Steps.**
1. Fire 502 POSTs in quick succession with the same key:
   ```bash
   for i in $(seq 1 502); do
     curl -s -o /dev/null -w "%{http_code}\n" \
       -X POST <server>/api/v1/cards \
       -H "Authorization: Bearer $KEY" \
       -H "Content-Type: application/json" \
       -d '{"source":"e2e.rate","title":"r","body":"r","layout":"medium","priority":"ephemeral"}'
   done | sort | uniq -c
   ```

**Expected.**
- ~500 `200`s and at least one `429`.
- The `429` body reads `{"error":"Rate limit exceeded."}` — no
  reset-time leakage.

**On failure.** Appendix A.11.

### 7.8 Auth — missing header

```bash
curl -s -o /dev/null -w "%{http_code}\n" <server>/api/v1/cards
```

**Expected.**
- `401`.

**On failure.** Appendix A.11.

### 7.9 CORS — cross-origin denied

**Steps.**
1. Open Chrome DevTools console on any site **other** than the Landfall
   companion origin.
2. Run:
   ```js
   fetch('<server>/api/v1/cards', { headers: { Authorization: 'Bearer X' } })
   ```

**Expected.**
- The browser shows a CORS error.
- The response (if visible) is `401` with no `Access-Control-*` headers
  (commit `1928faf`).

**On failure.** Appendix A.11.

---

## 8. Settings

### 8.1 Accounts panel

**Steps.**
1. Settings → Accounts.

**Expected.**
- All linked Google / Microsoft accounts shown with email + provider icon.
- **Revoke** removes the account; the relevant CalendarCard reflects it
  within ~30 s.

**On failure.** Appendix A.4.

### 8.2 Theme panel

Covered in § 3.

### 8.3 Profile panel

Covered in § 4.

### 8.4 Layout panel

Covered in § 5.

### 8.5 Ambient dim

**Steps.**
1. Settings → Ambient → enable.
2. Set the dim schedule (e.g. 22:00 – 07:00).
3. Wait until the schedule kicks in (or temporarily set "from now" + 1 min).

**Expected.**
- Screen brightness ramps down over ~30 s.
- Tapping (or moving the mouse on macOS) wakes the screen.
- Dim ends at the configured "until" time.

**Per-platform notes.**
- macOS: simulated via overlay.
- Pi: uses real backlight control (`/sys/class/backlight/...`).
- Fire TV: simulated via overlay.

**On failure.** Appendix A.17 (ambient).

### 8.6 Location

**Steps.**
1. Settings → Location → type a city.

**Expected.**
- Geocoded; lat/lon stored.
- Weather and Forecast cards re-fetch for the new location within 2 min.

**On failure.** Appendix A.10.

---

## 9. License & packs

These exist as endpoints and screens but are **deferred** for the public
beta (no Stripe billing, no paid tiers enforced). Verify they render
without crashing.

### 9.1 License tier display

**Steps.**
1. Settings → License (or the relevant entry — naming may vary).

**Expected.**
- A tier label is visible (e.g. "Free" or "Beta").
- No Stripe checkout buttons; no payment surfaces.

**On failure.** Appendix A.18 (license).

### 9.2 Pack browser

**Steps.**
1. Open Pack Browser.

**Expected.**
- Loads without error.
- Listed packs (if any) render with name + description.
- No purchase flow is exposed.

**On failure.** Appendix A.18.

---

## 10. Resilience

### 10.1 Backend kill / recover

**Steps.**
1. On the server host: `docker compose kill server`.
2. Wait 30 s.
3. `docker compose ps`.
4. Watch the display.

**Expected.**
- `server` container shows `restarting` then `running` within ~60 s
  (Phase 4d regression — must not show `dead`).
- Display shows a soft "offline" indicator (no crash).
- After recovery, cards refresh within 30 s without app restart.

**Per-platform notes.**
- Pi (image): same applies for the in-Pi compose stack.

**On failure.** Appendix A.19 (resilience).

### 10.2 Network drop

**Steps.**
1. Disconnect the display's WiFi for 60 s.
2. Reconnect.

**Expected.**
- Cards show cached data while offline.
- Within 30 s of reconnect, fresh data flows back in.

**On failure.** Appendix A.6, A.19.

### 10.3 Power-cycle

**Steps.**
1. Pull power on the display device.
2. Wait 30 s.
3. Power on.

**Expected.**
- Pi: boots into kiosk within ~90 s; display shows dashboard.
- Fire TV: app does **not** auto-launch (Fire OS launcher takes over).
- macOS: app does not auto-launch (this is a desktop, not an appliance).
- No re-prompt for the setup wizard.
- Clock shows correct local time immediately (no UTC blink — 4c regression).

**On failure.** Appendix A.2, A.9.

### 10.4 Service crash loop

**Steps.**
1. On the Pi, deliberately break the compose file (e.g. set the server
   image to a nonexistent tag).
2. Wait for the openbox autostart 3-fast-crash threshold.

**Expected.**
- A `display_crash_loop` telemetry event posts to
  `LANDFALL_TELEMETRY_ENDPOINT` (if set).
- `landfall-bug-report` is producible by SSH.
- After restoring the compose file, the stack recovers on its own.

**On failure.** Appendix A.19, A.20 (Pi).

---

## 11. Cross-platform parity

Run these last, with all three platforms online against the same backend.

- [ ] Same agent card pushed via `curl` appears on all three displays
      within 2 s.
- [ ] Theme change on one display propagates to the other two within ~5 s.
- [ ] Profile activated on one display propagates.
- [ ] Companion entity is **per-display** — three different pets, three
      different `/c/<uuid>` paths.
- [ ] CalendarCard event counts match across all three (same backend → same
      data).
- [ ] PhotoFrameCard cycles the same images on all three (same source).

**On failure.** Appendix A.15.

---

## Sign-off

| Section | macOS | Pi | Fire TV | Notes |
|---------|-------|----|---------|-------|
| 1. Setup            |  |  |  |  |
| 2. System cards     |  |  |  |  |
| 3. Themes           |  |  |  |  |
| 4. Profiles         |  |  |  |  |
| 5. Layout editor    |  |  |  |  |
| 6. Companion        |  |  |  |  |
| 7. Agent API        |  |  |  |  |
| 8. Settings         |  |  |  |  |
| 9. License & packs  |  |  |  |  |
| 10. Resilience      |  |  |  |  |
| 11. Parity          |  —  |  —  |  —  |  |

Sweep is releasable when every row is green or every red cell has a
"deferred" note pointing to a tracked issue.

---

## Appendix A — Logging reference

Each subsystem has a known place to look when something goes wrong. Tests
above reference these by number.

### A.1 Display app — Flutter logs

**macOS**: launched from `start_mac.sh`; logs print to terminal.

```bash
bash tools/scripts/start_mac.sh   # leave the terminal open while testing
```

For a backgrounded run:

```bash
tail -f /tmp/landfall-display.log
```

**Pi**:

```bash
ssh landfall@<hostname>.local
journalctl --user -u landfall-display -f
```

**Fire TV**:

```bash
adb connect <fire-tv-ip>:5555
adb logcat | grep -i flutter
```

What to grep for: `[CardsCubit]`, `[ThemeCubit]`, `[ProfileCubit]`,
`[LayoutCubit]`, `[CompanionCubit]`, plus stack traces.

### A.2 Local persistence (Drift / SharedPreferences)

The display caches state to a Drift SQLite database.

**macOS**:

```bash
ls ~/Library/Containers/com.landfall.display/Data/Library/Application\ Support/
sqlite3 ~/Library/Containers/com.landfall.display/Data/Library/Application\ Support/landfall.sqlite '.schema'
```

**Pi**:

```bash
ls /home/landfall/.local/share/landfall/
sqlite3 /home/landfall/.local/share/landfall/landfall.sqlite '.schema'
```

**Fire TV** (debuggable build only):

```bash
adb shell run-as com.landfall.display ls databases/
```

Wipe + retest: see `--reset` flag (macOS) or `adb pm clear com.landfall.display`.

### A.3 Auth / OTP

Server-side OTP delivery:

```bash
grep -i otp /tmp/landfall-server.log | tail -20
# Look for:
#   [OTP] Code for <email>: <code>            -- OTP_LOG_CODES=true path
#   [OTP] SMTP delivery failed: <reason>      -- real SMTP error (cf56eb7)
```

Re-check SMTP config:

```bash
grep -E '^smtp' server/landfall_server/config/passwords.yaml
```

The `smtpFromEmail` value **must** match the Gmail account being
authenticated, or Gmail rejects (cf56eb7).

### A.4 Calendar (Google / Microsoft)

```bash
grep -E 'Calendar|OAuth|refresh' /tmp/landfall-server.log | tail -40
```

Refresh failures emit a structured `LANDFALL_CREDENTIAL_REFRESH_FAILED`
marker. `landfall-doctor` parses it.

```bash
ssh landfall@<hostname>.local landfall-doctor
```

Database:

```bash
psql -h <db-host> -U landfall -d landfall \
  -c "SELECT id, provider, account_email, consecutiveRefreshFailures, lastRefreshErrorKind FROM linked_credentials;"
```

### A.5 OAuth callbacks

The callback URL **must** match what is registered with Google Cloud
or Microsoft. Common failures:

- macOS dev: `http://127.0.0.1:8082/calendar/oauth/callback` must be in
  the Google Cloud OAuth client.
- Pi (image): `https://<hostname>.local/calendar/oauth/callback` must be
  in both Google Cloud and Caddy's reverse-proxy config.

Caddy logs:

```bash
docker logs landfall-caddy-1 2>&1 | tail -40
```

(Note: container name depends on compose project. Check `docker ps`.)

### A.6 Networking

```bash
# From the display host:
curl -v <server>/card/getCards -X POST -H 'Content-Type: application/json' -d '{}'

# Check mDNS resolution:
dig +short <hostname>.local
ping -c 3 <hostname>.local
```

Firewall — server must be reachable on `:8080` (display) and `:8082`
(companion).

### A.7 Photos (Drive)

```bash
grep -i 'photo\|drive\|service.account' /tmp/landfall-server.log | tail -40
```

Verify provider in DB:

```bash
psql -h <db-host> -U landfall -d landfall \
  -c "SELECT id, provider, folder_id FROM photo_sources;"
```

`provider='google-sa'` is the SA path; `'google-oauth'` is the
per-user path.

Drive folder permissions: the SA email (from the JSON keyfile) must have
**Viewer** on the folder.

### A.8 Postgres direct access

```bash
# macOS dev (Docker compose):
docker compose exec postgres psql -U landfall -d landfall

# Pi (image):
ssh landfall@<hostname>.local docker compose -f /home/landfall/landfall/deploy/docker-compose.yml exec postgres psql -U landfall -d landfall
```

### A.9 Time sync

**macOS**:

```bash
date
sntp -sS time.apple.com
```

**Pi**:

```bash
timedatectl
# Must show: NTP synchronized: yes
journalctl -u systemd-time-wait-sync -b
```

If "Synchronized: no", `landfall-firstboot` should have waited on this —
check that the unit is gated correctly (4c regression).

**Fire TV**: Settings → My Fire TV → About → Date & Time.

### A.10 Weather (OpenWeatherMap)

```bash
grep -i 'weather\|owm' /tmp/landfall-server.log | tail -20
```

Test the OWM key directly:

```bash
KEY=$(grep ^openWeatherMapApiKey server/landfall_server/config/passwords.yaml | cut -d"'" -f2)
curl "https://api.openweathermap.org/data/2.5/weather?q=Seattle&appid=$KEY"
```

A 401 means the key is wrong / unactivated.

### A.11 Agent API

```bash
grep -iE 'api[_/]v1|api_key|rate.limit' /tmp/landfall-server.log | tail -40
```

Check the key by prefix (the table only stores hashes):

```bash
psql -h <db-host> -U landfall -d landfall \
  -c "SELECT key_prefix, scope, created_at, last_used_at FROM api_keys ORDER BY created_at DESC;"
```

### A.12 Companion

```bash
grep -iE 'companion|/c/' /tmp/landfall-server.log | tail -40
```

The display side runs in the same Flutter process — see A.1.

The companion phone page is served by Caddy (Pi) or the server's
`:8082` listener (macOS). For the URL-discovery bug:

```bash
# On the display host:
ip addr show | grep 'inet '       # macOS / linux
# Find the LAN IP. The companion URL embedded in the QR must match this,
# not 127.0.0.1.
```

### A.13 Themes

```bash
grep -iE 'theme|token' /tmp/landfall-server.log | tail -40
```

Validate a theme YAML locally before importing:

```bash
melos run validate-theme -- path/to/theme.yaml
```

### A.14 Profiles

```bash
grep -i 'profile' /tmp/landfall-server.log | tail -40
```

```bash
psql -h <db-host> -U landfall -d landfall \
  -c "SELECT id, name, active FROM profiles ORDER BY active DESC, name;"
```

### A.15 Cross-display sync

The server pushes updates via WebSockets. If display B is not following
display A:

```bash
grep -iE 'websocket|broadcast|fanout' /tmp/landfall-server.log | tail -40
```

Verify both displays are signed in to the same backend:

```bash
psql -h <db-host> -U landfall -d landfall \
  -c "SELECT id, display_id, last_seen_at FROM display_sessions ORDER BY last_seen_at DESC;"
```

### A.16 Layout

```bash
grep -iE 'layout|slot' /tmp/landfall-server.log | tail -40
```

```bash
psql -h <db-host> -U landfall -d landfall \
  -c "SELECT profile_id, preset, payload_version FROM layouts;"
```

### A.17 Ambient dim

**macOS / Fire TV**: the dim is an overlay widget — check display logs
(A.1) for `AmbientCubit`.

**Pi**: real backlight control:

```bash
ssh landfall@<hostname>.local
cat /sys/class/backlight/*/brightness
cat /sys/class/backlight/*/max_brightness
```

### A.18 License & packs

```bash
grep -iE 'license|pack|stripe' /tmp/landfall-server.log | tail -40
```

Stripe-related code is deferred — no real billing. If logs show Stripe
calls in a beta build, that's a bug.

### A.19 Container resilience

```bash
docker compose ps                              # running / restarting / dead
docker compose logs --tail=200 server          # server crash reason
docker inspect --format '{{.State.Health.Status}}' <container-id>
docker events --since 10m                      # recent restart events
```

### A.20 Pi-specific

```bash
# Crash bundle (Pi only):
ssh landfall@<hostname>.local landfall-bug-report
# Produces /tmp/landfall-bug-report-<timestamp>.tgz

# Kiosk autostart:
journalctl -u landfall-firstboot -b
journalctl --user -u landfall-display -b

# Hardware:
vcgencmd measure_temp
vcgencmd get_throttled                         # 0x0 means no throttle
```

See [debugging_pi.md](debugging_pi.md) for the full Pi-side playbook.

---

## Appendix B — Per-platform divergences

A quick reference for behaviours that legitimately differ across
platforms. **Not bugs** — design choices.

| Behaviour | macOS | Pi | Fire TV |
|-----------|-------|----|---------|
| App auto-launch on boot | No | **Yes** (kiosk) | No (Fire OS launcher) |
| Window can resize | Yes | No (fullscreen) | No (fullscreen) |
| Mouse / touch drag in layout editor | Yes | Touch only | No (D-pad nav only) |
| Companion URL host | LAN IP | mDNS via Caddy | LAN IP of backend |
| Server URL auto-detect in wizard | Yes | No | No |
| Ambient dim implementation | Overlay | Real backlight | Overlay |
| Setup-token gate for API key mint | dev `.env` | image `.env` | n/a (no server on Fire TV) |
| Crash bundle auto-ship | n/a | Yes (when `LANDFALL_TELEMETRY_ENDPOINT` set) | n/a |

---

## For AI assistants

A few things worth knowing about this document:

- **This is the exhaustive feature pass**, not the release gate. The
  release gate is [`manual_smoke_test.md`](manual_smoke_test.md). Don't
  conflate them. Both should exist.
- **Steps reference Appendix A by section number** (`A.4`, `A.11`, …).
  When adding a new test, either reuse an existing appendix entry or add
  a new one and link it from the test.
- **Per-platform divergences live in Appendix B.** Before flagging a
  difference as a bug, check the table — it may be by design.
- **When a feature is added**, add the test here in the same PR that adds
  the feature. The TDD rule in [CLAUDE.md](../CLAUDE.md) covers the
  automated tests; this doc covers human validation.
- **When a feature is removed**, delete the test here and any orphan
  appendix entries.
- **Real commit hashes** (`cf56eb7`, `7ced66b`, `1928faf`, `1e44e6e`,
  `d93d1a5`, `1e44e6e`) are regression anchors — when a test cites a
  commit, the test is verifying that fix did not regress. Do not
  remove the citation when refactoring.
