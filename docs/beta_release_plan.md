# Beta Release Plan — QA Fix Sessions

Detailed specs and a session-by-session plan for clearing the items in
[`beta_qa_findings.md`](beta_qa_findings.md) before the public beta.

Each session follows the TDD rules in [`../CLAUDE.md`](../CLAUDE.md):
write the failing test first, then the minimum code, then refactor.
Every session lists its tests *before* its production changes.

Sessions are ordered by risk and dependency. Recommended order:
**1 → 2 → 3 → 4 → 5**. Sessions 4 and 5 are independent and can be done
in any order / in parallel.

| # | Session | Why this slot | Est. |
|---|---------|---------------|------|
| 1 | Calendar OAuth wiring + verification | Accounts are broken on direct-port; blocks calendar testing | M |
| 2 | Calendar card empty states + view fixes | Daily/2-week render blank; depends on real events from S1 | M |
| 3 | Companion themes overhaul | Largest surface (4 sub-bugs); user-facing | L |
| 4 | Full-color weather icons | Isolated visual upgrade | S |
| 5 | Companion animation asset swap | Asset creation + wiring; independent | S–M |

---

## Session 1 — Calendar OAuth wiring + verification

> **Status (landed):** Both the port-wiring fix and the secure auth path
> are implemented and green.
> - Port wiring: `AccountsTabView` takes `webServerUrl` (companion: page
>   origin via `companionWebOriginFromPage`; native TV: `companionWebServerUrl`).
> - Auth (Option B, the SEC-06-compliant choice): `createCalendarLinkTicket`
>   mints a short-lived single-use ticket bound to the JWT-derived
>   `authUserId`; both OAuth start routes consume `?ticket=` and never trust
>   a query-param identity; the static `calendarOauthSetupToken` path was
>   removed; companion mints on tap. Self-hosting guide + `.env.example`
>   updated. Server suite (279 unit + oauth/settings integration) green,
>   app suite green, analyze clean.
> - **Remaining:** write the smoke-test verification steps; hardware E2E
>   still needs a Google-resolvable redirect domain.

### Problem
On the companion Settings → Accounts tab the Google/Microsoft "Connect"
URLs point at the **API server port (8080)**, but the OAuth routes are
registered on the **web server (8082)**. Direct-port access (dev Mac, Pi
without Caddy) hits a non-existent route. Behind Caddy (port 80/443) it
happens to work because both are served from one origin.

### Root cause (grounded)
- `apps/display/lib/companion_web_main.dart:42-44` — `serverUrl` is
  derived as the **API** URL: when on the web port it computes
  `host:(port-2)` → `:8080`. That value is correct for the Serverpod
  RPC `Client`, but it is the *wrong* base for OAuth links.
- `apps/display/lib/src/features/settings/screens/web_settings_screen.dart:124`
  passes that same `serverUrl` into `AccountsTabView`.
- `apps/display/lib/src/features/settings/widgets/accounts_tab_view.dart:108-111`
  builds `${base}calendar/oauth/start?authUserId=$userId` from it.
- `server/landfall_server/lib/server.dart:77` registers
  `CalendarOAuthStartRoute` on `pod.webServer` (8082), not the API server.

### Secondary risk to verify
`CalendarOAuthStartRoute` (`calendar_oauth_route.dart:57-92`) requires
`session.authenticated` **or** a `setup_token` query param. The accounts
tab URL includes `authUserId` but **not** `setup_token`, and opening the
link in a new browser tab/window will not carry the companion's JWT
(Serverpod auth is header-based, not cookie-based). So even on the
correct port the "Open" button may 401. Confirm on hardware; if it
401s, wire the `calendarOauthSetupToken` path (server already supports
it) or open the OAuth flow in-session.

