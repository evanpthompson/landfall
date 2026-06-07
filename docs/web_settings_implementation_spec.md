# Web Settings — Implementation Specification

**Status:** Reviewed and ready for implementation
**Date:** 2026-06-07
**Supersedes:** the standalone `/layout/` web-app plan and the standalone `/settings/` web-app plan. The chosen architecture is **Option B: settings folded into the existing companion web app** served at `/c/{displayId}`.

This spec turns the agreed 4-phase plan into a per-phase implementation contract. Every
claim below was re-verified against the codebase at commit `4030307` on 2026-06-07; file
and line references are current as of that commit.

---

## 1. Goal and locked decisions

Let a phone or laptop browser manage every Landfall setting that the Fire TV / Pi
settings screen manages today, without requiring a Mac, ADB, or physical access to the TV.

Decisions already made (do not re-litigate):

1. **Auth from day one.** Every settings-relevant endpoint requires a valid JWT before
   Phase 2 ships any UI. Static assets are *not* auth-gated — the login wall lives in
   the Flutter web app; the data lives behind `_requireAuth`.
2. **Option B.** No new server route, no new Flutter web build target. The settings UI
   is added to `apps/display/lib/companion_web_main.dart`'s app behind a gear icon.
   Entry remains the QR code on the companion card → `/c/{displayId}`.
3. **Auth mechanism is serverpod_auth_core JWT** — there are no session cookies in this
   system. Web sign-in is in-app OTP: `client.otp.sendCode(email)` →
   `client.otp.verifyCode(email, code)` → `AuthSuccess` stored client-side. The
   device-code flow (RFC 8628) is *not* used on web — it exists only because TVs can't type.
4. **TDD per `CLAUDE.md`** — every phase below lists tests before production code, and a
   phase is not done until `flutter analyze` and `flutter test` are green across packages
   plus the server test suite passes.

---

## 2. Verified codebase facts (audit results)

