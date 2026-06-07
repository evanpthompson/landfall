#!/usr/bin/env bash
# Verifies that every .md file under docs/ is indexed in docs/README.md,
# and that every .md link in docs/README.md resolves to an existing file.
#
# Run from anywhere in the repo. Exits 1 on any violation so CI can block.
# Follows the same pattern as deploy/tests/test_caddyfile_routes.sh.
#
# Two rules enforced:
#   A. Coverage:  every docs/*.md exists as a link target in docs/README.md
#   B. Integrity: every relative .md link in docs/README.md resolves to a real file

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DOCS_DIR="${REPO_ROOT}/docs"
INDEX="${DOCS_DIR}/README.md"

[[ -f "${INDEX}" ]] || { echo "docs/README.md not found at ${INDEX}" >&2; exit 1; }

fail=0

# ---------------------------------------------------------------------------
# Rule A: every .md file in docs/ must appear in docs/README.md
# ---------------------------------------------------------------------------
while IFS= read -r -d '' md_file; do
  filename="$(basename "${md_file}")"
  # The index references same-directory files as (filename.md) or [text](filename.md)
  if ! grep -qF "${filename}" "${INDEX}"; then
    echo "FAIL [coverage]: docs/${filename} is not referenced in docs/README.md" >&2
    fail=1
  fi
done < <(find "${DOCS_DIR}" -maxdepth 1 -name '*.md' -not -name 'README.md' -print0)

# ---------------------------------------------------------------------------
# Rule B: every relative .md link in docs/README.md must resolve
#
# Matches both same-directory refs like (file.md) and repo-root refs like
# (../CLAUDE.md). Ignores http/https links.
# ---------------------------------------------------------------------------
while IFS= read -r link; do
  # Skip absolute URLs
  [[ "${link}" == http* ]] && continue

  if [[ "${link}" == ../* ]]; then
    target="${REPO_ROOT}/${link#../}"
  else
    target="${DOCS_DIR}/${link}"
  fi

  if [[ ! -f "${target}" ]]; then
    echo "FAIL [integrity]: docs/README.md links to '${link}' but file does not exist: ${target}" >&2
    fail=1
  fi
done < <(grep -oE '\([^)]+\.md[^)]*\)' "${INDEX}" | tr -d '()' | sed 's/#[^)]*$//')

if (( fail == 1 )); then
  exit 1
fi

echo "OK: docs/README.md covers all docs/*.md files and all links resolve"
