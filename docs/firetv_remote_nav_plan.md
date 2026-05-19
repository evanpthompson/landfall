# Fire TV Remote Navigation + Zero-Type Setup — Implementation Plan

> **Revised after Phase 0 bench-test** (see [`fire_tv_guide.md`](fire_tv_guide.md) → Remote-control state of play). The cheap IME fix is being shipped as a fallback; the *real* answer is mDNS server discovery so users don't have to type a URL on any platform.

## Why this scope

Phase 0 surfaced two truths:

1. The Amazon IME never appears on Fire TV when a Flutter `TextField` gets focus. URL entry by remote is impossible today.
2. The root problem isn't just Fire TV. Asking any user to type `http://192.168.1.167:8080/` is bad UX on Pi, Fire TV, mobile, and macOS dev too.

The answer that solves it everywhere is **mDNS service discovery**: the server broadcasts `_landfall._tcp.local`, every Landfall display scans on launch, the user picks from a list (or auto-connects if exactly one). Zero typing. Same pattern as Plex/Sonos/HomeKit.

For login (email + OTP), the canonical TV pattern is **device authorization** (RFC 8628 — what Plex/Netflix use): TV shows a short code, user signs in on phone, server marks the code paired, TV polls and receives the token. Also zero typing on the TV side.

Manual URL entry and TV keyboard typing remain as fallbacks for unusual networks and power users.

---

## Phase 0 — Bench the real gap ✅

Done. Observations are in `fire_tv_guide.md`. Headlines: IME never appears, D-pad doesn't escape TextField, back exits the app.

---

## Phase 1 — Foundation (TV detection + cheap IME fix + focus theme)

### 1a. `isLeanback()` detection ✅ DONE this session

`apps/display/lib/src/platform/leanback.dart` + Android `MainActivity.kt` channel handler + 7 tests + `build_defines.md` entry for `LANDFALL_LEANBACK`.

### 1b. Cheap IME fix (Plan A — no-loss fallback for non-mDNS networks)

- **Test:** widget test that a focused `LandfallTextField` calls `SystemChannels.textInput.invokeMethod('TextInput.show')` → **Code:** new `widgets/landfall_text_field.dart` wrapping `TextField` with explicit show-IME on focus
- **Code (no test, manifest config):** `AndroidManifest.xml` add `android:windowSoftInputMode="stateVisible|adjustResize"` to `MainActivity`
- **Code (no test, manifest config):** `<uses-feature android:name="android.hardware.touchscreen" android:required="false"/>`
- **Manual on Fire TV:** rebuild APK, sideload, confirm Amazon IME appears on TextField focus

### 1c. Focus-visible widget

- **Test:** unit/widget test of `LandfallFocusable` (in `packages/ui_kit/lib/src/widgets/landfall_focusable.dart`) — when wrapped child gains focus, ring is drawn → **Code:** `FocusableActionDetector` with `onShowFocusHighlight` toggling a 3px ring + 1.04× scale
- **Test:** golden test at 1920×1080 showing focused vs unfocused state → **Code:** ditto
- **Test:** widget test wrapping a `FilledButton` with `LandfallFocusable` and asserting the ring renders when focus is requested via FocusNode → **Code:** ditto
- **Apply globally:** when `Leanback().isLeanback()` is true, swap `ElevatedButton`/`FilledButton`/`TextButton` for the focusable-wrapped variants. Use a theme extension to thread the flag.

---

## Phase 2 — mDNS server discovery (the real Plan B, replaces typed URL entry)

The biggest UX win. Eliminates URL typing for every user on every platform.

### 2a. Server-side broadcast

- **Test:** Serverpod test that the mDNS broadcaster registers `_landfall._tcp.local` with the right TXT records (`serverUrl`, `version`, `displayName`) when the server starts → **Code:** `server/landfall_server/lib/src/discovery/mdns_broadcaster.dart` using the `bonsoir` or `nsd` Dart package
- **Test:** test that the broadcast stops cleanly on server shutdown → **Code:** ditto, register the lifecycle hook
- **Code (no test, config):** wire startup hook in `server/landfall_server/lib/server.dart`

