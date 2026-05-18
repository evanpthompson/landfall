# Updating a Landfall Pi

> **Beta default: build a new image and reflash.** During alpha/beta every
> code change on the maintainer side ships as a fresh `.img` — that's the
> path that's actually exercised and known to work. The two in-place
> procedures further down (server-only, display-only) exist for when you
> have a healthy running Pi and want to avoid a full reflash, but they are
> the **advanced/edge case**, not the default.
>
> Until OTA ships post-beta (see [`docs/roadmap.md`](roadmap.md)), every
> update is a manual procedure.

---

## What survives every update

The Pi's persistent state lives in **Docker named volumes**, which the image
itself never touches:

| Volume | Contains |
|---|---|
| `landfall_postgres_data` | All user state — profiles, layouts, linked accounts, cards, themes |
| `landfall_redis_data` | OTP rate-limit counters, ephemeral caches |
| `landfall_caddy_data` | TLS certificates from Let's Encrypt |
| `landfall_caddy_config` | Caddy's auto-generated runtime config |

`/home/landfall/landfall/deploy/.env` holds the per-device secrets generated
by `landfall-firstboot.service`. **Do not delete it** — that would invalidate
every encrypted OAuth token and force every linked account to reconnect.

What does *not* survive a fresh image flash:

- Anything you put outside `/home/landfall` (custom scripts, manual installs)
- The display app's local SQLite cache (settings re-sync from server)

---

## The default path: build a new image, reflash, restore data

This is what every beta update looks like. Plan ~2 hours: roughly 1 hour for
the build on the dev host, ~5 minutes to flash, ~5 minutes to back up + restore
data. The Pi is offline only for the flash + first boot (≈ 5 minutes).

### Step 1 — Back up the Pi's data

If this is the **first ever** image (no prior data on the device), skip this
step entirely.

```bash
ssh landfall@<pi-hostname>.local

cd ~/landfall/deploy
sudo systemctl stop landfall-server   # quiesce Postgres

# Tar the named volumes. Path is /var/lib/docker/volumes/.
sudo tar -C /var/lib/docker/volumes -czf ~/landfall-data-backup-$(date +%Y%m%d).tgz \
  landfall_postgres_data \
  landfall_redis_data \
  landfall_caddy_data \
  landfall_caddy_config

# Save .env separately — without it the per-device secrets that decrypt
# OAuth tokens are gone.
sudo cp ~/landfall/deploy/.env ~/landfall-env-backup-$(date +%Y%m%d).env

exit
# Pull both off the Pi
scp landfall@<pi-hostname>.local:~/landfall-data-backup-*.tgz   ./
scp landfall@<pi-hostname>.local:~/landfall-env-backup-*.env    ./
```

### Step 2 — Build the new image

On the dev host. If your `passwords.yaml` already has the Pi-specific fields
(`sshAuthorizedKey`, `staticIpCidr`, etc. — see
[`docs/debugging_pi.md`](debugging_pi.md)), the build is one command:

```bash
PI_HOSTNAME=<your-pi-hostname> \
PI_TIMEZONE=<your-tz> \
WIFI_SSID='<ssid>' \
WIFI_PASSWORD='<pass>' \
  bash deploy/pi-gen/configure.sh \
    --from-yaml server/landfall_server/config/passwords.yaml

bash deploy/pi-gen/build.sh
```

Output: `deploy/pi-gen/work/pi-gen/deploy/<date>-landfall.img`

### Step 3 — Flash

Raspberry Pi Imager → **Use custom** → select the `.img`. When asked about
customisation settings, choose **No, clear settings** — our image bakes
everything in via `configure.sh` and Pi Imager would overwrite the
SSH/user/WiFi/hostname fields.

### Step 4 — Restore data on first boot

The new image's `landfall-firstboot.service` will normally generate fresh
secrets and write a new `.env`. To preserve your data, you have to interrupt
firstboot mid-flight and restore both `.env` and the volumes:

```bash
# As soon as SSH is responsive (within ~30s of power-on):
ssh landfall@<pi-hostname>.local

# Stop firstboot — it's idempotent, safe to interrupt.
sudo systemctl stop landfall-firstboot

# Restore .env
scp <your-laptop>:~/landfall-env-backup-*.env /tmp/old.env
sudo cp /tmp/old.env ~/landfall/deploy/.env
sudo chown landfall:landfall ~/landfall/deploy/.env
sudo chmod 640 ~/landfall/deploy/.env

# Mark firstboot complete so it never reruns
sudo touch /var/lib/landfall/.initialized

# Restore data volumes. Docker must NOT be running during this step.
sudo systemctl stop docker
scp <your-laptop>:~/landfall-data-backup-*.tgz /tmp/
sudo rm -rf /var/lib/docker/volumes/landfall_*_data \
            /var/lib/docker/volumes/landfall_caddy_*
sudo tar -xzf /tmp/landfall-data-backup-*.tgz -C /var/lib/docker/volumes/

# Bring the stack back up
sudo systemctl start docker
sudo systemctl start landfall-server
```

### Step 5 — Verify

```bash
landfall-doctor   # should be all-green
```

If anything's red, `landfall-bug-report` produces the bundle a maintainer
needs to diagnose remotely.

> **First-ever image** (no prior data): skip steps 1 and 4 entirely. Let
> firstboot run to completion — it generates fresh secrets, writes `.env`,
> and brings up the stack. `landfall-doctor` should be green within ~3 min
> of power-on.