| # | Fact | Evidence |
|---|------|----------|
| F1 | `AuthCubit` already implements the full OTP flow (`sendCode`/`verifyCode`/`resendCode`/`signOut`) against `client.otp.*` and a `ClientAuthSessionManager`. It is **client-storage-agnostic** and reusable on web as-is. | `apps/display/lib/src/features/auth/cubit/auth_cubit.dart:47-93` |
| F2 | JWT refresh is **not** baked into `AuthCubit` — it is handled by `ClientAuthSessionManager`, which implements `RefresherClientAuthKeyProvider`; the generated client auto-refreshes the 10-minute access token. The handover's open question is answered: **no extra refresh work is needed on web.** | `apps/display/lib/app.dart:77-84` |
| F3 | `serverpod_auth_core_client` ships `KeyValueClientAuthSuccessStorage` + a tiny abstract `KeyValueStorage` (get/set of strings). A web localStorage adapter is ~15 lines — **no custom `ClientAuthSuccessStorage` implementation needed.** | `~/.pub-cache/.../serverpod_auth_core_client-3.4.6/lib/src/storage/key_value_client_auth_success_storage.dart` |
| F4 | `LayoutEditor` is web-safe (imports only flutter / landfall_shared / ui_kit) and the whole layout/profile chain is server-backed: `DashboardProfileCubit` → `ServerpodProfileRepository` → `client.profile.*`. Web Layout tab is reuse, not rebuild. | `apps/display/lib/src/features/settings/widgets/layout_editor.dart`, `apps/display/lib/app.dart:86` |
| F5 | Unguarded endpoints today: `ThemeEndpoint` (**all six methods**), `LayoutEndpoint.getLayouts`, `ProfileEndpoint.listProfiles`, `WeatherEndpoint`, `GreetingEndpoint`. Guarded: profile writes, layout writes, settings, calendar, photo, card (SEC-01). `CompanionEndpoint` and `MarketplaceEndpoint` reads are anonymous **by design**. | `server/landfall_server/lib/src/theme/theme_endpoint.dart`, `layout/layout_endpoint.dart:21`, `profile/profile_endpoint.dart:18` |
| F6 | The TV settings screen has five tabs — Display, Accounts, Layout, Themes, License — all implemented as **private classes** in one 1025-line file. `_LayoutTab` (line 680), `_ThemesTab` (758), `_AccountsTab` (418), `_DisplayTab` (171), `_LicenseTab` (965 — a one-line wrapper around the public `LicenseTab`). | `apps/display/lib/src/features/settings/screens/settings_screen.dart` |
| F7 | The Display tab holds **four** device-local surfaces, not three: dim schedule, location, photo sources, **and Server address** (`ChangeServerScreen`). The plan had missed Server address. | `settings_screen.dart:240-251` |
| F8 | `DisplaySettings` (local Drift) fields: `dimEnabled`, `dimStartHour`, `dimEndHour`, `dimLevel`, `locationName`, `serverUrl`, `wizardComplete`, `displayId`, `photoSourceJson`. | `packages/landfall_shared/lib/src/models/settings/display_settings.dart` |
| F9 | The phone→TV channel is `CompanionEndpoint.pushAction` / `pollForEvents` long-poll, in-memory, **single-consumer** (one waiter is woken per action). The poll loop currently lives **inside `CompanionCard`** — it only runs when the companion card is on the active layout. | `server/landfall_server/lib/src/companion/companion_endpoint.dart:66-131`, `apps/display/lib/src/features/companion/widgets/companion_card.dart:110-125` |
| F10 | The QR code that opens `/c/{displayId}` is rendered **only on the companion card** — there is no other on-TV entry point to the web app. | `companion_card.dart:288,345` |
| F11 | Caddy proxies to the API server (8080) **only** for `/api/*`, `/card/*`, `/agent/*`, `/calendar/*`, `/companion(/*)`, `/websocket`; everything else falls through to the web server (8082). Serverpod endpoint calls are path-based on the endpoint name, so **every endpoint the settings UI calls needs a matcher** or it will 404 behind Caddy while working on `:8082`/`:8080` direct. | `deploy/Caddyfile` |
| F12 | Generated-client endpoint route names (= URL path segments): `otp`, `jwtRefresh`, `passkeyIdp`, `layout`, `profile`, `theme`, `marketplace`, `settings`, `apiKey`, `license`, `pack`, `photo`, `weather`, `greeting`, `card`, `agent`, `calendar`, `companion`. | `server/landfall_client/lib/src/protocol/client.dart` (`String get name =>` occurrences) |
| F13 | The companion web build (`melos flutter_build` in `server/landfall_server/pubspec.yaml`) targets `companion_web_main.dart`, `--base-href /app/`, output `web/app/`; `deploy/pi-gen/build.sh` rebuilds it, strips the service worker, and verifies `useLocalCanvasKit`. `expected-components.yaml` pins the `web/app` contents. | `server/landfall_server/pubspec.yaml:49-60`, `deploy/pi-gen/build.sh:186-210,448-450` |
| F14 | `companion_web_main.dart` reads `window.LANDFALL_DISPLAY_ID` (injected by `CompanionPageRoute` at `/c/**`) and derives the API origin from `Uri.base` (same-origin via Caddy, port−2 when on :8082). The settings UI therefore **already has the displayId** — needed for change-push in F9. | `apps/display/lib/companion_web_main.dart:13-32` |
| F15 | OTP delivery: SMTP via `mailer`, falls back to logging the code (`logCodes`) when SMTP is unconfigured. Initial TV pairing already depends on this same flow, so web login adds no new delivery requirement. | `server/landfall_server/lib/src/auth/otp_email_sender.dart` |
| F16 | `ThemeBrowserScreen`, `ProfileManagerScreen`, `ProfileSwitcher`, `LicenseTab`, `AgentKeysSection` are web-safe (no `dart:io`/Drift imports). `PhotoCubit` is **not** (imports `LocalDirectoryPhotoRepository` → `dart:io`); the web Display tab must not reuse it. | import scans 2026-06-07 |
| F17 | `AgentKeysSection` takes the management token as explicit user input — no hidden device dependency; reusable on web unchanged. | `apps/display/lib/src/features/settings/widgets/agent_keys_section.dart:7-22` |

### Corrections to last night's plan

1. **"No Caddy changes" was wrong.** Option B avoids a new *page* route, but the settings
   UI calls ~10 endpoints that today fall through to port 8082 and will fail behind Caddy
   (F11/F12). Phase 3 includes the Caddyfile work; it is small but mandatory.
