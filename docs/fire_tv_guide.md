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

## For AI assistants

Key facts for helping users build and sideload the Fire TV APK:

- **Build:** `bash tools/scripts/build_apk.sh` from the repo root. Output: `apps/display/build/app/outputs/flutter-apk/app-release.apk`.
- **Sideload:** `adb connect <ip>:5555 && adb install -r <path-to-apk>`. Developer options and ADB debugging must be enabled on the Fire TV first.
- **The APK does not pre-configure a server URL.** First launch shows the setup wizard — the user enters their self-hosted server URL (e.g. `http://192.168.1.50:8080`). Use HTTPS only when the server has a certificate the Fire TV trusts.
- **Signing:** current builds use Flutter's debug signing config. A proper keystore is needed before any public distribution — `android/key.properties` must not be committed.
- **Application ID:** `io.landfall.display`. Used in `adb shell monkey` and for identifying the app in Fire TV menus.
- **Any Android device** can run the same APK — not just Fire TV. Useful for testing on a phone or Android tablet.
