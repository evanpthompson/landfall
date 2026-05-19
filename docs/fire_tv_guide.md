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

### Observations

_(Bullets go here once Phase 0 is run. Be specific: "step 1 has no visible focus ring on the TextField; D-pad-down jumps two widgets, skipping the helper text; back button kills the app.")_

---

## For AI assistants

Key facts for helping users build and sideload the Fire TV APK:

- **Build:** `bash tools/scripts/build_apk.sh` from the repo root. Output: `apps/display/build/app/outputs/flutter-apk/app-release.apk`.
- **Sideload:** `adb connect <ip>:5555 && adb install -r <path-to-apk>`. Developer options and ADB debugging must be enabled on the Fire TV first.
- **The APK does not pre-configure a server URL.** First launch shows the setup wizard — the user enters their self-hosted server URL (e.g. `http://192.168.1.50:8080`). Use HTTPS only when the server has a certificate the Fire TV trusts.
- **Signing:** current builds use Flutter's debug signing config. A proper keystore is needed before any public distribution — `android/key.properties` must not be committed.
- **Application ID:** `io.landfall.display`. Used in `adb shell monkey` and for identifying the app in Fire TV menus.
- **Any Android device** can run the same APK — not just Fire TV. Useful for testing on a phone or Android tablet.
