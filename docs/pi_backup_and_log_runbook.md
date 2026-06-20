# Pi backup & display-log issues — investigation and resolution

Investigated 2026-06-20 on the production Pi (`landfall@192.168.1.129`, image
reflashed 2026-06-08). Two operator-visible symptoms were reported: a 301 MB
display log and a `deploy-backup-1` container stuck **unhealthy**. Both were
investigated live; fixes below are not yet applied — they are staged for a
post-event maintenance window.

---

## Issue 1 — Nightly Postgres backups are EMPTY (critical)

### Symptom
`deploy-backup-1` shows `Up (unhealthy)`. The nightly dumps in the `backup_data`
volume are **20 bytes each** (gzip of empty input) for every day Jun 14–20:

```
/backups/landfall_20260620_020001.sql.gz   20 bytes   → decompresses to 0 bytes
```

A manual `docker exec deploy-backup-1 /backup.sh` produces a **valid 345 KB**
dump, so Postgres and `pg_dump` themselves are fine (client/server both 16.14).

### Root cause — cron does not inherit the container environment
`deploy/docker-compose.prod.yml` (backup service) sets `PGHOST`, `PGUSER`,
`PGPASSWORD`, `PGDATABASE` as **container** env vars and registers the job with
`echo '0 2 * * * /backup.sh' | crontab -`. cron runs jobs with a minimal
environment and does **not** export the container's env into them, so at 02:00
`/backup.sh` runs with `PGHOST` unset. `pg_dump` then falls back to the local
unix socket, which does not exist in the backup container:

```
pg_dump: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432"
         failed: No such file or directory
```

