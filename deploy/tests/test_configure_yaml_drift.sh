#!/usr/bin/env bash
# Regression test: configure.sh --from-yaml must warn when the user's
# passwords.yaml is missing keys that passwords.yaml.template defines.
# This catches silent breakage when a template key is renamed and the user's
# local yaml still uses the old name (e.g. googleClientId vs googleOAuthClientId).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CONFIGURE="${REPO_ROOT}/deploy/pi-gen/configure.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

# Yaml that uses the *old* key names (the real-world drift we hit).
cat > "${tmp}/passwords-drift.yaml" <<'YAML'
shared:
  googleClientId: 'fake-client-id'
  googleClientSecret: 'fake-secret'
  googleDriveFolderId: 'fake-folder'
  smtpHost: 'smtp.example.com'
  smtpPort: '587'
  smtpUsername: 'u'
  smtpPassword: 'p'
  smtpFromEmail: 'f@e.com'
  smtpFromName: 'L'
YAML

output="$(LANDFALL_CONFIG_OUTPUT="${tmp}/build.conf" \
          bash "${CONFIGURE}" --from-yaml "${tmp}/passwords-drift.yaml" 2>&1)"

# Must announce the drift and name both the missing canonical key and the
# typo-likely key actually present in the user's yaml.
echo "${output}" | grep -q "missing keys expected by passwords.yaml.template" \
  || { echo "FAIL: drift check did not announce missing keys"; echo "--- output ---"; echo "${output}"; exit 1; }
echo "${output}" | grep -q "googleOAuthClientId" \
  || { echo "FAIL: drift check did not list googleOAuthClientId as missing"; echo "--- output ---"; echo "${output}"; exit 1; }
echo "${output}" | grep -q "googleClientId" \
  || { echo "FAIL: drift check did not suggest the user's googleClientId as likely rename"; echo "--- output ---"; echo "${output}"; exit 1; }

# Yaml that matches the template exactly must produce no drift warning.
# Build it by reading the template and stripping envsubst placeholders.
template="${REPO_ROOT}/server/landfall_server/config/passwords.yaml.template"
sed -E "s/\\\$\\{[^}]+\\}/placeholder/g" "${template}" > "${tmp}/passwords-clean.yaml"

clean_output="$(LANDFALL_CONFIG_OUTPUT="${tmp}/build-clean.conf" \
                bash "${CONFIGURE}" --from-yaml "${tmp}/passwords-clean.yaml" 2>&1)"

if echo "${clean_output}" | grep -q "missing keys expected by passwords.yaml.template"; then
  echo "FAIL: drift check fired on a template-aligned yaml"
  echo "--- output ---"
  echo "${clean_output}"
  exit 1
fi

echo "OK: configure.sh --from-yaml drift check works"
