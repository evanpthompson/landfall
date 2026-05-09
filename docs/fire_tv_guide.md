# Fire TV Guide

Fire TV delivery is APK based. The server remains self-hosted; the Fire TV app connects to the server URL you enter during setup.

## Current Status

`tools/scripts/build_apk.sh` is the build entry point, but it now fails early if `apps/display/android/` is missing. Before Fire TV can be treated as release-ready, the Android platform scaffold must be committed with the expected package ID, internet permission, Android TV launcher metadata, and landscape/fullscreen behavior.

## Build

```bash
bash tools/scripts/build_apk.sh
```

Expected release artifact:

```text
apps/display/build/app/outputs/flutter-apk/app-release.apk
```

If the script reports missing Android platform files, generate them from the display app and then apply the Fire TV manifest settings:

```bash
flutter create --platforms=android apps/display
```

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
