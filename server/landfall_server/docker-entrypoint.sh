#!/bin/sh
set -e

# Render config templates from environment variables.
# envsubst replaces ${VAR} placeholders; unset vars become empty strings.
envsubst < /app/config/production.yaml.template > /app/config/production.yaml
envsubst < /app/config/passwords.yaml.template  > /app/config/passwords.yaml

exec /app/server \
  --mode=production \
  --server-id=default \
  --logging=normal \
  --role=monolith \
  --apply-migrations \
  "$@"
