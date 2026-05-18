# Building a Debug Pi Image

A **debug Pi image** is a build with the diagnostic safety nets fully on so a
maintainer can recover and inspect the device remotely. Compared to a normal
production image, it has:

1. **SSH access guaranteed** — your public key is baked in, optional password.
2. **Local-loopback telemetry on** — the Pi posts events to its **own** server
   (`http://127.0.0.1:8080/api/v1/telemetry/event`). No separate dev server,
   no API key, no minting.
3. **All Tier 1–3 self-healing** — identical to production.

That's it. The Pi is self-contained. You SSH in, run `landfall-doctor`, and
read the events from the Pi's own journal.

---

## What goes in `passwords.yaml`

Add these keys under the existing `production:` block. **Just these** — the
SSH key plus optional static IP. No telemetry endpoint, no API key. The
debug flag does the rest.

```yaml
production:
  # ...all your existing keys (database, jwtHmacSha512PrivateKey, etc.)...

  # ── SSH (required so a maintainer can recover the device) ─────────────────
  sshAuthorizedKey: 'PASTE_OUTPUT_OF_cat_~/.ssh/id_ed25519.pub_HERE'
  sshPassword: 'pick-something-or-leave-out'   # optional, key auth alone works

  # ── Static IP (optional but recommended for headless setups) ──────────────
  staticIpCidr: '192.168.1.129/24'
  staticGateway: '192.168.1.1'
  staticDns: '1.1.1.1,8.8.8.8'
  staticInterface: 'eth0'
```

Get your SSH public key with:

```bash
cat ~/.ssh/id_ed25519.pub   # or ~/.ssh/id_rsa.pub
```

> **No telemetry endpoint or API key in passwords.yaml.** They were required
> in an earlier design that posted telemetry to a separate dev server. With
> `LANDFALL_BUILD_TYPE=debug` (set on the command line below), the build
> wires telemetry to the Pi's own loopback interface and the server
> auth-bypasses loopback requests. The Pi is fully self-contained.

---

## Build the image

```bash
# From the repo root:
LANDFALL_BUILD_TYPE=debug \
PI_HOSTNAME=landfall-debug \
PI_TIMEZONE=America/Chicago \
WIFI_SSID='YourWiFi' \
WIFI_PASSWORD='YourPassword' \
WIFI_COUNTRY=US \
  bash deploy/pi-gen/configure.sh \
    --from-yaml server/landfall_server/config/passwords.yaml

bash deploy/pi-gen/build.sh
```

Drop the `WIFI_*` vars if you're using ethernet.

Takes 1–2 hours. Output:

```
deploy/pi-gen/work/pi-gen/deploy/<date>-landfall.img
```

You should see `Debug build: telemetry will post to local loopback (no API
key required)` early in the build output — that confirms the flag took
effect.

---

## Flash

Raspberry Pi Imager → **Use custom** → select the `.img` → choose your SD card.

When asked about customization settings, choose **"No, clear settings."**
Our image bakes everything in via `configure.sh`. Pi Imager's fields would
overwrite SSH/user/WiFi/hostname and break authentication.

---

## After first boot (~2 minutes)

```bash
ssh landfall@192.168.1.129       # or landfall-debug.local
landfall-doctor                  # should be all-green

# Telemetry events land in the Pi's own journal:
journalctl -t landfall-server -b | grep LANDFALL_TELEMETRY
```

If anything's wrong:

```bash
landfall-bug-report
exit
scp landfall@192.168.1.129:landfall-bug-report-*.tgz .
```

That `.tgz` has the redacted `.env`, every relevant journal tail, compose
state, per-service logs, network/disk state, package versions, and a full
`landfall-doctor` snapshot. One file, everything needed to diagnose.

---

## Production vs debug comparison

|  | Production | Debug |
|---|---|---|
| `LANDFALL_BUILD_TYPE` | `production` (default) | `debug` |
| SSH key required | optional | **required** |
| Static IP | optional | recommended |
| Telemetry endpoint | empty | `http://127.0.0.1:8080/api/v1/telemetry/event` |
| Telemetry API key | n/a | **none — loopback auth-bypass** |
| `app_launched` events on every display launch | no | yes |
| `display_crash_loop` events after fast-crash threshold | no | yes |
| `landfall-doctor`, `landfall-bug-report` | yes | yes |
| Self-healing (`landfall-repair.timer`, watchdog, maintenance) | yes | yes |
| On-screen diagnostic on crash-loop | yes | yes |
| Display binary | release | release |

The display binary is functionally identical — only the build-time telemetry
endpoint differs. Everything else is operator-side affordances.

---

## Advanced: fleet telemetry to a remote aggregator

The default loopback model gives one Pi a way to phone home **to itself**,
which is what you want for one-off debugging. If you're running a fleet of
Pis and want them all posting to a central aggregator (for trend analysis,
crash sampling, etc.), set the endpoint explicitly:

```yaml
production:
  landfallTelemetryEndpoint: 'http://your-aggregator.local:8080/api/v1/telemetry/event'
  landfallTelemetryApiKey: 'lf_xxxx'   # mint once via tools/scripts/mint_api_key.sh
```

For this path you do need the API key (the aggregator isn't on the Pi's
loopback). See `tools/scripts/mint_api_key.sh`. Fleet aggregation is
otherwise undocumented post-beta work — see [`docs/roadmap.md`](roadmap.md).

---

## For AI assistants

Key facts for helping users build and use a debug Pi image:

- **Debug vs production:** the only differences are (1) SSH key baked in (required for debug), (2) telemetry wired to `http://127.0.0.1:8080/api/v1/telemetry/event` instead of empty. All self-healing services, display binary, and server behavior are identical to production.
- **`LANDFALL_BUILD_TYPE=debug`** is a command-line env var passed to `configure.sh`, not a key in `passwords.yaml`.
- **No telemetry API key needed** for the loopback path — the server auth-bypasses requests from `127.0.0.1`. API keys are only needed for fleet aggregators on non-loopback addresses.
- **Read telemetry events:** `journalctl -t landfall-server -b | grep LANDFALL_TELEMETRY` on the Pi.
- **`landfall-bug-report`** produces a `.tgz` with redacted `.env`, journal tails, compose state, network/disk state, and a full `landfall-doctor` snapshot. That's everything needed to diagnose remotely. Collect it with `scp landfall@<pi>:landfall-bug-report-*.tgz .`.
- **Static IP** in `passwords.yaml` under `staticIpCidr`/`staticGateway`/`staticDns`/`staticInterface`. Recommended for debug images so the Pi is always at a known address.
- **Build is from repo root** using `configure.sh --from-yaml` then `build.sh`. The `cd` in the example above is just to orient you — the scripts are self-locating from the repo root.
