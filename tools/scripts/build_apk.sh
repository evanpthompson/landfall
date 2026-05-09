#!/usr/bin/env bash
# Build the Landfall Fire TV APK (release).
#
# Usage:  bash tools/scripts/build_apk.sh
#
# Output: apps/display/build/app/outputs/flutter-apk/app-release.apk

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DISPLAY_DIR="${REPO_ROOT}/apps/display"

BOLD=$'\033[1m'
GREEN=$'\033[1;32m'
CYAN=$'\033[1;36m'
RED=$'\033[1;31m'
RESET=$'\033[0m'

ok()   { echo "${GREEN}✓  $*${RESET}"; }
info() { echo "   $*"; }
die()  { echo "${RED}✗  $*${RESET}"; exit 1; }

echo ""
echo "${CYAN}${BOLD}Landfall — Fire TV APK build${RESET}"
echo ""

if ! command -v flutter > /dev/null; then
  echo "flutter not found. Install it from https://docs.flutter.dev/get-started/install"
  exit 1
fi

if [[ ! -f "${DISPLAY_DIR}/android/app/src/main/AndroidManifest.xml" ]]; then
  die "Android platform files are missing under apps/display/android. Run 'flutter create --platforms=android apps/display' and apply the Fire TV manifest settings before building an APK."
fi

MANIFEST="${DISPLAY_DIR}/android/app/src/main/AndroidManifest.xml"
GRADLE_FILE="${DISPLAY_DIR}/android/app/build.gradle.kts"
grep -q 'android.permission.INTERNET' "${MANIFEST}" \
  || die "Android manifest is missing INTERNET permission"
grep -q 'android.intent.category.LEANBACK_LAUNCHER' "${MANIFEST}" \
  || die "Android manifest is missing Android TV leanback launcher category"
grep -q 'android:screenOrientation="landscape"' "${MANIFEST}" \
  || die "Android manifest must force landscape orientation for Fire TV"
grep -q 'applicationId = "io.landfall.display"' "${GRADLE_FILE}" \
  || die "Unexpected Android applicationId; expected io.landfall.display"

cd "${DISPLAY_DIR}"

info "Building release APK..."
flutter build apk --release

APK="${DISPLAY_DIR}/build/app/outputs/flutter-apk/app-release.apk"
ok "APK ready: ${APK}"

echo ""
echo "${BOLD}Sideload to Fire TV:${RESET}"
info "Prerequisite: adb must be installed on this machine."
info "  macOS:  brew install android-platform-tools"
info "  Linux:  sudo apt-get install adb"
info "  Windows: download from https://developer.android.com/tools/releases/platform-tools"
info ""
info "1. Enable ADB debugging on your Fire TV:"
info "   Settings → My Fire TV → Developer Options → ADB debugging: ON"
info "   Settings → My Fire TV → Developer Options → Apps from Unknown Sources: ON"
info ""
info "2. Find the Fire TV IP address:"
info "   Settings → My Fire TV → About → Network → IP address"
info ""
info "3. Connect and install:"
info "   adb connect <FIRE_TV_IP>:5555"
info "   adb install -r ${APK}"
info ""
info "4. Launch from the Fire TV app drawer or set as the default launcher."
echo ""