### Fix
- Introduce a **web-server base URL** for OAuth links, distinct from the
  RPC `serverUrl`. Cleanest: pass a `webServerUrl` into `AccountsTabView`
  computed in `companion_web_main.dart` (on default port = same origin;
  on direct port = `host:port` of the web server itself, i.e. the page's
  own origin, since the companion is *served* from 8082).
- Update `web_settings_screen.dart` and `settings_screen.dart` callers.
- If verification shows the 401: thread `setup_token` into the URL from a
  server-provided value, or switch "Open" to an in-app authenticated
  redirect.

### Tests first
- Test: `AccountsTabView` builds the Google/Microsoft connect URL from
  the **web** base, not the API base → Code: add `webServerUrl` param +
  use it for URL construction.
- Test: `companion_web_main` URL derivation maps {default port, direct
  8082} → correct web base → Code: extract a pure helper and unit-test it.
- Integration: existing `calendar_oauth_route` test still green; add a
  case asserting `setup_token` path if adopted.

### Acceptance / verification steps (write into the smoke test)
1. Connect a Google account from the companion on a **direct-port** Pi
   (no Caddy): the Open/Copy URL resolves to a real page, not a 404.
2. Complete consent → confirmation page shows the connected email.
3. `LinkedCredential` row exists server-side and `isActive = true`.
4. `CalendarRefreshCall` pulls events; they render on the TV display.
5. Repeat behind Caddy to confirm no regression on the same-origin path.

---

## Session 2 — Calendar card empty states + view fixes

> **Status (empty-state portion landed):** Daily now always shows today's
> date + a no-events note; the 2-week view always renders the full 14-day
> scaffold and buckets events into it. `calendar_card_test.dart` covers the
> empty cases; goldens regenerated; analyze clean. (The companion view-value
> selector mapping check remains as future verification, but the default →
> biweekly routing is confirmed correct.)

### Problem
Selecting the **2-week** range shows nothing; **daily** is also blank;
**monthly** works. The user wants the calendar grid visible even with no
events.

### Root cause (grounded)
`apps/display/lib/src/features/calendar/widgets/calendar_card.dart`:
- `_DailyView` (l.64) and `_BiweeklyView` (l.230) are **event-list**
  layouts: a label + an `Expanded(ListView.builder(itemCount: grouped.length))`.
  With zero events in-window, `grouped` is empty → the card renders only a
  tiny label, i.e. visually blank.
- `_MonthlyView` (l.430) renders a full **grid** regardless of events, so
  it "works" even when empty.
- View switch (l.33-38): `'daily'`, `'weekly'`, `'monthly'`, default →
  `_BiweeklyView`. **Verify** what value the settings UI sends for the
  2-week option — if it sends a named value with no matching case it
  still lands on the biweekly default, so the blankness is the empty-list
  issue, not a routing miss. Confirm the settings→`displayConfig['view']`
  mapping in `web_display_tab.dart` / layout config.

### Fix
- Add an **empty state** to `_DailyView` and `_BiweeklyView`: when
  `grouped.isEmpty`, render a friendly "No events" panel. For 2-week,
  prefer always rendering a lightweight day scaffold (the next 14 day
  rows) so the card never collapses to a label.
- Confirm/repair the view-value mapping so the 2-week option resolves
  deterministically (consider giving it an explicit `'biweekly'` case
  rather than relying on `default`).

### Tests first
- Test: `_DailyView` with `events: []` shows the empty-state widget →
  Code: add empty branch.
- Test: `_BiweeklyView` with `events: []` shows the 14-day scaffold /
  empty state → Code: add empty branch.
- Test: view-value mapping — `displayConfig['view'] == '<2-week value>'`
  resolves to the biweekly layout → Code: explicit case.
- Golden: daily-empty, biweekly-empty at 1920×1080.

### Acceptance
With a connected calendar that has no upcoming events, daily and 2-week
both render a visible calendar surface (not a blank card); with events,
all four views populate.

---

## Session 3 — Companion themes overhaul

