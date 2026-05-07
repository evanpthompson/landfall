#!/bin/bash
# Landfall first-boot initialization.
# Runs once as a systemd one-shot service on the first boot after flashing.
# Loads the pre-built server Docker image and marks the system as initialized.
# Subsequent boots skip this script; landfall-server.service handles docker compose.

set -euo pipefail

log() { echo "[landfall-firstboot] $*"; }

IMAGE_TARBALL="/opt/landfall/landfall-server.tar.gz"
INITIALIZED_FLAG="/var/lib/landfall/.initialized"

log "Loading Landfall server Docker image..."
if [[ -f "${IMAGE_TARBALL}" ]]; then
  docker load < "${IMAGE_TARBALL}"
  log "Image loaded — removing tarball to reclaim space"
  rm -f "${IMAGE_TARBALL}"
else
  log "WARNING: ${IMAGE_TARBALL} not found — skipping image load"
  log "The server container may fail to start if the image was not pre-loaded."
fi

mkdir -p /var/lib/landfall
touch "${INITIALIZED_FLAG}"
log "First-boot initialization complete"
