#!/usr/bin/env bash
# Landfall OTA update — placeholder.
#
# Automatic over-the-air updates are deferred until after the beta. The
# decisions that need to be made first (signing key management, A/B
# partitioning, rollback policy, release infrastructure) are documented
# in docs/updating.md and docs/roadmap.md.
#
# When OTA lands, this script will be replaced with the real update
# orchestrator. Until then, run it to discover the manual procedure.

cat <<'EOF'
Landfall OTA updates are not yet implemented.

For the beta phase, the default update procedure is:

  Build a fresh image on the dev host, flash it to the SD card,
  restore the Pi's data volumes + .env on first boot.

Full step-by-step (with the data-preservation steps so you don't lose
your linked accounts, profiles, layouts, etc.):

  https://github.com/evanpthompson/landfall/blob/main/docs/updating.md

Two in-place procedures exist as edge cases for when you have a
healthy running Pi and want to avoid a reflash:

  - Server-only update (Landfall server changed, nothing else)
  - Display-only update (Flutter binary changed, nothing else)

Both are documented in the same file. Use them only if you understand
what changed in the new build — otherwise reflash, which is the path
that's actually exercised every release.

OTA arrives post-beta; this script will be replaced then.
EOF

exit 0
