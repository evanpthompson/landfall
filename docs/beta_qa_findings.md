# Beta QA Findings

Open bugs and validation items found during beta QA. Unlike
[`beta_known_limitations.md`](beta_known_limitations.md) (intentionally
deferred, shipped-as-is), everything here is a **bug to fix or a thing to
verify before the beta is signed off**.

Work top-to-bottom. Check a box when the item is fixed *and* re-verified.
When an item lands, move it out of this file (or delete it) in the same
commit that fixes it.

Detailed specs and the session-by-session fix plan for these items live
in [`beta_release_plan.md`](beta_release_plan.md).

---

## Accounts / Google Calendar

- [x] **Connect URL targeted the wrong port (8080).** FIXED — the
      accounts tab built the OAuth connect URL from the API base (`:8080`);
      the routes live on the web server (`:8082`). Added a `webServerUrl`
      param to `AccountsTabView`; companion derives it from the page origin
      (`companionWebOriginFromPage`), native TV from `companionWebServerUrl`
      (API+2). Covered by `accounts_tab_view_test.dart` +
      `companion_url_test.dart`.
- [x] **OAuth start 401 from the companion "Open" flow.** FIXED via the
      secure ticket model (Option B). `SettingsEndpoint.createCalendarLinkTicket`
      mints a short-lived, single-use ticket bound to the JWT-derived
      `authUserId` (SEC-06); both OAuth start routes exchange `?ticket=` for
      that identity and no longer trust any query-param `authUserId`. The
      static `calendarOauthSetupToken` path was removed. Companion mints the
      ticket on tap. Tests: `calendar_link_ticket_test.dart`,
      `oauth_route_test.dart`, `settings_endpoint_test.dart`,
      `accounts_tab_view_test.dart`.
  - [x] Verification steps written into `manual_smoke_test.md` (§2.10
        native, §7.6 companion, §4.4 Fire TV, plus calendar empty-state
        checks in §2.3). Hardware E2E still needs a Google-resolvable
        redirect domain — see `self_hosting_guide.md` → "OAuth without a
        public domain".

## Calendar card / rendering

- [x] **2-week & daily views rendered blank with no events.** FIXED — the
      daily and 2-week views were event-list layouts that collapsed to a
      bare heading when empty. Daily now always shows today's date plus a
      "No events scheduled today" note; the 2-week view always renders the
      full 14-day scaffold (each day's date/label) and buckets events into
      it. Monthly/weekly already always render their grids. Covered by
      `calendar_card_test.dart`; goldens regenerated.

## Themes (companion)

- [x] **Themes page squished / Apply buttons clipped.** FIXED — the
      `_Footer` row clipped the Apply button at narrow widths and the
      preview-strip mini tiles overflowed horizontally. Footer Apply is now
      flex-protected (badge ellipsizes); mini tiles wrapped in `FittedBox`;
      the browser grid pins card height (`mainAxisExtent`) so Apply is always
      visible at ≤390px. `theme_card.dart`, `theme_preview_strip.dart`,
      `theme_browser_screen.dart`.
- [x] **Marketplace removed entirely.** FIXED — the theme browser is now a
      single Themes view (no Installed/Marketplace tabs, no prices, no
      Free/Owned/Purchase). Deleted the marketplace cubit/state, the
      marketplace card + detail sheet, and the app-side marketplace
      repository; removed the `MarketplaceCubit` providers from `app.dart`
      and `companion_web_main.dart`. `theme_browser_screen.dart` rewritten;
      stale "browse the marketplace" prompt in `profile_manager_screen.dart`
      reworded. 812 app tests pass, analyze clean.
- [x] **Theme changes didn't apply to the dashboard.** FIXED — the
      companion built `ThemeCubit` **without** a `profileRepository`, so
      `applyTheme` ran with `profileId: null`, which `ThemeEndpoint.applyTheme`
      treats as a no-op (nothing persisted → TV never updates). The companion
      now passes the `profileRepository` it already constructs, matching the
      TV (`companion_web_main.dart`). Cubit contract already covered by
      `theme_cubit_test.dart`; add a manual smoke check (companion apply →
      TV repaints).
- [x] **Companion card background stayed black.** FIXED — `companion_card.dart`
      hardcoded `Color(0xFF111318)`; now uses the active theme's
      `tokens.cardFill`, so the TV companion card tracks the theme. (The
      phone companion chrome in `companion_mobile_screen.dart` is a
      deliberately self-styled mini-app, left as-is.)

## Weather

- [x] **Full-color weather icons.** FIXED — replaced the monochrome Material
      glyphs with full-colour **Meteocons** PNGs (Bas Milius, **MIT** —
      `apps/display/assets/weather/LICENSE`), with day/night variants per OWM
      code. `WeatherCard.meteoconAssetFor` maps codes → assets and
      `WeatherCard.weatherIcon` renders them, falling back to the old glyph
      (`weatherIconData`) for unknown codes. Swapped in `weather_card.dart`,
      `current_weather_card.dart`, `forecast_strip_card.dart`. Covered by
      `weather_icon_test.dart` + updated card tests; 820 app tests pass.
      Note: assets ship in the shared pubspec, so the companion web bundle
      grows slightly — re-verify `deploy` expected-components on next build.

## Companion

- [ ] **Create + swap the companion animation asset.** The live companion
      sprite sheet is `apps/display/assets/companions/lumen.webp`
      (referenced from `companion_card.dart` and `companion_mobile_screen.dart`).
      A new asset needs to be created and swapped in. It must match the
      sprite spec the renderer expects (`petdex_provider.dart`):
  - Frame size: **192 × 208 px** per frame.
  - **9 rows**, one per animation state, in this order with these frame
    counts: idle (6), play (8), playLeft (8), pet (4), reactCelebratory (5),
    reactUrgent (8), idleCalm (6), playSprint (8), lookAtViewer (6).
  - Sheet ≥ 1536 px wide (8 frames × 192) × 1872 px tall (9 rows × 208),
    `.webp`, left-aligned frames per row.
  - After swapping, regenerate the companion goldens
    (`companion_mobile_screen.png`, `companion_card.png`).

---

## For AI assistants

- This is the live beta-bug list. Real bugs go here; *intentionally*
  deferred items go in [`beta_known_limitations.md`](beta_known_limitations.md).
- Before fixing, reproduce against current code — handover notes go stale.
- When an item is fixed and re-verified, remove it here in the same commit.
- Follow the TDD rules in [`../CLAUDE.md`](../CLAUDE.md): failing test first.
