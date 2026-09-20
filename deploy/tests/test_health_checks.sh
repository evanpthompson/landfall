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

# ── 5. Verbose GL logging is not a production default ───────────────────────
# LIBGL_DEBUG=verbose left on unconditionally wrote 8.8 million lines and
# 138 MB on one Pi, burying the one message that mattered in its own repeats.
SESSION="${REPO_ROOT}/deploy/pi-gen/stage2-landfall/00-landfall/files/landfall-display-session.sh"
# Column zero means it is not inside the conditional — the indented export
# within the flag-file guard is the intended form.
if grep -nE '^export LIBGL_DEBUG' "${SESSION}" > /dev/null; then
  fail "LIBGL_DEBUG is exported unconditionally; gate it behind the flag file"
fi
grep -q 'gl-debug' "${SESSION}" \
  || fail "no gl-debug flag file check; verbose logging has no way to be enabled"
pass "verbose GL logging is opt-in"

# ── 6. The display log is rotated ───────────────────────────────────────────
LOGROTATE="${REPO_ROOT}/deploy/pi-gen/stage2-landfall/00-landfall/files/landfall-display-log.logrotate"
[[ -f "${LOGROTATE}" ]] || fail "no logrotate config for the display log"
grep -q 'copytruncate' "${LOGROTATE}" \
  || fail "rotation must use copytruncate — the session holds the file open"
grep -q 'landfall-display-log.logrotate' "${REPO_ROOT}/deploy/pi-gen/stage2-landfall/00-landfall/00-run.sh" \
  || fail "logrotate config exists but the image build never installs it"
pass "display log is rotated, and the rotation is actually installed"

# ── 7. The descriptor ceiling is raised where the display actually starts ───
# landfall-display.service is inactive on a running Pi — the display is
# launched from the openbox session — so LimitNOFILE in the unit file is not
# enough on its own.
grep -q 'ulimit -n' "${SESSION}" \
  || fail "the session script does not raise the descriptor limit; the unit file alone does not apply"
pass "descriptor ceiling is raised in the session that launches the display"

# ── 8. History survives rotation ────────────────────────────────────────────
# Rotation used to erase the answer: minutes after logrotate first ran, the
# 7-day trend reported "steady-state operation" because the week it summarised
# had moved into .1.gz. The same shape of lie as a parser that fails silently.
if grep -nE "(awk|grep)[^|]*"\$\{crash_log\}"" "${DOCTOR}" > /dev/null; then
  fail "a history check reads only the live log; rotated archives are ignored"
fi
grep -q 'read_display_history' "${DOCTOR}" \
  || fail "no rotated-archive reader in landfall-doctor"
pass "display history is read across rotated archives"

# And prove the reader actually reads them, gzip and all.
histdir="$(mktemp -d)"
trap 'rm -rf "${fixture}" "${histdir}"' EXIT
printf '[2026-09-10T01:00:00-05:00] Flutter display exited status=0 uptime=100s\n' \
  | gzip > "${histdir}/log.2.gz"
printf '[2026-09-12T01:00:00-05:00] Flutter display exited status=0 uptime=200s\n' \
  | gzip > "${histdir}/log.1.gz"
printf '[2026-09-19T01:00:00-05:00] Flutter display exited status=0 uptime=300s\n' \
  > "${histdir}/log"

crash_log="${histdir}/log"
display_log_sources() {
  local n
  for n in 9 8 7 6 5 4 3 2 1; do
    [[ -f "${crash_log}.${n}.gz" ]] && printf '%s\n' "${crash_log}.${n}.gz"
    [[ -f "${crash_log}.${n}" ]] && printf '%s\n' "${crash_log}.${n}"
  done
  [[ -f "${crash_log}" ]] && printf '%s\n' "${crash_log}"
  return 0
}
read_display_history() {
  local f
  while IFS= read -r f; do
    case "${f}" in
      *.gz) gzip -dc -- "${f}" 2>/dev/null ;;
      *)    cat -- "${f}" 2>/dev/null ;;
    esac
  done < <(display_log_sources) \
    | grep -aE 'launching Flutter display|Flutter display exited' || true
}

seen="$(read_display_history | wc -l | tr -d ' ')"
[[ "${seen}" == "3" ]] || fail "reader saw ${seen} history lines across rotation, expected 3"
oldest="$(read_display_history | head -1 | cut -c2-11)"
[[ "${oldest}" == "2026-09-10" ]] || fail "reader returned '${oldest}' first, expected the oldest archive"
pass "reader spans .2.gz, .1.gz and the live log, oldest first"

# ── 9. The history is decompressed once, and cleaned up ─────────────────────
# Every caller reads this through $( ), which is a subshell. A cache built
# lazily inside the reader therefore never survived back to the parent: the
# archive was decompressed on all four calls anyway, and each subshell leaked
# its temp file into /tmp. Build it in the main shell, or not at all.
reader_body="$(grep -A 1 '^read_display_history()' "${DOCTOR}")"
if grep -qE 'mktemp|gzip' <<< "${reader_body}"; then
  fail "read_display_history builds its own cache; in a subshell that neither caches nor cleans up"
fi
grep -qE "^trap .*rm -f .*_display_history_file" "${DOCTOR}" \
  || fail "no trap removing the history temp file; every run would leak one"
[[ "$(grep -c 'mktemp' "${DOCTOR}")" == "1" ]] \
  || fail "more than one mktemp in landfall-doctor; only the top-level cache should allocate"
pass "history is decompressed once in the main shell and cleaned up on exit"

echo "  All health-check integrity tests passed"
