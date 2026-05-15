#!/usr/bin/env bash
# Verify a freshly built server image / stage tree against expected-components.yaml.
#
# Runs after `docker save | gzip` and before pi-gen assembles the .img. Checks
# the *actual files that will ship* (extracted from the Docker image, not the
# source tree) so silent build-pipeline drift fails the build immediately.
#
# Usage:
#   bash deploy/pi-gen/verify-artifact.sh \
#     --image landfall-server:latest \
#     --tarball /path/to/landfall-server.tar.gz \
#     --stage  /path/to/pi-gen/stage2-landfall/00-landfall/files \
#     --caddyfile /path/to/deploy/Caddyfile \
#     --expected /path/to/deploy/pi-gen/expected-components.yaml
#
# Exits 0 if all checks pass; nonzero with a summary of failures otherwise.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

IMAGE=""
TARBALL=""
STAGE=""
CADDYFILE="${REPO_ROOT}/deploy/Caddyfile"
EXPECTED="${SCRIPT_DIR}/expected-components.yaml"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image)     IMAGE="$2"; shift 2 ;;
    --tarball)   TARBALL="$2"; shift 2 ;;
    --stage)     STAGE="$2"; shift 2 ;;
    --caddyfile) CADDYFILE="$2"; shift 2 ;;
    --expected)  EXPECTED="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -n "${IMAGE}"    ]] || { echo "verify-artifact: --image required" >&2; exit 2; }
[[ -n "${TARBALL}"  ]] || { echo "verify-artifact: --tarball required" >&2; exit 2; }
[[ -n "${STAGE}"    ]] || { echo "verify-artifact: --stage required" >&2; exit 2; }
[[ -f "${EXPECTED}" ]] || { echo "verify-artifact: expected file not found: ${EXPECTED}" >&2; exit 2; }

GREEN=$'\033[1;32m'; RED=$'\033[1;31m'; YELLOW=$'\033[1;33m'; RESET=$'\033[0m'

FAILS=()
pass() { echo "${GREEN}✓${RESET} $*"; }
fail() { echo "${RED}✗${RESET} $*"; FAILS+=("$*"); }
warn() { echo "${YELLOW}⚠${RESET} $*"; }

# Extract /app/web/app from the just-built image into a temp dir.
TMP="$(mktemp -d -t lf-verify-XXXXXX)"
trap 'rm -rf "${TMP}"; [[ -n "${CID:-}" ]] && docker rm -f "${CID}" >/dev/null 2>&1 || true' EXIT

CID="$(docker create "${IMAGE}")"
docker cp "${CID}:/app/web/app" "${TMP}/web_app"
docker rm "${CID}" >/dev/null
CID=""

# Tiny YAML reader for the leaf scalars we care about. Stdlib-only — pyyaml
# isn't a build-host dependency. Handles the exact shapes expected-components.yaml
# uses: top-level keys, 2-space-indented child keys (scalar or list-of-strings),
# 4-space-indented `- item` list entries. Inline `# comments` are stripped.
yaml_value() {
  # yaml_value <key.path>  — dotted path; scalars print one line, lists print one per line.
  python3 - "$1" "${EXPECTED}" <<'PY'
import sys
target = sys.argv[1].split('.')
sections = {}
cur_top = None
cur_child = None
with open(sys.argv[2]) as f:
    for raw in f:
        line = raw.rstrip('\n')
        stripped = line.lstrip()
        if not stripped or stripped.startswith('#'):
            continue
        # strip inline comments (safe for this file: no '#' inside quoted values)
        if '#' in stripped:
            stripped = stripped.split('#', 1)[0].rstrip()
            if not stripped:
                continue
        indent = len(line) - len(line.lstrip())

        def unquote(v):
            v = v.strip()
            if len(v) >= 2 and v[0] == v[-1] and v[0] in ("'", '"'):
                v = v[1:-1]
            return v

        if indent == 0 and stripped.endswith(':'):
            cur_top = stripped[:-1].strip()
            cur_child = None
            sections.setdefault(cur_top, {})
        elif indent == 2 and cur_top is not None:
            if stripped.startswith('- '):
                v = unquote(stripped[2:])
                node = sections[cur_top].get(cur_child)
                if not isinstance(node, list):
                    sections[cur_top][cur_child] = []
                sections[cur_top][cur_child].append(v)
            elif ':' in stripped:
                k, _, v = stripped.partition(':')
                cur_child = k.strip()
                v = v.strip()
                if v == '':
                    sections[cur_top][cur_child] = None  # nested list follows
                elif v in ('true', 'false'):
                    sections[cur_top][cur_child] = (v == 'true')
                else:
                    sections[cur_top][cur_child] = unquote(v)
        elif indent == 4 and stripped.startswith('- ') and cur_top and cur_child:
            v = unquote(stripped[2:])
            node = sections[cur_top].get(cur_child)
            if not isinstance(node, list):
                sections[cur_top][cur_child] = []
            sections[cur_top][cur_child].append(v)

node = sections
for k in target:
    if isinstance(node, dict) and k in node:
        node = node[k]
    else:
        sys.exit(1)

if node is None:
    sys.exit(1)
elif isinstance(node, bool):
    print('true' if node else 'false')
elif isinstance(node, list):
    for v in node:
        print(v)
else:
    print(node)
PY
}