2. **TV live-update was unspecified and the obvious mechanism is broken by default.**
   The long-poll channel is single-consumer and its only consumer lives inside
   `CompanionCard` (F9). If the web app pushes a `layout.changed` action, either the
   companion card swallows it (and ignores the unknown kind) or nobody is polling at all.
   Phase 2 adds an **app-level action router** so web edits appear on the TV in seconds.
3. **Server address is explicitly out of web scope** (F7). Editing the display's
   server URL from a web client served *by that server* is a self-cut-rope; it stays
   TV-only. The completeness matrix below records this as a deliberate exclusion.
4. **The QR entry point is layout-dependent** (F10). If the user removes the companion
   card, there is no path to the web settings. Phase 3 adds a QR + URL tile to the TV
   settings screen itself.
5. **Endpoint lockdown list grows**: `WeatherEndpoint` and `GreetingEndpoint` are also
   unguarded (F5). Both are display-read paths; the TV is authenticated post-pairing, so
   they are locked in Phase 1 with the rest.

---

## 3. Architecture overview

```
Phone browser ──QR──▶ /c/{displayId}  (CompanionPageRoute, port 8082, unauthenticated HTML)
                        │
                        ├─ Companion screen (existing, anonymous: pushAction, getOrCreateForDisplay)
                        │
                        └─ ⚙ gear ──▶ AuthGate (web AuthCubit + localStorage JWT)
                                        │  unauthenticated → OTP login screen
                                        ▼
                              WebSettingsScreen (TabBar)
                              ├─ Layout   → LayoutTabView (extracted) → client.profile.*
                              ├─ Themes   → ThemesTabView (extracted) → client.theme.* / client.marketplace.*
                              ├─ Accounts → AccountsTabView (extracted) → client.settings.* / client.apiKey.* / OAuth links
                              ├─ Display  → WebDisplayTab (new, Phase 4) → client.displaySettings.*
                              └─ License  → LicenseTab (already public) → client.license.*

After any successful save: client.companion.pushAction(displayId, '<domain>.changed')
TV: DisplayActionService (app-level long-poll, Phase 2) routes
    'companion.*'         → CompanionEventBus (animations, unchanged behaviour)
    'layout.changed'      → DashboardProfileCubit.loadProfiles()
    'theme.changed'       → ThemeCubit.loadThemes()
    'settings.changed'    → DisplaySettingsSyncService.pull()   (Phase 4)
```

Auth model: JWT in `localStorage` via `KeyValueClientAuthSuccessStorage` +
`WebLocalKeyValueStorage` (F3); `ClientAuthSessionManager` auto-refreshes (F2).
Residual XSS exposure of localStorage is accepted: LAN-only device, strict CSP already
set in the Caddyfile, no third-party scripts.

---

## 4. Phase 1 — Auth foundation + endpoint lockdown (est. 2.5–3.5 h)

Goal: every settings-relevant endpoint rejects anonymous callers; a web client can sign
in via OTP and stay signed in across reloads. **No visible UI change on the TV.**

### 4.1 Server: endpoint lockdown

Pattern: the file-local `_requireAuth(Session)` already used in
`profile_endpoint.dart:5` / `layout_endpoint.dart:5`.

- Test: `LayoutEndpoint.getLayouts` throws for an unauthenticated session; succeeds for an authenticated one → Code: add `_requireAuth` at `layout_endpoint.dart:21`.
- Test: `ProfileEndpoint.listProfiles` throws unauthenticated → Code: add `_requireAuth` at `profile_endpoint.dart:18`.
- Test: each `ThemeEndpoint` method (`listThemes`, `uploadTheme`, `importTheme`, `deleteTheme`, `previewTheme`, `applyTheme`) throws unauthenticated → Code: add `_requireAuth` to all six (file currently has zero guards).
- Test: `WeatherEndpoint` and `GreetingEndpoint` methods throw unauthenticated → Code: add guards.
- Test: `MarketplaceEndpoint` mutating methods (anything that installs/purchases/writes) throw unauthenticated; catalog reads stay anonymous-tolerant (ownership flags already degrade to `false`) → Code: guard mutations only. Record the read decision in the endpoint doc comment.
- Test (regression): existing integration suites for layout/profile/theme still pass with authenticated test sessions → Code: update test fixtures that relied on anonymous reads.

Explicitly **not** locked: `CompanionEndpoint` (anonymous by design — QR phone flow),
`OtpEndpoint` / `JwtRefreshEndpoint` / `PasskeyIdpEndpoint` (they *are* the auth flow),
`/photos/**` serve route (out of scope, pre-existing posture).

