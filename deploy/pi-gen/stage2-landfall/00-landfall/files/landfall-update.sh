#!/usr/bin/env bash
# Landfall OTA update — placeholder.
#
# Automatic over-the-air updates are deferred until after the beta. The
# decisions that need to be made first (signing key management, A/B
# partitioning, rollback policy, release infrastructure) are documented
# in docs/updating.md.
#
# When OTA lands, this script will be replaced with the real update
# orchestrator. Until then, run it to discover the manual procedures.

cat <<'EOF'
Landfall OTA updates are not yet implemented.

For now, every update is a manual procedure. The three supported
update paths — server-only, display-only, and full image reflash —
are documented in detail at:

  https://github.com/evanpthompson/landfall/blob/main/docs/updating.md

Quick reference:

  Server only       (most common, ~3 min)   →  Procedure A
  Display only      (Flutter changes)       →  Procedure B
  Full image flash  (kernel / major version) →  Procedure C

All procedures preserve your data — Postgres, Redis, Caddy certs, and
the per-device secrets in .env survive untouched through reflashes.

When OTA arrives post-beta, this script will be replaced.
EOF

exit 0
