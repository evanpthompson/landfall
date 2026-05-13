# Building a Maximally Debuggable Pi Image

This doc is the **fastest path to a Pi image that gives a maintainer all the
information needed to diagnose a problem remotely.** Use it when:

- The previous Pi image had an unexplained failure (display didn't start,
  crash-looping, something else weird)
- You want every diagnostic safety net turned on so the next failure tells
  us why instead of leaving us guessing

The image you produce here has **two differences** from a normal production
image:

1. **SSH access is guaranteed** — public key baked in, optional password.
2. **Dev-build telemetry is enabled** — the Pi posts structured events to
   a Landfall server you also control, so failures phone home automatically.

Everything else (Tier 1–3 self-healing) is identical to a production image.

---

## Pre-flight checklist

Before running `configure.sh`, gather:

- [ ] **Your SSH public key.** Default: `~/.ssh/id_ed25519.pub` or `~/.ssh/id_rsa.pub`.
      If you don't have one, generate now: `ssh-keygen -t ed25519 -C "you@host"`.
- [ ] **A reachable Landfall server with an API key.** This is where telemetry
      posts will land. Easiest option: your existing dev macOS instance
      (`bash tools/scripts/start_mac.sh --server`) plus an API key.

      Mint a key once and reuse it across every debug image:

      ```bash
      bash tools/scripts/start_mac.sh --server    # in one terminal
      bash tools/scripts/mint_api_key.sh --name pi-debug   # in another
      ```

      Copy the printed `plainTextKey` into `passwords.yaml` as
      `landfallTelemetryApiKey` (under the `production:` block). **That file
      is the persistent home for the key** — it's gitignored, it lives in
      your repo on disk, and `--from-yaml` will pick it up on every
      subsequent `configure.sh` run. You never need to mint it again unless
      you deliberately wipe the dev server's Postgres volume (which would
      also invalidate the hash on the server side and break the old key).
- [ ] **The Pi's intended LAN address** (static IP), or accept whatever DHCP
      hands out — a static IP just makes "SSH to this specific Pi" deterministic.
- [ ] **A WiFi SSID + password** if not using ethernet.

Optional:

- [ ] Timezone (e.g. `America/Chicago`) — without this, the clock card shows
      UTC until you SSH in to fix it.
- [ ] OpenWeatherMap key + coordinates if you want weather cards on first boot.

---

## Build the image

### Path A — interactive

```bash
bash deploy/pi-gen/configure.sh
```

When the wizard asks for **SSH public key**, accept the default path (your
key auto-loads). Set a password too if you want belt-and-suspenders.

When it asks for **Static IP**, enter your chosen address (e.g.
`192.168.1.129/24`), gateway, and DNS.

When the wizard finishes, **manually add the telemetry settings** to the
output file (the wizard doesn't prompt for them — they're advanced-mode
only). Open `deploy/pi-gen/landfall-build.conf` and set:

```ini
LANDFALL_TELEMETRY_ENDPOINT='http://<your-dev-server>:8080/api/v1/telemetry/event'
LANDFALL_TELEMETRY_API_KEY='lf_xxxxxxxxxxxxxxxx'
```

Then build:

```bash
bash deploy/pi-gen/build.sh
```

### Path B — fully scripted (recommended for repeat debug images)

Create a `debug-pi.conf` once, reuse forever:

```ini
WIFI_COUNTRY=US
WIFI_SSID=YourWiFi
WIFI_PASSWORD='your-wifi-password'
PI_HOSTNAME=landfall-debug
PI_TIMEZONE=America/Chicago

SSH_AUTHORIZED_KEY='ssh-ed25519 AAAA... you@host'
SSH_PASSWORD='strong-password-you-actually-want'

STATIC_IP_CIDR=192.168.1.129/24
STATIC_GATEWAY=192.168.1.1
STATIC_DNS=1.1.1.1,8.8.8.8
STATIC_INTERFACE=eth0

# DEV ONLY — never set these on a production image
LANDFALL_TELEMETRY_ENDPOINT='http://192.168.1.42:8080/api/v1/telemetry/event'
LANDFALL_TELEMETRY_API_KEY='lf_xxxxxxxxxxxxxxxx'

# Optional integrations
OWM_API_KEY=''
WEATHER_LATITUDE=''
WEATHER_LONGITUDE=''
WEATHER_LOCATION_NAME=''
GOOGLE_CLIENT_ID=''
GOOGLE_CLIENT_SECRET=''
GOOGLE_DRIVE_FOLDER_ID=''
MICROSOFT_CLIENT_ID=''
MICROSOFT_CLIENT_SECRET=''

# Email — leave blank if not testing OTP sign-in this round
SMTP_HOST=''
SMTP_PORT=587
SMTP_USERNAME=''
SMTP_PASSWORD=''
SMTP_FROM_EMAIL=''
SMTP_FROM_NAME=Landfall
SMTP_SSL=false
SMTP_ALLOW_INSECURE=false
```