### 2b. Client-side discovery

- **Test:** widget/unit test of `MdnsServerDiscovery` — when the platform stream yields a service, `discoveredServers` includes it → **Code:** `apps/display/lib/src/data/discovery/mdns_server_discovery.dart`
- **Test:** test that discovery times out gracefully after 8s with empty results → **Code:** ditto
- **Test:** test that discovery is stopped on disposal (no leaked subscriptions) → **Code:** ditto

### 2c. New wizard step: "Discover servers"

This becomes the new step 1 of the wizard, ahead of the existing URL step.

- **Test:** widget test (`SetupWizardScreen` with `_DiscoverStep`) — pumps the screen, fakes the discovery service to yield 2 servers, asserts both render as D-pad-selectable tiles → **Code:** new `_DiscoverStep` widget; `SetupWizardCubit.startDiscovery()` and `selectDiscoveredServer(...)` methods
- **Test:** when discovery yields exactly one server AND `--dart-define=LANDFALL_AUTO_PICK_SINGLE=true`, the wizard auto-advances → **Code:** auto-pick branch in cubit
- **Test:** when discovery yields zero servers after timeout, "Enter manually" option is focused first → **Code:** fallback branch
- **Test:** "Enter manually" routes to the existing URL step (now step 1b) → **Code:** new cubit transition

---

## Phase 3 — Wizard remote nav (always-on, regardless of discovery path)

- **Test:** widget test on every wizard step — `LogicalKeyboardKey.arrowDown` moves focus through interactive elements in document order → **Code:** wrap each step body in `FocusTraversalGroup` with `OrderedTraversalPolicy`, add explicit `FocusNode`s
- **Test:** widget test that `LogicalKeyboardKey.escape` (Fire TV back) goes one wizard step backwards instead of popping the app → **Code:** `PopScope` driving `SetupWizardCubit.previousStep`
- **Test:** D-pad arrow keys escape the TextField (no more "trapped in input") → **Code:** wrap TextFields with `Shortcuts({arrowDown: NextFocusIntent()})` + `Actions` so arrows traverse when caret is at edges, or use `TextInputAction.next` + `onSubmitted` to advance
- **Test:** URL-entry-fallback step shows quick-fill chips (`http://`, `https://`, `:8080/`) when `Leanback().isLeanback()` is true → **Code:** chip row above the TextField
- **Manual on Fire TV:** confirm all four wizard steps are reachable, completable, and back-traversable using only the remote

---

## Phase 4 — Login: device authorization (the real fix) + remote nav fallback

### 4a. Device-authorization flow (zero-type login on TV)

Pattern: TV shows a 6-character user code + a short URL (e.g. `http://<server>/device`). User opens that URL on their phone (full keyboard), enters the code + their email/OTP, server marks the device session authorized, TV polls and receives the access token.

- **Test:** Serverpod test that `POST /auth/device/start` returns `{userCode, deviceCode, verificationUri, expiresIn, interval}` → **Code:** new `DeviceAuthEndpoint` in the server
- **Test:** Serverpod test that polling `POST /auth/device/poll` with a paired `deviceCode` returns the access token → **Code:** ditto
- **Test:** Serverpod test that polling an unpaired code returns `authorization_pending`, then after expiry returns `expired_token` → **Code:** ditto, with cleanup timer
- **Test:** Serverpod test that `GET /device` serves an HTML page with email + OTP form that completes the pairing → **Code:** server-rendered page (or `serverpod_web_server` route)
- **Test:** client widget test that `LoginScreen` in `Leanback().isLeanback()` mode shows the user code + URL and polls `auth/device/poll` until receiving a token → **Code:** new `_DeviceAuthStep` in `LoginScreen` (gated by leanback flag), `AuthCubit.startDeviceFlow()`
- **Manual on Fire TV + phone:** complete login end-to-end using only the remote on the TV and a phone for the code entry