# ── 1. flutter_bootstrap.js: required tokens ──────────────────────────────────
BOOTSTRAP="${TMP}/web_app/flutter_bootstrap.js"
if [[ ! -f "${BOOTSTRAP}" ]]; then
  fail "flutter_bootstrap.js missing from image at /app/web/app/"
else
  while IFS= read -r needle; do
    if grep -qF -- "${needle}" "${BOOTSTRAP}"; then
      pass "bootstrap contains: ${needle}"
    else
      fail "bootstrap missing required token: ${needle}"
    fi
  done < <(yaml_value companion_web.bootstrap_must_contain || true)
fi

# ── 2. canvaskit.wasm: must exist and be ≥ min bytes ──────────────────────────
WASM="${TMP}/web_app/canvaskit/canvaskit.wasm"
MIN_WASM="$(yaml_value companion_web.canvaskit_wasm_min_bytes || echo 0)"
if [[ ! -f "${WASM}" ]]; then
  fail "canvaskit.wasm missing — local CanvasKit reference will 404 at runtime"
else
  SIZE="$(stat -f%z "${WASM}" 2>/dev/null || stat -c%s "${WASM}")"
  if (( SIZE >= MIN_WASM )); then
    pass "canvaskit.wasm size ${SIZE} ≥ ${MIN_WASM}"
  else
    fail "canvaskit.wasm size ${SIZE} < required ${MIN_WASM}"
  fi
fi

# ── 3. FontManifest.json: every expected family is listed ─────────────────────
FONT_MANIFEST="${TMP}/web_app/assets/FontManifest.json"
if [[ ! -f "${FONT_MANIFEST}" ]]; then
  fail "FontManifest.json missing from image"
else
  while IFS= read -r family; do
    if python3 -c "
import json,sys
m=json.load(open(sys.argv[1]))
sys.exit(0 if any(e.get('family')==sys.argv[2] for e in m) else 1)
" "${FONT_MANIFEST}" "${family}"; then
      pass "FontManifest lists family: ${family}"
    else
      fail "FontManifest missing family: ${family} (Flutter will fetch from gstatic.com)"
    fi
  done < <(yaml_value companion_web.font_manifest_must_include || true)
fi

# ── 4. Service worker: present XOR absent per policy ──────────────────────────
SW="${TMP}/web_app/flutter_service_worker.js"
SW_EXPECTED="$(yaml_value companion_web.service_worker_present || echo true)"
if [[ "${SW_EXPECTED}" == "false" ]]; then
  if [[ -e "${SW}" ]]; then
    fail "flutter_service_worker.js present but policy says it must be absent"
  else
    pass "no flutter_service_worker.js (policy: absent)"
  fi
  # Also confirm the registration is gone from index.html.
  if [[ -f "${TMP}/web_app/index.html" ]] && grep -q "flutter_service_worker" "${TMP}/web_app/index.html"; then
    fail "index.html still references flutter_service_worker — registration not stripped"
  fi
else
  [[ -f "${SW}" ]] && pass "flutter_service_worker.js present" || fail "flutter_service_worker.js missing (policy: present)"
fi

# ── 5. Cache-busting query strings on script tags ─────────────────────────────
NEED_VQ="$(yaml_value companion_web.script_tags_must_have_version_query || echo false)"
if [[ "${NEED_VQ}" == "true" && -f "${TMP}/web_app/index.html" ]]; then
  if grep -E 'src="[^"]*(flutter_bootstrap|main\.dart)\.js\?v=[^"]+"' "${TMP}/web_app/index.html" >/dev/null; then
    pass "index.html script tags carry ?v=<sha> cache-buster"
  else
    fail "index.html script tags missing ?v=<sha> cache-buster"
  fi
fi