> **Status (landed):** All four sub-bugs fixed and green (848 app tests,
> analyze clean).
> - 3a squished/Apply clipped: footer Apply flex-protected, preview-strip
>   mini tiles wrapped in `FittedBox`, browser grid pins card height.
> - 3b marketplace **removed entirely**: single Themes view, no tabs, no
>   prices/Free/Owned/Purchase. Deleted marketplace cubit/state/card/detail
>   sheet + app-side repo and providers.
> - 3c not-applying: companion `ThemeCubit` now gets `profileRepository`
>   (was applying with null profileId → server no-op).
> - 3d black card: `companion_card.dart` uses `tokens.cardFill`.
> Smoke-test steps added (§7.5b).

Four sub-bugs on the companion themes experience. Group them; they touch
the same files.

### 3a. Themes page squished / Apply buttons not visible
**Problem:** Theme tiles are cramped and the Apply action below the tiles
is cut off on the companion (≤390px) viewport.
**Where:** `apps/display/lib/src/features/theme/screens/theme_browser_screen.dart`
(grid sizing) and `theme_detail_sheet.dart` (apply action). Related to
the open 390px overflow item (Task #3) in
[`beta_qa_findings.md`](beta_qa_findings.md).
**Fix:** Responsive grid (fewer columns / taller tiles at narrow width);
ensure the Apply button is always on-screen (pin to sheet footer or make
the list scrollable with a sticky action).
**Tests:** widget test asserts Apply button is hittable at 390×844;
regenerate web goldens at true 390×844 after fix.

### 3b. Remove marketplace purchasing + prices
**Problem:** The themes browser presents a paid-marketplace UI (prices,
purchase flow) that should not ship for beta.
**Where:** `apps/display/lib/src/features/theme/widgets/marketplace_theme_card.dart`
— `_PriceBadge` (l.77-112) renders `entry.displayPrice`. Also
`theme_detail_sheet.dart` (purchase CTA) and `marketplace_cubit.dart` /
`marketplace_state.dart`.
**Fix:** Treat all themes as free/owned for beta: drop the price badge
(keep an optional "Owned/Applied" indicator), and replace any "Buy" CTA
with "Apply". Decide whether to hard-remove the purchase path or feature-
flag it off — recommend feature-flag so the marketplace can return later.
**Tests:** widget test asserts no price text renders and the CTA reads
"Apply"; cubit test for the flagged-off path.

### 3c. Theme changes don't apply to the dashboard
**Problem:** Applying a theme in the companion doesn't update the TV.
**Mechanism that exists:** companion fires `onPush('theme.changed')`
(`web_settings_screen.dart:122`); the display handles it via
`display_action_service.dart:79` → `_themeReloader.loadThemes()`.
**Leading hypothesis (verify):** the companion's apply updates only its
**local** `ThemeCubit` and never persists the new active theme
server-side, so the TV's `loadThemes()` re-pulls the *old* active theme.
Trace the apply path in `theme_browser_screen.dart` /
`theme_detail_sheet.dart` → does it call a server endpoint that sets the
active theme? If not, that's the bug.
**Fix:** Ensure "Apply" persists the active theme server-side **before**
the `theme.changed` push fires; confirm `ThemeReloader.loadThemes()`
reads that persisted value.
**Tests:** integration — apply theme on companion → server active theme
updated → `theme.changed` consumed → display theme matches. Bloc test on
the reloader path.

### 3d. Companion card background stays black
**Problem:** The companion card's background does not follow the theme
background color.
**Root cause (grounded):** `apps/display/lib/src/features/companion/widgets/companion_card.dart:144`
hardcodes `const bgColor = Color(0xFF111318);` instead of a theme token.
**Fix:** Replace with a token — `tokenColor(tokens.cardFill)` (to match
other cards) or `tokens.backgroundValue` if the design intends the page
bg. Confirm contrast for the sprite/QR content over light themes.
**Tests:** widget test asserts the card's `DecoratedBox` color equals the
active theme token (parameterize over a light and a dark theme);
regenerate companion goldens.

### Acceptance (whole session)
On a ≤390px companion: tiles readable, Apply always reachable, no
prices/purchase UI, applying a theme repaints the TV dashboard, and the
companion card background tracks the theme.

---

## Session 4 — Full-color weather icons

> **Status (landed):** Replaced monochrome glyphs with full-colour
> **Meteocons** PNGs (MIT) under `assets/weather/`, day/night per OWM code,
> via `WeatherCard.meteoconAssetFor` + `WeatherCard.weatherIcon` (glyph
> fallback retained). Tests in `weather_icon_test.dart` + updated card tests;
> 820 app tests pass, analyze clean. Smoke test §2.3 covers the visual check.

### Problem
Weather icons are monochrome Material glyphs; the user wants full-color
weather icons.

### Root cause (grounded)
`apps/display/lib/src/features/weather/widgets/weather_card.dart:138`
`weatherIconData(code)` maps OWM codes to monochrome `IconData`
(`Icons.wb_sunny`, etc.), rendered tinted (`current_weather_card.dart:69-73`
uses `color: textSecondary`; `forecast_strip_card.dart` similarly).

### Fix
- Add a full-color icon set (asset-based — SVG or PNG sprite per OWM
  condition group, day/night variants via the `d`/`n` suffix in the
  code). Place under `apps/display/assets/weather/` and declare in
  `pubspec.yaml`.
- Add a `weatherIcon(code)` widget helper returning the colored asset;
  keep `weatherIconData` as a fallback for missing assets.
- Swap usages in `current_weather_card.dart` and `forecast_strip_card.dart`.

### Tests first
- Test: `weatherIcon` resolves each OWM prefix (01–04, 09, 10, 11, 13,
  50) and day/night variants to the right asset → Code: mapping + widget.
- Test: unknown code falls back gracefully → Code: fallback branch.
- Golden: current + forecast cards at 1920×1080 with the new icons.

### Acceptance
Current and forecast weather render full-color condition icons with
correct day/night variants across all OWM groups.

---

## Session 5 — Companion animation asset swap

### Problem
The live companion sprite sheet is a placeholder; a new animation asset
must be created and swapped in.

### Spec the asset must meet (from `petdex_provider.dart`)
- Active asset: `apps/display/assets/companions/lumen.webp`, referenced
  from `companion_card.dart:17` and `companion_mobile_screen.dart:61`.
- Frame size: **192 × 208 px** per frame
  (`petdex_provider.dart:24-27`).
- **9 rows**, in order, with these frame counts:
  idle (6), play (8), playLeft (8), pet (4), reactCelebratory (5),
  reactUrgent (8), idleCalm (6), playSprint (8), lookAtViewer (6).
- Sheet ≥ **1536 px** wide (8 × 192) × **1872 px** tall (9 × 208),
  `.webp`, frames left-aligned per row.

### Fix
- Create the asset, drop it at the existing path (or a new name + update
  the two references).
- If frame counts/rows differ from the new art, update
  `petdex_provider.dart` to match — keep the renderer and sheet in lockstep.

### Tests first
- Test: `PetdexProvider.specFor` returns the expected row/frameCount for
  every state (locks the contract) → Code: any provider change.
- Golden: `companion_mobile_screen.png` and `companion_card.png`
  regenerated with the new asset.

### Acceptance
Companion animates correctly for every trigger state on TV and companion;
goldens updated; `flutter analyze` + `flutter test` green.

---

## For AI assistants
- This is the plan; the live checklist is
  [`beta_qa_findings.md`](beta_qa_findings.md). Tick items there as
  sessions land.
- Re-verify every "grounded" file:line before editing — line numbers
  drift. Hypotheses marked "verify" are not yet confirmed against runtime.
