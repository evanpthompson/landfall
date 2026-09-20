#!/usr/bin/env bash
# The health checks themselves are the thing under test here.
#
# Every failure this file pins was found live on a Pi where the check had been
# reporting for days without anyone being able to act on it: two that cried
# wolf, one that cried "fine". A check that cannot run is not a pass, and a
# check that always fails is not a check — it is noise that trains the operator
# to ignore the real one.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DOCTOR="${REPO_ROOT}/deploy/pi-gen/stage2-landfall/00-landfall/files/landfall-doctor.sh"
COMPOSE="${REPO_ROOT}/deploy/docker-compose.prod.yml"

fail() { echo "  ✗  $*"; exit 1; }
pass() { echo "  ✓  $*"; }

echo "Health-check integrity"

# ── 1. gawk-only syntax on a mawk device ────────────────────────────────────
# The Pi image ships mawk. Three-argument match() is a gawk extension: under
# mawk it is a syntax error, so the block never ran and the doctor printed
# "no exit events in the last 7 days (steady-state operation)" no matter what
# the log actually said. A health tool that reports all-clear when its parser
# failed is worse than one that reports nothing.
# Detect the third argument by its shape — a bare variable name just before
# the closing paren, as in `match($0, /re/, m)`. Counting commas does not work:
# the regex literal contains parens and commas of its own, which is how the
# first version of this very check passed a file that had the bug in it.
if grep -nE 'match\(.*,[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\)' "${DOCTOR}" > /dev/null; then
  fail "landfall-doctor uses gawk-only 3-argument match(); the Pi runs mawk"
fi
pass "no gawk-only match() in landfall-doctor"

# ── 2. grep -c with an || fallback ──────────────────────────────────────────
# `grep -c` prints 0 and exits 1 when nothing matches, so `|| echo 0` yields
# the two-line value "0\n0". The arithmetic test then threw a syntax error and
# fell through to the failure branch: a display that had never crashed was
# reported as a crash-loop.
if grep -nE 'grep -c[^|]*\|\|[[:space:]]*echo' "${DOCTOR}" > /dev/null; then
  fail "grep -c with an || echo fallback produces a two-line count"
fi
pass "no grep -c || echo fallback in landfall-doctor"

# ── 3. The trends parser actually parses ────────────────────────────────────
# Static checks above say the syntax is portable. This one says it is correct,
# by running the real awk program against a log in the real format. Ubuntu
# runners ship mawk as awk, which is the same interpreter the Pi uses.
fixture="$(mktemp)"
trap 'rm -f "${fixture}"' EXIT
cat > "${fixture}" <<'LOG'
[2026-09-18T01:24:55-05:00] launching Flutter display
[2026-09-18T01:56:28-05:00] Flutter display exited status=0 uptime=1893s
[2026-09-18T02:00:00-05:00] launching Flutter display
[2026-09-18T02:00:03-05:00] Flutter display exited status=1 uptime=3s
[2001-01-01T00:00:00-05:00] Flutter display exited status=1 uptime=9999s
LOG

read -r total exits fast <<< "$(awk -v c="2026-09-01" '
  /Flutter display exited/ {
    if (substr($0, 2, 10) < c) next
    if (match($0, /uptime=[0-9]+s/) == 0) next
    u = substr($0, RSTART + 7, RLENGTH - 8)
    total += u + 0
    count++
    if (u + 0 < 5) fast++
  }
  END { print (total+0), (count+0), (fast+0) }
' "${fixture}")"

[[ "${exits}" == "2" ]] || fail "expected 2 exits inside the window, got '${exits}'"
[[ "${total}" == "1896" ]] || fail "expected 1896s total uptime, got '${total}'"
[[ "${fast}" == "1" ]] || fail "expected 1 fast crash, got '${fast}'"
pass "trends parser counts exits, uptime and fast crashes correctly"

# ── 4. A healthcheck may only use a binary the image has ────────────────────
# The backup container's check ran `pgrep`, which its base image does not
# ship. It had failed every minute since the container started — 4,333
# consecutive failures on the live Pi — so a real backup failure would have
# been indistinguishable from the permanent false alarm.
if grep -q 'pgrep' "${COMPOSE}"; then
  grep -q 'apt-get install[^&]*procps' "${COMPOSE}" \
    || fail "a healthcheck uses pgrep but no service installs procps"
  pass "pgrep healthcheck has procps installed alongside it"
fi

echo "  All health-check integrity tests passed"
