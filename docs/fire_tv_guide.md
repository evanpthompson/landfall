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

Alpha APKs are signed with Flutter's debug signing config so local release builds and sideloading work without a shared keystore. Before public distribution, replace that with a private release keystore and keep `android/key.properties` out of git.

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
adb shell monkey -p <application_id> 1
adb logcat
```

If the app cannot connect, confirm the Fire TV and server are on the same network and that the server responds from another device:

```bash
curl http://<SERVER_IP>:8081
```