Then:

```bash
bash deploy/pi-gen/configure.sh --from-env debug-pi.conf
bash deploy/pi-gen/build.sh
```

If you already have a `passwords.yaml` for your dev server, the credentials
are pulled in automatically; only the Pi-specific fields need to be set as
environment overrides:

```bash
PI_HOSTNAME=landfall-debug \
PI_TIMEZONE=America/Chicago \
STATIC_IP_CIDR=192.168.1.129/24 \
STATIC_GATEWAY=192.168.1.1 \
SSH_AUTHORIZED_KEY="$(cat ~/.ssh/id_ed25519.pub)" \
LANDFALL_TELEMETRY_ENDPOINT='http://192.168.1.42:8080/api/v1/telemetry/event' \
LANDFALL_TELEMETRY_API_KEY='lf_xxxx' \
  bash deploy/pi-gen/configure.sh \
    --from-yaml server/landfall_server/config/passwords.yaml
bash deploy/pi-gen/build.sh
```

---

## Flash

Use Raspberry Pi Imager → **Use custom** → select the `.img` produced under
`deploy/pi-gen/work/pi-gen/deploy/`.

> **Critical:** when Pi Imager asks "would you like to apply OS customisation
> settings?", choose **No (clear)**. Our image bakes in everything via
> `configure.sh`. Pi Imager's settings (hostname, WiFi, user, SSH) would
> overwrite the wrong things and break SSH authentication.

Insert the SD card, power on the Pi.

---

## Verify everything is wired

First boot takes ~2 minutes for the kiosk to render the splash + start the
server stack. As soon as the network is up:

```bash
# 1. SSH should work without a password prompt (key auth)
ssh landfall@<static-ip-or-hostname.local>

# 2. Doctor should be all-green (or near it)
landfall-doctor

# 3. Telemetry should already have posted an `app_launched` event.
#    Verify by tailing the journal on your dev server:
ssh dev-server 'journalctl -t landfall-server -f | grep LANDFALL_TELEMETRY'
```

If `landfall-doctor` reports any failures: that's the actual problem to
debug. Run:

```bash
landfall-bug-report
# wait for the bundle to finish, then pull it off:
exit
scp landfall@<pi>:landfall-bug-report-*.tgz .
```

Send the resulting `.tgz` to a maintainer (or attach to a GitHub issue).
That single file has everything we need to diagnose: redacted .env, journal
tails for every relevant unit, docker compose state and per-service logs,
network state, disk, package versions, openbox autostart, lightdm config,
and the full `landfall-doctor` output as a snapshot.

---

## What to expect

With the maximally-debuggable image, here's the full picture of what you
get vs. a production image:

|  | Production image | This debug image |
|---|---|---|
| SSH key auth | optional | **required** (you set it) |
| SSH password | optional | optional |
| Static IP | optional | **enabled** |
| Telemetry endpoint baked in `.env` | blank | **set to your dev server** |
| `app_launched` event on every display launch | no | **yes** |
| `display_crash_loop` event after 3 fast crashes | no | **yes** |
| `landfall-doctor`, `landfall-bug-report` | yes | yes |
| Self-healing (`landfall-repair.timer`, watchdog, maintenance) | yes | yes |
| On-screen diagnostic on crash-loop | yes | yes |
| Display app binary | release | release |

The binary is identical to production. The only differences are the
operator-side affordances (SSH, telemetry endpoint, static IP) that let
us figure out what went wrong.

---

## Future: this will get easier

Today telemetry-enabled images and SSH-key images still require you to fill
in a config file. Future work (see [`docs/roadmap.md`](roadmap.md)):

- **Crash bundle auto-ship** — when a fast-crash trips telemetry, the Pi
  will also auto-POST the bundle so you don't have to SCP it manually.
- **Health admin card** — a card on the display itself that shows what
  `landfall-doctor` currently reports, for non-SSH operators.
- **OTA updates** — once shipping, debug images won't need to be re-flashed
  for every issue.
