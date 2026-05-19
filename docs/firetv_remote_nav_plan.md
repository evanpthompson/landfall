# Fire TV Remote Navigation — Implementation Plan

Beta-scope plan for making the display app navigable end-to-end with a Fire TV remote (no USB keyboard required). Discovered gap: the codebase has zero TV awareness — no `FocusNode` wiring, no `Focus` widgets, no D-pad refs, no leanback detection. The wizard and login screens rely entirely on Flutter's default focus traversal plus Material's built-in focusability, which gets the IME to open for `TextField` but leaves no visible focus ring on buttons and no tested navigation order.

Beta scope = wizard + login + display dismiss/settings entry must work cold from a remote. Everything else can land post-beta.

---

## Phase 0 — Bench the real gap (no code change)

Before writing anything, find out what already works. Drive Fire TV from your Mac with `adb`:

| Key | adb keyevent |
|---|---|
| D-pad up/down/left/right | 19/20/21/22 |
| OK / Center | 23 |
| Back | 4 |

Walk the wizard with only the remote. Capture what does and doesn't work — focus visibility, IME open/close, initial focus, back button.

**Deliverable:** bench-test note (5–10 bullets) appended to [`fire_tv_guide.md`](fire_tv_guide.md) under "Remote-control state of play". Outcome of this phase reshapes scope.

---

## Phase 1 — TV detection + focus-visible theme

Goal: a runtime flag so TV-aware styling activates without breaking touch UX, plus a high-contrast focus ring visible across a room.

- **Test:** unit test that `isLeanback()` returns true for `--dart-define=LANDFALL_LEANBACK=true` and reads Android `UiModeManager` else → **Code:** `lib/src/platform/leanback.dart`
- **Test:** golden test of a `LandfallFocusableContainer` showing a 3px accent ring + 1.04× scale at 1920×1080 → **Code:** wrapper widget in `ui_kit/lib/src/widgets/landfall_focusable.dart`
- **Test:** widget test that `FilledButton` inside this wrapper draws the ring when `Focus.of(context).hasFocus` is true → **Code:** apply the ring via `FocusableActionDetector.onShowFocusHighlight`

---

## Phase 2 — Setup wizard remote nav

- **Test:** widget test pumps `SetupWizardScreen` at step `serverUrl`, sends `LogicalKeyboardKey.arrowDown` × 2, asserts focus lands on the Connect button → **Code:** wrap each step body in `FocusTraversalGroup` with `OrderedTraversalPolicy`, add explicit `FocusNode`s
- **Test:** widget test asserts focus initially lands on the TextField (so IME opens) on every step entry → **Code:** keep `autofocus: true`, add `FocusScope.of(context).requestFocus(...)` on state restore
- **Test:** widget test sends `LogicalKeyboardKey.escape` (Fire TV back) and asserts the wizard goes back one step (not killing the app) → **Code:** `PopScope` handler driving `SetupWizardCubit.previousStep`
- **Test:** widget test of URL-prefix quick-fill chips ("http://", "https://"), arrow-right cycles them → **Code:** chip row above the TextField when `isLeanback()` is true
- **Manual on Fire TV:** with the Amazon keyboard, typing a server URL submits cleanly. Documented procedure added to `fire_tv_guide.md`.

Why the chips: typing `http://192.168.1.167:8080/` on the Amazon virtual keyboard takes ~40 D-pad presses. Two chip presses + the IP body cuts it to ~12.

---

## Phase 3 — Login screen remote nav

- **Test:** widget test of `LoginScreen` with mock `AuthCubit` — initial focus on email field, arrow-down to "Send code", Enter submits → **Code:** `FocusTraversalGroup` + nodes in `_EmailStep` and `_CodeStep`
- **Test:** OTP code entry — focus traps inside the 6-digit field, digits auto-advance, last digit triggers verify → **Code:** swap the single TextField for a Pinput-style 6-cell widget with `LengthLimitingTextInputFormatter` + auto-submit
- **Test:** numeric-IME keyboard type stays set → **Code:** `keyboardType: TextInputType.number`
- **Manual:** Fire TV Amazon keyboard shows numeric pad for OTP entry. Document on `fire_tv_guide.md`.

Biggest UX win: 6-digit code entry over a single underlined field on a TV is hostile.

---

## Phase 4 — Display screen + settings entry remote nav

- **Test:** widget test of `DisplayScreen` — pressing OK opens the settings tray, Back closes it → **Code:** `Focus` + `KeyboardListener` at the display root, `Actions.invoke(OpenSettingsIntent())`
- **Test:** `SettingsScreen` first focusable is the first tile; arrow-down traverses tiles in document order → **Code:** group settings list as `FocusTraversalGroup` with `ReadingOrderTraversalPolicy`
- **Test:** Back from settings root returns to display (does not exit app) → **Code:** `PopScope` handler

---

## Phase 5 — Manifest + launch behavior

- `AndroidManifest.xml` — add `<category android:name="android.intent.category.LEANBACK_LAUNCHER"/>` so Fire TV's home rail shows the app under "Your Apps" without sideload trickery. Add `<uses-feature android:name="android.software.leanback" android:required="false"/>`.
- `<uses-feature android:name="android.hardware.touchscreen" android:required="false"/>` — required for any Fire TV submission.
- Smoke test: `adb shell am start -n io.landfall.display/.MainActivity` launches via D-pad, no touchscreen warning.

---

## Out of scope for beta (backlog)

- Voice-search integration (Fire TV "Alexa, open Landfall and connect to ...")
- Overscan-safe padding for older Fire TV Sticks (assume modern HDMI for beta)
- Settings screens not reached during first-run (calendar reconnect, theme picker, etc.) — get focus theme via Phase 1 globally; explicit traversal can wait
- Fire OS Live App Tile / channel surfaces

---

## Tooling and gotchas

- **Test simulation:** `tester.sendKeyEvent(LogicalKeyboardKey.arrowDown)` + `tester.pump()`. Already in `flutter_test`.
- **bloc_test:** already in tree.
- **Pinput:** if you go with Phase 3 OTP suggestion, add `pinput: ^5.0.0` to `apps/display/pubspec.yaml`. Active maintenance, ~1.5k stars.
- **CLAUDE.md TDD bar:** every cubit gets a `bloc_test`, every public widget gets widget + golden tests. Phase 1's `LandfallFocusableContainer` needs both.

---

## Estimated session breakdown

| Phase | Rough size | Blocks beta? |
|---|---|---|
| 0 | 30 min on Fire TV with remote | Yes — reshapes everything |
| 1 | half session | Yes |
| 2 | one session | Yes |
| 3 | one session (Pinput refactor is the bulk) | Yes |
| 4 | half session | Yes |
| 5 | 30 min + Fire TV verify | Yes |

Roughly **3–4 focused sessions** to beta-ready. Phase 0 first since its results may collapse or expand later phases.
