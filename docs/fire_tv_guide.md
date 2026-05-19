# Fire TV Guide

Fire TV delivery is APK based. The server remains self-hosted; the Fire TV app connects to the server URL you enter during setup.

Unlike the Raspberry Pi all-in-one image, Fire TV APK builds do not set `LANDFALL_DEFAULT_SERVER_URL`. First launch shows the setup wizard so you can enter the URL of your self-hosted server. Stored settings on the device override any future defaults.

## Current Status

`tools/scripts/build_apk.sh` is the build entry point. The Android scaffold is committed with the expected application ID, internet permission, Android TV launcher metadata, and landscape behavior.

## Build

```bash
bash tools/scripts/build_apk.sh
```

Expected release artifact:

```text
apps/display/build/app/outputs/flutter-apk/app-release.apk
```

Current APKs are signed with Flutter's debug signing config so local release builds and sideloading work without a shared keystore. Before public distribution, replace that with a private release keystore and keep `android/key.properties` out of git.

## Sideload

Install Android platform tools, then enable developer options and ADB debugging on the Fire TV.

```bash
adb connect <FIRE_TV_IP>:5555
adb install -r apps/display/build/app/outputs/flutter-apk/app-release.apk
```

On first launch, enter the self-hosted server URL, for example:

```text
http://192.168.1.50:8080
```

Use HTTPS only when the server is configured with a real certificate that the Fire TV trusts.

## Troubleshooting

```bash
adb devices
adb shell monkey -p io.landfall.display 1
adb logcat
```

If the app cannot connect, confirm the Fire TV and server are on the same network and that the server responds from another device:

```bash
curl http://<SERVER_IP>:8081
```

---

## Remote-control state of play

Beta-required: the app must be navigable end-to-end from the Fire TV remote, no USB keyboard. Full plan lives in [`firetv_remote_nav_plan.md`](firetv_remote_nav_plan.md). This section is the Phase 0 bench-test log — fill it in by walking the wizard with the script below, then the later phases adjust to what you find.

### Bench-test script

Drive the Fire TV from the Mac. Replace `<FIRE_TV_IP>` once.

```bash
adb connect <FIRE_TV_IP>:5555

# D-pad
adb shell input keyevent 19   # up
adb shell input keyevent 20   # down
adb shell input keyevent 21   # left
adb shell input keyevent 22   # right
adb shell input keyevent 23   # OK / center
adb shell input keyevent 4    # back

# Launch the app fresh
adb shell am force-stop io.landfall.display
adb shell am start -n io.landfall.display/.MainActivity

# Watch logs while you navigate
adb logcat | grep -iE 'flutter|landfall'
```

### Checklist (fill in as you bench)

- [ ] **Initial focus on wizard step 1** — does any control look focused on launch?
- [ ] **TextField focus → IME** — does the Amazon keyboard appear on first launch?
- [ ] **Focus visibility on buttons** — can you see which control is focused from the couch?
- [ ] **D-pad traversal order** — does down/right move focus where you expect?
- [ ] **OK button** — submits forms? Activates buttons?
- [ ] **Back button** — closes IME? Goes back a step? Or exits the app?
- [ ] **TextField submit** — does the Amazon keyboard's "Done" advance the wizard?
- [ ] **Wizard step 2 (location)** — same checks as step 1
- [ ] **Wizard step 3 (link accounts)** — D-pad navigates to "Got it"?
- [ ] **Login screen email** — same checks; OTP code entry usable?
- [ ] **Settings tray** — can you open it from the display? Close it?

### Observations (Phase 0 bench-test, 2026-05-19)

Bench-tested against a sideloaded APK on Fire TV (model TBD; Impeller/Vulkan rendering).

- **Initial focus:** TextField on wizard step 1 is focused on launch (border highlight visible). `autofocus: true` works as expected.
- **Amazon IME never appears.** With focus on the TextField, no on-screen keyboard is summoned. There is no way to type a server URL using only the remote. **This is the beta blocker.**
- **D-pad does not traverse off the TextField.** None of up/down/left/right move focus to the Connect button. The TextField appears to swallow arrow keys (default Android `EditText` behavior — arrows are caret movement when text is empty too).
- **OK / center has no observable effect.** Likely because focus is parked on a TextField with no text to submit; the button is unreachable.
- **Back button kills the app.** Single back press exits to the Fire TV home screen. No graceful per-step navigation; no `PopScope`/`WillPopScope` handler exists.
- **`LEANBACK_LAUNCHER` is already wired** in the Android manifest — confirmed in logcat (`cat=[android.intent.category.LEANBACK_LAUNCHER]` on launch).
- **Impeller/Vulkan rendering is active.** Not a problem, but a variable to keep in mind if odd rendering issues appear later (`android_context_vk_impeller.cc`).

### Implications for the plan

1. **IME blocker has two viable solutions** (decide before starting Phase 1 widget work):
   - **Plan A — fix the IME.** Add `android:windowSoftInputMode="stateVisible|adjustResize"` to the activity, and on TextField focus explicitly call `SystemChannels.textInput.invokeMethod('TextInput.show')`. Cheap if it works; uncertain on Fire OS.
   - **Plan B — phone-pairing flow.** Show a short code on the Fire TV. User opens a URL on their phone, enters the code, then enters the server URL. Fire TV polls until it receives the URL. Requires a small pairing-relay endpoint on the server (or a third-party relay). Sidesteps the IME entirely and is the pattern most Fire TV apps use (Netflix, Disney+, Plex).
2. **Phase 2's `FocusTraversalGroup` work is still needed** regardless of which IME path wins — D-pad needs to escape the TextField.
3. **Phase 2's `PopScope` handler is essential.** Single back press must not exit the app from any wizard step.
4. **Phase 5 manifest work is partly done.** Still need `<uses-feature android:name="android.hardware.touchscreen" android:required="false"/>` for clean Fire TV submission.

---

## For AI assistants

Key facts for helping users build and sideload the Fire TV APK:

- **Build:** `bash tools/scripts/build_apk.sh` from the repo root. Output: `apps/display/build/app/outputs/flutter-apk/app-release.apk`.
- **Sideload:** `adb connect <ip>:5555 && adb install -r <path-to-apk>`. Developer options and ADB debugging must be enabled on the Fire TV first.
- **The APK does not pre-configure a server URL.** First launch shows the setup wizard — the user enters their self-hosted server URL (e.g. `http://192.168.1.50:8080`). Use HTTPS only when the server has a certificate the Fire TV trusts.
- **Signing:** current builds use Flutter's debug signing config. A proper keystore is needed before any public distribution — `android/key.properties` must not be committed.
- **Application ID:** `io.landfall.display`. Used in `adb shell monkey` and for identifying the app in Fire TV menus.
- **Any Android device** can run the same APK — not just Fire TV. Useful for testing on a phone or Android tablet.
