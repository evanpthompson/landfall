#!/bin/bash
set -euo pipefail
apt-get update -q && apt-get install -y --no-install-recommends \
  cmake ninja-build clang libgtk-3-dev pkg-config \
  libblkid-dev liblzma-dev libsecret-1-dev lld
flutter build linux --release