### 4.2 Display-app regression (TV must keep working)

- Test: widget/integration test asserting the display attaches its JWT before its first `listProfiles`/`listThemes` call after startup (client is constructed with `authSessionManager` in `app.dart:84` — verify ordering, not existence).
- Manual check in this phase's QA: cold-boot a dev display against the locked server; dashboard loads.

### 4.3 Web auth plumbing (`apps/display`)

New files:

| File | Contents |
|---|---|
| `lib/src/data/auth/web_local_key_value_storage.dart` | `KeyValueStorage` over `package:web` `window.localStorage` (~15 lines) |
| `lib/src/features/auth/screens/web_login_screen.dart` | Touch-styled OTP login (email → code), reusing `AuthCubit`; non-leanback layout |
| `lib/src/features/auth/widgets/auth_gate.dart` | `BlocBuilder<AuthCubit, AuthState>`: `AuthAuthenticated` → child, else login screen |

- Test: unit — `WebLocalKeyValueStorage` get/set/delete round-trip (run with `flutter test --platform chrome` or abstract behind an in-memory fake for the VM).
- Test: existing `AuthCubit` bloc_test suite passes unmodified when constructed with a `ClientAuthSessionManager(storage: KeyValueClientAuthSuccessStorage(keyValueStorage: fake))` — proves storage-agnosticism.
- Test: widget — `AuthGate` shows login when unauthenticated, child when authenticated, returns to login after `signOut`.
- Test: widget — `WebLoginScreen` email submit → `sendCode` called → code entry shown → `verifyCode` called; error state renders the `AuthError` message.
- Code: the three files above. No change to `AuthCubit`.

### 4.4 Exit criteria

