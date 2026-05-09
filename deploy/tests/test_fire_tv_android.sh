#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DISPLAY_DIR="${REPO_ROOT}/apps/display"
MANIFEST="${DISPLAY_DIR}/android/app/src/main/AndroidManifest.xml"
GRADLE_FILE="${DISPLAY_DIR}/android/app/build.gradle.kts"
MAIN_ACTIVITY="${DISPLAY_DIR}/android/app/src/main/kotlin/io/landfall/display/MainActivity.kt"

[[ -f "${MANIFEST}" ]] || { echo "Missing Android manifest" >&2; exit 1; }
[[ -f "${GRADLE_FILE}" ]] || { echo "Missing Android Gradle config" >&2; exit 1; }
[[ -f "${MAIN_ACTIVITY}" ]] || { echo "Missing Landfall MainActivity" >&2; exit 1; }

grep -q 'applicationId = "io.landfall.display"' "${GRADLE_FILE}"
grep -q 'namespace = "io.landfall.display"' "${GRADLE_FILE}"

grep -q 'android.permission.INTERNET' "${MANIFEST}"
grep -q 'android.software.leanback' "${MANIFEST}"
grep -q 'android.hardware.touchscreen' "${MANIFEST}"
grep -q 'android:required="false"' "${MANIFEST}"
grep -q 'android.intent.category.LEANBACK_LAUNCHER' "${MANIFEST}"
grep -q 'android.intent.category.LAUNCHER' "${MANIFEST}"
grep -q 'android:screenOrientation="landscape"' "${MANIFEST}"
grep -q 'android:banner="@drawable/tv_banner"' "${MANIFEST}"

grep -q '^package io.landfall.display$' "${MAIN_ACTIVITY}"