### 4b. Remote nav fallback for non-leanback login

For non-TV builds where the existing email + OTP flow is fine, just polish:

- **Test:** widget test of `LoginScreen` with mock `AuthCubit` — initial focus on email field, arrow-down to "Send code", Enter submits → **Code:** `FocusTraversalGroup` + nodes in `_EmailStep` and `_CodeStep`
- **Test:** OTP code entry — focus traps inside the 6-digit field, digits auto-advance, last digit triggers verify → **Code:** swap the single TextField for a Pinput-style 6-cell widget
- **Test:** numeric-IME keyboard type stays set → **Code:** `keyboardType: TextInputType.number`

---

## Phase 5 — Display + settings entry remote nav

- **Test:** widget test of `DisplayScreen` — pressing OK opens the settings tray, Back closes it → **Code:** `Focus` + `KeyboardListener` at the display root, `Actions.invoke(OpenSettingsIntent())`
- **Test:** `SettingsScreen` first focusable is the first tile; arrow-down traverses tiles in document order → **Code:** group settings list as `FocusTraversalGroup` with `ReadingOrderTraversalPolicy`
- **Test:** Back from settings root returns to display (does not exit app) → **Code:** `PopScope` handler

---

## Phase 6 — Manifest + launch polish

- `<category android:name="android.intent.category.LEANBACK_LAUNCHER"/>` — **already present** (confirmed in Phase 0 logcat).
- `<uses-feature android:name="android.software.leanback" android:required="false"/>`
- `<uses-feature android:name="android.hardware.touchscreen" android:required="false"/>` — moved to Phase 1b since it pairs with the IME work.
- Smoke test: `adb shell am start -n io.landfall.display/.MainActivity` launches via D-pad, no touchscreen warning, app appears in Fire TV "Your Apps" row.

---

## Out of scope for beta (backlog)

- Voice-search integration ("Alexa, open Landfall and connect to X")
- Overscan-safe padding for older Fire TV Sticks
- Settings screens not reached during first-run (theme picker, calendar reconnect)
- Fire OS Live App Tile / channel surfaces
- mDNS broadcaster on the **macOS** dev server (Pi + Linux server only for now; Mac users can use the URL fallback)
- QR-code companion pairing for the existing post-setup companion (separate feature)

---

## Tooling and dependencies

| Need | Package |
|---|---|
| Client mDNS discovery | `nsd: ^2.5.0` (or `multicast_dns` from Flutter team — review both) |
| Server mDNS broadcast | `bonsoir: ^5.1.0` (Dart-only, works in Serverpod) |
| Pinput OTP cells | `pinput: ^5.0.0` |
| Key event tests | `flutter_test` (built-in) |
| Bloc test | `bloc_test` (already in tree) |

---

## Estimated session breakdown (revised)

| Phase | Rough size | Blocks beta? | Status |
|---|---|---|---|
| 0 | bench | Yes | ✅ done |
| 1a `isLeanback()` | 30 min | Yes | ✅ done |
| 1b cheap IME fix | 30 min + Fire TV verify | Yes (fallback) | Doing this session |
| 1c focus widget | half session | Yes | Pending |
| 2 mDNS discovery (server + client + wizard step) | **two sessions** — the big one | Yes (the real fix) | Pending |
| 3 wizard remote nav | one session | Yes | Pending |
| 4a device auth | one session | Yes (the real fix for login) | Pending |
| 4b login fallback nav | half session | Yes | Pending |
| 5 display + settings nav | half session | Yes | Pending |
| 6 manifest polish | 30 min | Yes | Pending |

Roughly **5–6 focused sessions** to beta-ready. mDNS discovery + device authorization are the biggest single-feature commitments and the largest UX payoffs. Cheap IME fix this session unblocks bench testing while the bigger pieces land.
