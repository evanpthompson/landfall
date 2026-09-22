# Agent instructions: landfall

**Read this before touching secrets, the Pi, or anything that deploys.**

This file is canonical and harness-neutral — Codex, Cursor, Copilot, Zed,
Aider, Windsurf, Jules and Claude Code all read this filename. `CLAUDE.md`
beside it is a symlink to it. Do not let them drift.

## This repository is public

`github.com/evanpthompson/landfall` is **public**. Anything committed here is
world-readable and stays in history after deletion. The architecture-decisions
record and the phased delivery plan live in a separate private repo and must
stay there.

Two consequences that are easy to get wrong:

- **No LAN addresses, hostnames or account names in tracked files.** The Pi is
  reached through `$LANDFALL_PI` (below), never a literal. Thirteen references
  to the production Pi were removed in `8b3ea51`; do not reintroduce them.
- **Tests keep literal private addresses on purpose.** `isPrivateLanIpv4`
  accepts only RFC1918, so an RFC 5737 documentation range would be rejected
  and the suite would fail for the wrong reason. Use an arbitrary RFC1918
  address — a test that reads its expectations from the environment is not a
  test.

## Secrets: gitignored is half the job

Three files hold live credentials. All are gitignored and none has ever been
committed. **All three must be mode 600** — every one was found at 644 on
2026-09-21.

| File | Holds |
|---|---|
| `server/landfall_server/config/passwords.yaml` | Serverpod secrets, OAuth, HMAC, Stripe |
| `deploy/pi-gen/landfall-build.conf` | wifi + SSH passwords, OpenWeather, Google, Microsoft, Stripe |
| `deploy/.env` | compose secrets, and `LANDFALL_PI_IP` |

`passwords_file_guard.dart` enforces this for the first file only: the server
**refuses to start** when it is world-readable in any run mode outside
`development` and `test`. The other two have no such guard.

**`passwords.yaml` is baked into the image, not mounted.** `Dockerfile:43`
copies `config/` into the build, so its permissions are decided on the machine
that runs `push-server.sh` — your Mac — not on the Pi. A `chmod` on the Pi
fixes nothing.

Never write a credential into a tracked file. `passwords.yaml.template` and
`.example` are the tracked stand-ins.

## Reaching the Pi

Resolution order, defined by `deploy/scripts/push-server.sh` and mirrored by
every runbook:

1. `LANDFALL_PI_IP` in the environment
2. a `LANDFALL_PI_IP=` line in the gitignored `deploy/.env`
3. `landfall.local` — `avahi-daemon` ships in the image, so mDNS works on a
   normal LAN with no configuration

```bash
export LANDFALL_PI=landfall@${LANDFALL_PI_IP:-landfall.local}
```

`sudo` on the Pi needs a password, so root changes cannot be applied from a
tool shell. `~/files/automation/landfall/apply-pi-root-fixes.sh` installs them;
run it yourself.

## The repo and the running Pi have drifted

The live machine was imaged before parts of this repo existed. Verify, do not
assume:

- **`landfall-display.service` is not installed.** It ships in
  `deploy/pi-gen/stage2-landfall/00-landfall/files/`, but the Pi starts the
  display from openbox autostart. `tools/scripts/build_linux.sh:110` prints
  `systemctl restart landfall-display` as the deploy step and it fails.
  The lever that works is `systemctl restart lightdm`, or `pkill` on the
  display binary — the session script relaunches it in a loop.
- **A fix applied only to the running Pi is one a reflash deletes.** Anything
  installed by hand also goes into `00-run.sh` in the same change.
- **The display leaks ~11.8 MB/hour** and nothing catches it: the watchdog only
  fires when the display process *disappears*, which a leak never causes.
  `landfall-display-restart.timer` restarts it nightly as a stopgap.

## TDD is non-negotiable

Red → Green → Refactor. No production code without a failing test first.

| What ships | Required tests |
|---|---|
| Every `Cubit` / `Bloc` | `bloc_test` suite covering **all** state transitions |
| Every public widget | Widget test + golden test at 1920×1080 |
| Every Serverpod endpoint | Integration test via the Serverpod test framework |
| Every repository interface | Contract test against both mock and real implementation |
| Every use case | Unit test covering success, failure and edge cases |

Phase plans list the test before the code it drives: "Test: [what it verifies]
→ Code: [what it implements]". Never call a feature complete without unit,
widget/integration and end-to-end all covered.

**A silent assert-based test that passes and one that never ran look
identical.** `deploy/tests/*.sh` print nothing on success. When you change an
assertion, mutate it and confirm it fails before trusting the green.

## The gates

```
flutter analyze                             no issues
flutter test                                green across all packages
dart test                                   in server/landfall_server
bash deploy/tests/test_build_stage_only.sh  silent; exit 0 is the pass
```

`deploy/tests/test_build_stage_only.sh` overwrites
`deploy/pi-gen/landfall-build.conf` and restores it from a trap. Back it up
before running if you value the contents.

## Documentation index

`docs/README.md` is the canonical index of every doc in the repo. Adding,
renaming, moving or deleting any `.md` updates it in the same commit. The root
`README.md` links into the index — do not re-list individual docs there.

## Commit discipline

- **No AI attribution.** No `Co-Authored-By`, no session trailers.
- One logical change per commit.
- The message describes the why, not the what.