---

## In-place server-only update (fast path)

> **When to use this instead of a full reflash:** you have a healthy running
> Pi, the only thing that changed is the Landfall server (no kernel/system
> updates, no display binary changes), and you want to save the reflash
> time.
>
> If anything else changed, **don't use this path** — reflash.

The fast path is automated by `deploy/scripts/push-server.sh`. One command
rebuilds the arm64 image, copies it to the Pi, loads it into Docker, and
restarts the server service. Postgres, Redis, and Caddy stay up. The display
reconnects within ~5 seconds once the server is back.

### Configure the Pi target once

Pick one of these:

- Export `LANDFALL_PI_IP` in your shell (good for one-off pushes):
  ```bash
  export LANDFALL_PI_IP=192.168.1.130
  ```
- Or add it to `deploy/.env` (persists across sessions):
  ```
  LANDFALL_PI_IP=192.168.1.130
  ```
- Or pass it as the first argument every time.

If your Pi user is not `landfall` or the deploy path differs, override:

```bash
export LANDFALL_PI_USER=ethompson
export LANDFALL_PI_DEPLOY_PATH=/opt/landfall/deploy
```

### Push

```bash
bash deploy/scripts/push-server.sh
```

Preview without executing anything:

```bash
bash deploy/scripts/push-server.sh --dry-run
```

### What the script does

1. `docker buildx build --platform linux/arm64 -t landfall-server:latest server/landfall_server` — arm64 build (required; an amd64 binary loads but fails at runtime with `exec format error`).
2. `docker save landfall-server:latest | gzip > /tmp/landfall-server-<ts>.tar.gz`
3. `scp` to `landfall@<pi>:/tmp/landfall-server.tar.gz`
4. Over SSH on the Pi: `gunzip -c ... | docker load`, then `docker compose -f docker-compose.prod.yml up -d --no-deps server`, then remove the staging tarball.
5. Local cleanup of the dev-host tarball.

### Verify

```bash
ssh landfall@<pi-hostname>.local landfall-doctor
```

All-green within ~10 seconds of the script completing means the new server
binary is running and accepting traffic. If anything's red,
`landfall-bug-report` produces the diagnostic bundle.

### When to fall back to a full reflash

Use the default reflash path (above) when:

- Anything outside `server/landfall_server/` changed (display binary, Caddyfile, systemd units, openbox autostart, anything in `deploy/pi-gen/`)
- The Pi kernel or base OS needs an update
- `landfall-doctor` reports red on something unrelated to the server itself

---

## Advanced: in-place display-only update (edge case)

> **When to use this instead of a full reflash:** you have a healthy running
> Pi, the only thing that changed is the Flutter display binary (no server
> changes, no kernel changes), and the Pi's Linux GL stack is known to be
> working with the new binary. Skip otherwise — reflash.

```bash
# On the dev host
bash tools/scripts/build_linux.sh --arch arm64

scp -r apps/display/build/linux/arm64/release/bundle/* \
       landfall@<pi-hostname>.local:/home/landfall/landfall/display/

# On the Pi: lightdm relaunches the binary automatically
ssh landfall@<pi-hostname>.local
sudo systemctl restart lightdm
landfall-doctor
```

---

## Sanity checks before any update

```bash
ssh landfall@<pi-hostname>.local
landfall-doctor
docker compose -f ~/landfall/deploy/docker-compose.prod.yml images
```

If `landfall-doctor` is red, fix the existing state first. Never roll out
an update on top of a broken system — you lose the ability to tell which
problem the update caused versus which was pre-existing.

---

## Future: OTA updates (post-beta)

Automatic over-the-air updates are deferred until after beta because they
introduce real failure modes that need their own design work — signing-key
custody, A/B partitioning, rollback policy, release infrastructure. See
[`docs/roadmap.md`](roadmap.md) for current scope.

`landfall-update` on the Pi is a placeholder that prints a pointer to this
doc rather than failing with "command not found." When OTA lands, that
script will be replaced with the real orchestrator.

---

## For AI assistants

Key facts for helping users update a Landfall Pi:

- **Default update path is reflash.** Every beta release ships as a new `.img`. The in-place server-only and display-only paths are edge cases for when you have a healthy Pi and want to skip the reflash.
- **Data that survives a reflash** lives in Docker named volumes: `landfall_postgres_data`, `landfall_redis_data`, `landfall_caddy_data`, `landfall_caddy_config`. These are on the SD card outside the image partition and are never touched by a flash.
- **`deploy/.env` does not survive a reflash** by default — it's on the rootfs. Back it up before flashing and restore it within the first 30 seconds of first boot (before `landfall-firstboot.service` generates new secrets). Instructions are in the "Restore data on first boot" step above.
- **In-place server push:** `bash deploy/scripts/push-server.sh`. Requires `LANDFALL_PI_IP` set. Builds an arm64 image, scps it to the Pi, loads and restarts the server service. Other services (Postgres, Redis, Caddy) stay up.
- **Never update over a broken state.** Run `landfall-doctor` before any update. If it's red, diagnose and fix first — you can't tell which problems the update caused vs. which were pre-existing.
- **Volume backup command** is in Step 1 above — `sudo tar -C /var/lib/docker/volumes -czf ...`. It requires quiescing Postgres first (`sudo systemctl stop landfall-server`).
