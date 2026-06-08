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

# Always rebuild the companion web app before the APK so the server image never
# serves stale UI. The web build is gitignored — it must be regenerated from
# source on every build. Skipping this step silently bakes outdated companion
# code into the server and has caused bugs in every deploy that omitted it.
echo ""
echo "${CYAN}${BOLD}Building companion web app...${RESET}"
flutter build web --release --target lib/companion_web_main.dart
rm -rf "${REPO_ROOT}/server/landfall_server/web/app"
cp -r "${DISPLAY_DIR}/build/web" "${REPO_ROOT}/server/landfall_server/web/app"
ok "Companion web built and staged to server/landfall_server/web/app"
echo ""

echo "${CYAN}${BOLD}Building Fire TV APK...${RESET}"

# Optional server URLs, baked via --dart-define (both default to empty, which
# preserves the stock behavior: first-run setup wizard, single-origin client).
#
# For direct-port LAN validation against a Caddy-less dev server, set both so
# RPC and device-auth sign-in resolve to their separate ports (mirrors the Pi):
#   LANDFALL_DEFAULT_SERVER_URL=http://192.168.1.167:8080/ \
#   LANDFALL_WEB_SERVER_URL=http://192.168.1.167:8082/ \
#   bash tools/scripts/build_apk.sh
# Omit LANDFALL_DEFAULT_SERVER_URL to keep the setup wizard; LANDFALL_WEB_SERVER_URL
# alone is enough for sign-in to reach the web server while you type the :8080
# RPC URL in the wizard.
LANDFALL_DEFAULT_SERVER_URL="${LANDFALL_DEFAULT_SERVER_URL:-}"
LANDFALL_WEB_SERVER_URL="${LANDFALL_WEB_SERVER_URL:-}"

if [[ -n "${LANDFALL_DEFAULT_SERVER_URL}" ]]; then
  info "Baking LANDFALL_DEFAULT_SERVER_URL=${LANDFALL_DEFAULT_SERVER_URL}"
fi
if [[ -n "${LANDFALL_WEB_SERVER_URL}" ]]; then
  info "Baking LANDFALL_WEB_SERVER_URL=${LANDFALL_WEB_SERVER_URL}"
fi

info "Cleaning build cache..."
flutter clean
info "Building release APK..."
flutter build apk --release \
  --dart-define=LANDFALL_DEFAULT_SERVER_URL="${LANDFALL_DEFAULT_SERVER_URL}" \
  --dart-define=LANDFALL_WEB_SERVER_URL="${LANDFALL_WEB_SERVER_URL}"

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
