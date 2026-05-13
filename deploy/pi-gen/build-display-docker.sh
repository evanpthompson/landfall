#!/bin/bash
set -euo pipefail
apt-get update -q && apt-get install -y --no-install-recommends \
  cmake ninja-build clang llvm libgtk-3-dev pkg-config \
  libblkid-dev liblzma-dev libsecret-1-dev lld

# Telemetry: empty by default (production). Debug builds set
# LANDFALL_TELEMETRY_ENDPOINT to point at the Pi's own local server
# (loopback bypass means no API key needed — see telemetry_route.dart).
flutter build linux --release \
  --dart-define=LANDFALL_DEFAULT_SERVER_URL="${LANDFALL_DEFAULT_SERVER_URL:-http://127.0.0.1:8080/}" \
  --dart-define=LANDFALL_WEB_SERVER_URL="${LANDFALL_WEB_SERVER_URL:-http://127.0.0.1:8082/}" \
  --dart-define=LANDFALL_TELEMETRY_ENDPOINT="${LANDFALL_TELEMETRY_ENDPOINT:-}" \
  --dart-define=LANDFALL_TELEMETRY_API_KEY="${LANDFALL_TELEMETRY_API_KEY:-}"