# ── 6. Tarball hygiene: forbidden paths ───────────────────────────────────────
# docker save tarball contains layer tars; gunzip + look for any file path
# ending with the forbidden name in any layer.
TARBALL_INDEX="${TMP}/tarball.index"
gunzip -c "${TARBALL}" | tar -t > "${TARBALL_INDEX}" 2>/dev/null || true
while IFS= read -r forbidden; do
  if grep -E "(^|/)${forbidden}(/|$)" "${TARBALL_INDEX}" >/dev/null; then
    fail "server tarball contains forbidden path: ${forbidden}"
  else
    pass "server tarball clean of: ${forbidden}"
  fi
done < <(yaml_value server_tarball.forbidden_paths || true)
# Note: this catches it at the outer layer (manifest, blobs/). Each layer is a
# nested tar — for thorough scanning we'd unpack layers. For now the outer scan
# catches the common cases (deploy/.env staged into the build context, etc.).
for forbidden in $(yaml_value server_tarball.forbidden_paths || true); do
  # Unpack any layer tar that mentions the forbidden name and re-scan.
  while IFS= read -r layer; do
    if gunzip -c "${TARBALL}" 2>/dev/null | tar -xO "${layer}" 2>/dev/null \
        | tar -t 2>/dev/null | grep -E "(^|/)${forbidden}(/|$)" >/dev/null; then
      fail "server tarball layer ${layer} contains forbidden path: ${forbidden}"
    fi
  done < <(grep -E 'layer\.tar$|blobs/sha256/' "${TARBALL_INDEX}" || true)
done

# ── 7. Stage tree hygiene ─────────────────────────────────────────────────────
while IFS= read -r forbidden; do
  if find "${STAGE}" -name "${forbidden}" -print -quit | grep -q .; then
    fail "stage tree contains forbidden path: ${forbidden}"
  else
    pass "stage tree clean of: ${forbidden}"
  fi
done < <(yaml_value stage.forbidden_paths || true)

# ── 8. Caddyfile CSP connect-src ⊇ hosts in compiled JS ───────────────────────
MAIN_JS="${TMP}/web_app/main.dart.js"
if [[ -f "${MAIN_JS}" && -f "${CADDYFILE}" ]]; then
  CSP_LINE="$(grep -E 'Content-Security-Policy' "${CADDYFILE}" || true)"
  CONNECT_SRC="$(echo "${CSP_LINE}" | sed -nE 's/.*connect-src ([^;]*);.*/\1/p')"
  # Hosts that appear only as string literals in framework messages — never fetched.
  IGNORE_HOSTS="$(yaml_value caddy.csp_connect_src_string_literal_hosts || true)"
  # Extract scheme://host patterns from main.dart.js. We accept self-only
  # builds; the check fires only when an absolute URL appears in the JS.
  HOSTS="$(grep -oE 'https?://[a-zA-Z0-9_.-]+|wss?://[a-zA-Z0-9_.-]+' "${MAIN_JS}" \
            | sort -u || true)"
  if [[ -z "${HOSTS}" ]]; then
    pass "main.dart.js references no absolute http(s)/ws(s) hosts"
  else
    while IFS= read -r host; do
      [[ -z "${host}" ]] && continue
      origin="$(echo "${host}"   | sed -E 's#^(https?|wss?)://([^/]+).*#\1://\2#')"
      hostname="$(echo "${host}" | sed -E 's#^[a-z]+://([^/]+).*#\1#')"
      # Suppress string-literal-only hosts (framework error messages etc.).
      if [[ -n "${IGNORE_HOSTS}" ]] && \
         echo "${IGNORE_HOSTS}" | grep -qxF "${hostname}"; then
        pass "CSP ignores string-literal host: ${origin}"
        continue
      fi
      # Allow if the origin or hostname appears in connect-src verbatim, or if
      # connect-src includes 'self' and the host is localhost / 127.0.0.1.
      if echo "${CONNECT_SRC}" | grep -qE "(${hostname}|${origin})"; then
        pass "CSP allows host from main.dart.js: ${origin}"
      elif [[ "${hostname}" =~ ^(localhost|127\.0\.0\.1)$ ]] && \
           echo "${CONNECT_SRC}" | grep -q "'self'"; then
        pass "CSP 'self' covers loopback host: ${origin}"
      else
        fail "CSP connect-src missing host referenced from main.dart.js: ${origin}"
      fi
    done <<< "${HOSTS}"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
if (( ${#FAILS[@]} == 0 )); then
  echo "${GREEN}verify-artifact: all checks passed${RESET}"
  exit 0
fi
echo "${RED}verify-artifact: ${#FAILS[@]} failure(s):${RESET}"
for f in "${FAILS[@]}"; do echo "  • $f"; done
exit 1
