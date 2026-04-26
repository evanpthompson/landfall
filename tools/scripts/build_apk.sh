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
RESET=$'\033[0m'

ok()   { echo "${GREEN}✓  $*${RESET}"; }
info() { echo "   $*"; }

echo ""
echo "${CYAN}${BOLD}Landfall — Fire TV APK build${RESET}"
echo ""

command -v flutter > /dev/null || { echo "flutter not found"; exit 1; }

cd "${DISPLAY_DIR}"

info "Building release APK..."
flutter build apk --release

APK="${DISPLAY_DIR}/build/app/outputs/flutter-apk/app-release.apk"
ok "APK ready: ${APK}"

echo ""
echo "${BOLD}Sideload to Fire TV:${RESET}"
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