- Server suite green, including new unauthenticated-throws tests.
- `flutter analyze` + `flutter test` green in `apps/display`.
- A scratch web build can sign in against a local server and survive a page reload
  (manual smoke; the automated reload-persistence test lands with Phase 2's gate flow).

---

## 5. Phase 2 — Layout tab on web + TV live-update (est. 2.5–3 h)

Goal: from a phone browser, rearrange/resize cards and switch profiles; the TV reflects
the change within one poll cycle (≤ ~5 s) without restart.

### 5.1 Extraction refactor (TV side, behaviour-neutral)

- Test: golden re-verification — existing TV settings goldens (1920×1080) byte-identical after extraction → Code: move `_LayoutTab` + `_SectionHeader` out of `settings_screen.dart` into `lib/src/features/settings/widgets/layout_tab_view.dart` (public `LayoutTabView`, same constructor surface: `leanback`, `onMoveModeChanged`, `onCancelMoveRegistered`) and `lib/src/features/settings/widgets/section_header.dart`. `settings_screen.dart` consumes the public widgets.
- Test: widget — `LayoutTabView` renders loading state for non-loaded `DashboardProfileState`, editor + `ProfileSwitcher` when loaded (this coverage currently doesn't exist because the class was private).

### 5.2 App-level action router (TV side) — fixes F9

New: `lib/src/features/display/services/display_action_service.dart`.
Owns the single long-poll loop (moves it out of `CompanionCard`); started once in
`app.dart` after the client exists; dispatches by `CompanionAction.kind`:

| kind | dispatch |
|---|---|
| existing companion kinds (`feed`, `pet`, … as consumed today by `CompanionCard`) | forward to `CompanionEventBus` / `CompanionCubit` exactly as the card does now |
| `layout.changed` | `DashboardProfileCubit.loadProfiles()` |
| `theme.changed` | `ThemeCubit.loadThemes()` (wired now, pushed from Phase 3) |
| `settings.changed` | no-op until Phase 4 |
| unknown | ignore + debug log |

- Test: unit — given a fake `CompanionPollService` emitting each kind, the right
  callback/cubit method fires; unknown kinds are ignored; poll loop reissues after
  null (timeout) and after an action; loop survives a thrown poll error (backoff retry).
- Test: widget regression — `CompanionCard` no longer polls itself but still animates on
  bus events (adapt `companion_card.dart:110-125` tests).
- Code: the service; `CompanionCard` poll-loop removal; wiring in `app.dart`.
- Note: single-consumer semantics (F9) are now safe — exactly one poller per display.

### 5.3 Web settings shell + Layout tab (web side)

- Test: widget — gear `IconButton` overlaid on the companion screen navigates to `WebSettingsScreen` wrapped in `AuthGate` (mock client; unauthenticated path shows login).
- Test: widget — `WebSettingsScreen` builds a `TabBar` with Layout / Themes / Accounts / Display / License; Layout tab hosts `LayoutTabView(leanback: false)` under a `DashboardProfileCubit` built from `ServerpodProfileRepository(client)`.
- Test: bloc/integration — save round-trip: editor `onLayoutChanged` → `saveActiveLayout` → repository called → `client.companion.pushAction(displayId, 'layout.changed')` fired after successful save (and **not** fired on save failure).
- Code: `lib/src/features/settings/screens/web_settings_screen.dart`; gear in `companion_web_main.dart`; a thin `SettingsChangePusher` (wraps `client.companion.pushAction` with the injected displayId) so tabs don't hand displayIds around.
- Non-Layout tabs render placeholder panes this phase (replaced in Phases 3–4).

### 5.4 Exit criteria

- TV goldens unchanged; all suites green.
- Manual: phone (direct `:8082`) → QR → gear → login → drag a card → TV updates without
  restart. (Caddy-fronted path is Phase 3.)

---

## 6. Phase 3 — Themes / Accounts / License tabs + build & Caddy wiring (est. 3–4 h)

Goal: the remaining server-backed tabs work on web; the whole thing works **behind Caddy**
on the Pi image; an entry point exists even without the companion card.

### 6.1 Tab extractions (same recipe as 5.1 — golden re-verify each)

- Test: goldens byte-identical after each extraction → Code:
  - `_ThemesTab` (+ `_ActiveThemeTile`, `_TokenSwatchPanel`, `_SwatchChip`) → `widgets/themes_tab_view.dart`.
  - `_AccountsTab` (+ `_AccountsList`, `_CredentialTile`, `_ConnectUrlTile`) → `widgets/accounts_tab_view.dart`.
  - `_LicenseTab` is already a wrapper over public `LicenseTab` (F6) — no extraction; web uses `LicenseTab` directly.
- Test: widget per extracted view — loading / loaded / error states (new coverage).

### 6.2 Web behaviour deltas

- Test: widget — Accounts tab on web renders OAuth connect tiles as **tap-to-open links**
  (`url_launcher` or anchor) in addition to copy; `getMyAuthUserId` drives the URL exactly
  as on TV → Code: small `isWeb`/callback parameter on `AccountsTabView`.
- Test: widget — Themes tab "Browse Themes" pushes `ThemeBrowserScreen` (web-safe, F16)
  under provided `ThemeCubit`/`MarketplaceCubit`; applying a theme calls
  `client.theme.applyTheme` then pushes `theme.changed` → Code: wire `SettingsChangePusher`
  into the theme apply path (web only).
- Test: widget — License tab renders `LicenseLoaded` status from a mocked `LicenseCubit`;
  key activation calls `activateLicense`.
- Test: widget — Agent keys section lists/generates/revokes via mocked `client.apiKey.*`
  callbacks (reuse the existing `AgentKeysSection` tests' fakes).

### 6.3 TV-side entry point (fixes F10)

- Test: widget — TV settings AppBar (or Display tab "Remote control" section) shows a QR
  + URL tile for `/c/{displayId}` built from `getCompanionBaseUrl()`; renders a fallback
  message when the URL can't resolve → Code: reuse `CompanionQrCode`; goldens updated
  deliberately (this is an intentional visual change, not drift).

### 6.4 Build + Caddy wiring (fixes F11, correction #1)

- Test: server integration — `companion_page_route_test.dart` still serves the rebuilt
  bundle; `expected-components.yaml` check passes against the new `web/app` contents
  (update the pinned file list if hashed names changed).
- Code: `deploy/Caddyfile` — add named matchers (bare + `/*` per the `@companion`
  comment, which documents why inline multi-path syntax is invalid) proxying to
  `server:8080` for: `otp`, `jwtRefresh`, `passkeyIdp`, `layout`, `profile`, `theme`,
  `marketplace`, `settings`, `apiKey`, `license`, `pack`. (`displaySettings` is added in
  Phase 4 alongside its endpoint.)
- Code: none needed in melos/pi-gen — same build target (F13); but **record the bundle
  size** before/after (`main.dart.js` bytes) in the phase notes; flag if growth > ~30%.
- Test (manual, scripted in `docs/manual_smoke_test.md`): every settings call succeeds
  through port 80/443 (Caddy) — not just `:8082`/`:8080` direct. This is the failure
  mode the old plan would have hit in QA.

### 6.5 Exit criteria

- All five tabs present; four fully functional (Display tab still placeholder).
- Caddy-fronted phone E2E: login, edit layout, apply theme, view accounts/license.

---

## 7. Phase 4 — Display tab (server-side lift) + full E2E (est. 3–4 h)

Goal: dim schedule, location, and photo sources editable from the web; the TV applies
changes live; full-system QA.

### 7.1 Protocol + endpoint

New Serverpod model `display_settings` (server `.spy.yaml`):
`displayId` (string, indexed unique), `dimEnabled`, `dimStartHour`, `dimEndHour`,
`dimLevel`, `locationName`, `photoSourceJson` (nullable), `updatedAt`.
**Excluded by design:** `serverUrl`, `wizardComplete`, `displayId-generation` — device-local (F7/F8).

- Test: integration — `DisplaySettingsEndpoint.get(displayId)` returns null when absent,
  row when present; `save(settings)` upserts by displayId and bumps `updatedAt`; both
  methods throw unauthenticated → Code: endpoint with `_requireAuth`, migration.
- Code: register in `server.dart` if needed; regenerate client; add `displaySettings`
  Caddy matcher.

### 7.2 Display-side sync (TV)

New: `DisplaySettingsSyncService` — write-through + pull:

- On startup: seed — if server row absent, push local Drift values up; if present and
  `updatedAt` newer than local last-sync, apply server → Drift (`DisplaySettingsCubit`
  reloads).
- On TV-local edit: existing Drift write **plus** server `save` (write-through decorator
  around `DriftDisplaySettingsRepository`; tolerate offline — queue/forget with log,
  local remains source of truth for the running device).
- On `settings.changed` action (router from 5.2): pull + apply.
- Conflict policy: **last write wins by `updatedAt`**; documented in the service header.

- Test: unit — seed-up, seed-down, pull-on-action, write-through, offline-tolerant paths
  against fake repository + fake client.
- Test: bloc — `DisplaySettingsCubit` emits updated state after a pull (dim values change
  → `DimOverlay` reacts; existing dim widget tests extended with one remote-change case).

### 7.3 Web Display tab

- Test: widget — `WebDisplayTab` mirrors the TV form minus Server address: dim
  enable/start/end/level, location field, photo-source editor; loads via
  `client.displaySettings.get`, saves via `.save`, pushes `settings.changed` on success
  → Code: new widget; reuse `_HourRow`-style controls (extract `hour_row.dart` if shared).
- Photo sources on web: a **lightweight editor of `photoSourceJson`** (choice of
  Serverpod / network URL list / local-directory path-on-the-Pi as a plain text field
  with explanatory caption). It must **not** import `PhotoCubit` (F16 — `dart:io`).
- Test: widget — each source type round-trips through the JSON shape used by
  `PhotoSource` in `landfall_shared`.

### 7.4 Full E2E + polish

Manual script (append to `docs/manual_smoke_test.md`):

1. Pi image build via `deploy/pi-gen/build.sh`; `expected-components.yaml` passes.
2. Phone → QR (companion card **and** the Phase 3 settings-screen QR) → login.
3. Layout drag → TV updates ≤ 5 s. Theme apply → TV re-themes. Dim level → TV dims.
   Location → weather card label changes after next refresh. Photo source swap → slideshow
   source changes.
4. Token expiry: leave the tab open > 10 min, perform a save — succeeds via auto-refresh (F2).
5. Sign out → gate returns; companion interact features still work unauthenticated.
6. Responsive: phone portrait usable on all tabs; layout editor usable in landscape;
   tablet OK.
7. Bundle size recorded; boot-time regression check on the TV (locked endpoints, F5).

Automated:

- Test: goldens for `WebSettingsScreen` at phone portrait (390×844) and landscape for the
  layout tab.
- Test: one end-to-end widget test — login → layout tab → save → pushAction observed
  (mocked client), per CLAUDE.md's three-level coverage rule.

---

## 8. Completeness matrix — every TV settings surface

| TV surface (settings_screen.dart) | Backing store | Web disposition | Phase |
|---|---|---|---|
| Layout: card drag/resize editor | server (`profile.cardsJson`) | reuse `LayoutTabView` | 2 |
| Layout: profile switcher | server | reuse `ProfileSwitcher` | 2 |
| Layout: Manage profiles (create/rename/duplicate/delete/activate/schedule) | server | reuse `ProfileManagerScreen` (web-safe, F16) | 2 |
| Layout: reset to default | server | reuse (`onReset` enabled — pointer mode) | 2 |
| Themes: active theme + token swatches | server | reuse `ThemesTabView` | 3 |
| Themes: browse / marketplace / apply / import | server | reuse `ThemeBrowserScreen` + push `theme.changed` | 3 |
| Accounts: linked credentials list | server | reuse `AccountsTabView` | 3 |
| Accounts: Google/Microsoft OAuth connect | server + browser redirect | reuse; *better* on web (tap-to-open) | 3 |
| Accounts: agent API keys (list/generate/revoke) | server | reuse `AgentKeysSection` (F17) | 3 |
| License: tier badge, status, key activation | server | reuse `LicenseTab` (already public) | 3 |
| Display: dim enable/start/end/level | local Drift → **lifted to server** | new `WebDisplayTab` + sync service | 4 |
| Display: location name | local Drift → lifted | same | 4 |
| Display: photo sources | local Drift (`photoSourceJson`) → lifted | new lightweight JSON editor (no `PhotoCubit`) | 4 |
| Display: **Server address** | local Drift | **excluded by design** — TV-only (correction #3) | — |
| First-run wizard / `wizardComplete` / `displayId` | local Drift | excluded — device bootstrap, meaningless remotely | — |
| Entry point: QR to `/c/{displayId}` | companion card only today | add QR + URL tile to TV settings screen | 3 |
| Live TV pickup of remote edits | none today | `DisplayActionService` + `*.changed` push kinds | 2 |

Nothing on the TV settings screen is left without an explicit web disposition.

---

## 9. Risks and open items

| Risk | Mitigation |
|---|---|
| Push-kind channel is unauthenticated (`pushAction` is anonymous by design) — anyone on LAN can spam `layout.changed` | It is a *notification only*; the TV refetches over its own authenticated client. Worst case = extra refresh traffic. Accepted (LAN-only). Revisit if `pushAction` ever gains payloads. |
| Golden churn from extracting four private tabs | Extract one tab per commit; goldens re-verified per commit (Phases 2/3 sequencing already reflects this). |
| `expected-components.yaml` pin may break on bundle rebuild | Update pins in the same Phase 3 commit as the rebuild; `build.sh` already invalidates stale tarballs (F13). |
| Bundle growth from settings/theme/profile/auth trees | Measure in Phase 3; threshold ~30% before optimizing (deferred imports are the lever if needed). |
| `flutter test --platform chrome` may not be wired in CI for the localStorage adapter | Keep the adapter behind the `KeyValueStorage` interface; VM tests cover logic with a fake, a single chrome-platform test covers the binding. |
| Two pollers during rollout (old APK with card-poll + new server) | The router lands display-side in the same release; server protocol unchanged, so no cross-version hazard. |

Open question (decide at Phase 4 start, does not block 1–3): should TV-local Display-tab
edits be disabled once server-side settings exist, or kept with write-through? **Spec
default: keep TV editing with write-through** (7.2) — the TV remains usable standalone.

---

## 10. Definition of done (whole feature)

- [ ] All Phase 1 lockdown tests green; no settings-relevant endpoint callable anonymously.
- [ ] Phone browser can: sign in (OTP), persist across reload, auto-refresh JWT.
- [ ] All five tabs functional on web per the matrix; Server address visibly absent by design.
- [ ] TV reflects web edits (layout/theme/display settings) without restart.
- [ ] Works through Caddy on the Pi image, not just direct ports.
- [ ] TV settings screen offers the QR entry point regardless of layout contents.
- [ ] Goldens: TV unchanged (except the deliberate Phase 3 QR tile); web goldens added.
- [ ] `flutter analyze` clean; `flutter test` green in all packages; server suite green.
- [ ] `docs/README.md` indexes this spec; `docs/manual_smoke_test.md` extended (7.4).