Reproduced by simulating cron's env: `docker exec deploy-backup-1 env -i
PATH=... sh -c 'pg_dump --no-password'` → the socket error above.
`docker exec /backup.sh` works only because exec inherits the full container env.

### Contributing defect — the failure is silently masked
`deploy/scripts/backup.sh` does `pg_dump --no-password | gzip > "$FILE"`. With
`set -e`, only the **last** command in a pipeline (`gzip`) is checked, so a
failed `pg_dump` still exits 0 and the script logs `Backup written`. Nothing
validates that the dump is non-empty.

### Contributing defect — the healthcheck can't catch this and is itself broken
The healthcheck is `pgrep cron > /dev/null || exit 1`, but the
`pgvector/pgvector:pg16` image has no `procps`, so `pgrep` is *not found* and the
check fails every minute regardless of backup state (`FailingStreak` 121). Even
if it worked, "cron is alive" says nothing about whether dumps have content.

### Proposed fix (repo)
All three in version control so a rebuilt image is correct:

1. **Make cron see the DB env.** In the backup service `entrypoint`, dump the
   PG vars into the crontab before installing it, e.g.:
   ```sh
   printenv | grep -E '^PG(HOST|USER|PASSWORD|DATABASE)=' > /etc/cron.env
   { echo 'BASH_ENV=/etc/cron.env'; echo '0 2 * * * . /etc/cron.env; /backup.sh'; } | crontab -
   ```
   (or write `PGHOST=...` lines directly above the schedule line in the crontab).
2. **Fail loudly on an empty/failed dump** in `deploy/scripts/backup.sh`:
   `set -eo pipefail`; dump to a temp file, check `pg_dump` exit and that the
   gunzipped size is greater than a sane floor (e.g. > 1 KB) before renaming into
   place; otherwise exit non-zero and leave the previous good backup untouched.
3. **Fix the healthcheck** — install `procps` in the image, or (better) replace
   the liveness check with a *freshness* check: fail if the newest
   `/backups/landfall_*.sql.gz` is older than ~26 h or smaller than the floor.
   This catches both a dead cron and silent empty dumps.

### Immediate one-time remediation (safe to run any time)
A correct backup already exists from the manual run during investigation:
`/backups/landfall_20260620_233319.sql.gz` (345 KB). To take a fresh known-good
dump on demand:
```
ssh landfall@192.168.1.129 'docker exec deploy-backup-1 /backup.sh'
```
(works because exec inherits the env). Pull one off-box for safety:
```
docker cp deploy-backup-1:/backups/<file>.sql.gz ./   # then scp to the Mac
```

---

## Issue 2 — Display log grew to 301 MB (minor, largely self-resolved)

### Symptom
`~/.landfall-display.log` was 301 MB / 21 M lines. ~99% of lines were the bare
string `export failed` (≈50 K per 50 K-line sample).

### Root cause — GL spam from the BROKEN photo source (now fixed)
`export failed` is **not** in our code (no match across `*.dart/*.sh/*.py`). It
is emitted to stderr by the Mesa GL stack on the Pi's `vc4` driver when a dmabuf
export fails. The previous display instance was running the `serverpod` photo
source with **no photos**, so the slideshow rapid-cycled (`onError → advance` on
every frame), and each frame's failed GL export logged a line — pegging the log
at ~50 MB/day.

Pointing the slideshow at the working local directory (`~/Documents/Us`, see
the photo-source change in this session) **stopped the rapid-cycling and the
spam**: the live log grew 0 lines in 8 s afterward. The 301 MB is stranded
history from the broken instance.

### Contributing defect — truncation cadence is too coarse
`landfall-maintenance.sh` already truncates the log when it exceeds
`DISPLAY_LOG_MAX` (50 MB), and `landfall-maintenance.timer` is enabled — but it
is **weekly** (last run Jun 14, next Jun 21 03:42). At ~50 MB/day the log
reaches ~350 MB between runs. The weekly cap was sized for normal volume, not a
spam loop.

### Contributing defect — maintenance SQLite vacuum targets the wrong path
`landfall-maintenance.sh` defaults `SQLITE_DB` to
`/home/landfall/.local/share/landfall/landfall.db`, but the app's Drift DB is
actually at `/home/landfall/Documents/landfall.db` (path_provider returns
`~/Documents` for the GTK build). The vacuum step silently no-ops. Unrelated to
the log size but found during this investigation.

### Lower-rate residual noise
`[DisplayActionService] poll error: TimeoutException ... retrying in 0:00:05`
recurs every ~5 s (companion long-poll to `127.0.0.1:8080` timing out). ~17 K
lines/day — not log-critical, but worth a look as a companion-poll reliability
item. Also seen historically: `SocketException: ... Too many open files,
errno = 24` against port 8080 — the display fd soft limit is 1024 and the
long-running broken instance appears to have leaked sockets under the retry
loop (current healthy instance sits at ~58 fds, so not actively leaking).

### Proposed fix (repo)
1. **Primary is already done** — the photo-source fix removes the spam source.
2. **Filter the known-noise line out of the log sink** in
   `landfall-display-session.sh` so a future GL issue can't fill the disk:
   pipe the tee through a `grep --line-buffered -v -e 'export failed'` (and
   optionally rate-limit), keeping journald as the unfiltered record.
3. **Size-trigger the truncation** instead of relying only on the weekly timer:
   add a lightweight size check (e.g. via the watchdog loop or a more frequent
   timer) that truncates at the 50 MB cap.
4. **Fix the `SQLITE_DB` default** in `landfall-maintenance.sh` to
   `~/Documents/landfall.db` (or derive it).

### Immediate one-time remediation (safe now)
Reclaim the 301 MB without disturbing the running app (tee re-appends from 0):
```
ssh landfall@192.168.1.129 ': > ~/.landfall-display.log'
```

---

## Files referenced
- `deploy/docker-compose.prod.yml` — backup service env, entrypoint, healthcheck
- `deploy/scripts/backup.sh` — dump script (pipeline masks failure)
- `deploy/pi-gen/stage2-landfall/00-landfall/files/landfall-display-session.sh` — log sink (`tee -a`)
- `deploy/pi-gen/stage2-landfall/00-landfall/files/landfall-maintenance.sh` — log truncate + SQLite vacuum
- `deploy/pi-gen/stage2-landfall/00-landfall/files/landfall-maintenance.{service,timer}` — weekly schedule
