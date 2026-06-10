# Self-Hosting Guide

Landfall runs entirely on your own hardware. Nothing leaves your network unless you explicitly connect an external API such as weather, Google Calendar, or Microsoft Calendar. This Docker server plus Fire TV/Android display path is the recommended setup for beta.

---

## What you need

- A machine to run the server: Raspberry Pi 4 (4 GB+), an old PC, a VPS, or anything that runs Linux and Docker
- A display: Fire TV Stick, Raspberry Pi with HDMI, or any Android device
- Docker and Docker Compose installed on the server machine

If you want a single-device setup (one Pi running both the server and the display), see the [Raspberry Pi Guide](raspberry_pi_guide.md) — a pre-built image handles everything.

---

## 1. Install Docker

On the server machine:

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Log out and back in, then verify:
docker run hello-world
```

---

## 2. Clone the repo

```bash
git clone https://github.com/evanpthompson/landfall.git
cd landfall
```


---

## 3. Run setup

```bash
bash deploy/scripts/setup.sh
```

This script:
- Asks for your hostname or IP address
- Generates all required secrets (DB password, JWT keys, etc.)
- Writes a `deploy/.env` file ready for Docker Compose

---

## 4. Add optional integrations

Open `deploy/.env` in a text editor. The file has comments explaining each field.

**Email sign-in** — configure SMTP so Landfall can send one-time login codes:
```
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=your_smtp_password_or_api_key
SMTP_FROM_EMAIL=landfall@example.com
SMTP_FROM_NAME=Landfall
SMTP_SSL=false
SMTP_ALLOW_INSECURE=false
OTP_LOG_CODES=false
```

For local development only, set `OTP_LOG_CODES=true` to write OTP codes to server logs when SMTP is blank. Keep it `false` for production and Pi images.

**Weather** — free API key from [openweathermap.org/api](https://openweathermap.org/api):
```
OWM_API_KEY=your_key_here
```

**Google Calendar** — uses OAuth 2.0. The user signs in once via a browser; the server holds an encrypted refresh token to keep events in sync.

1. In Google Cloud Console (create a project first if you don't already have one), enable the **Google Calendar API** under "APIs & Services → Library". Without this step the OAuth consent will succeed but syncing returns permission errors.
2. Go to "APIs & Services → Credentials" → **Create credentials → OAuth client ID**. Application type: **Web application**.
3. Under "Authorised redirect URIs", add:
   ```
   https://<your-domain>/calendar/oauth/callback
   ```
   `<your-domain>` must be the `LANDFALL_DOMAIN` you set in `.env`. **Google rejects `.local` hostnames and bare IP addresses** — you need a real domain (or a public dynamic-DNS hostname). If you only have `.local` available, see [OAuth without a public domain](#oauth-without-a-public-domain) below.
4. Click Create. Copy the `Client ID` and `Client secret`.
5. Fill these in `.env`:
   ```
   GOOGLE_CLIENT_ID=<your client id>
   GOOGLE_CLIENT_SECRET=<your client secret>
   GOOGLE_REDIRECT_URI=https://<your-domain>/calendar/oauth/callback
   ```
6. After the server is running (next section), connect your account: sign in to the display, then open the OAuth start URL on any device:
   ```
   https://<your-domain>/calendar/oauth/start
   ```
   You'll be redirected to Google's consent screen. Sign in, grant access, and you'll land on a "Connected" confirmation page. The next calendar refresh job (within 15 minutes) pulls your events.

**Google Drive photos** — *recommended path is a service account*, not OAuth. Service accounts skip the browser-consent dance entirely and never expire, so photos keep syncing even after a Pi reflash.

1. In the same Google Cloud project, enable the **Google Drive API** under "APIs & Services → Library".
2. Go to "IAM & Admin → Service Accounts" → **Create service account**. Name it whatever you like (e.g. `landfall-photos`). Skip the optional role/grants steps.
3. Open the new service account, go to the **Keys** tab → **Add key → Create new key → JSON**. A `*.json` file downloads.
4. Open the JSON. Two values matter:
   - `client_email` — looks like `landfall-photos@your-project.iam.gserviceaccount.com`
   - `private_key` — the PEM-encoded private key
5. **Share your Drive photo folder with the service account email.** Right-click the folder in Drive → Share → paste the `client_email` → set to **Viewer** → Share. This is what gives the service account permission to read your photos.
6. Get the folder ID from the URL (the part after `/folders/`).
7. Fill these in `.env`:
   ```
   GOOGLE_DRIVE_FOLDER_ID=1AbCdEf...
   GOOGLE_SERVICE_ACCOUNT_EMAIL=landfall-photos@your-project.iam.gserviceaccount.com
   GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n"
   ```
   The private key must be on one line with literal `\n` between PEM lines, wrapped in double quotes. Copy-paste from the JSON's `private_key` field — that's already the right format.

*OAuth fallback* — if you'd rather use the same OAuth flow as Calendar, leave the two `GOOGLE_SERVICE_ACCOUNT_*` keys blank and just set `GOOGLE_DRIVE_FOLDER_ID`. The credential connected via the calendar OAuth start URL will also be used for Drive photos. This works but OAuth tokens can silently expire, no re-link UI exists yet, and the setup flow requires a browser. Use service accounts if you can.

**Microsoft Calendar** — register an app at [portal.azure.com](https://portal.azure.com), add the `Calendars.Read` delegated permission under "API permissions" and click **Grant admin consent** (without the consent grant the permission is registered but not active). Set the redirect URI to `https://<your-domain>/calendar/microsoft/oauth/callback`:
```
MICROSOFT_CLIENT_ID=...
MICROSOFT_CLIENT_SECRET=...
MICROSOFT_REDIRECT_URI=https://<your-domain>/calendar/microsoft/oauth/callback
```

---

## 5. Start the server

```bash
cd deploy
docker compose -f docker-compose.prod.yml up -d
```

First run builds the server image from source (~5–15 minutes depending on hardware). Subsequent starts are instant.

Each container has a healthcheck and `restart: unless-stopped`, so a single service crash recovers automatically. `docker compose ps` reports `healthy` or `unhealthy` per service:

```bash
docker compose -f docker-compose.prod.yml ps
curl http://localhost:8080/card/getCards -X POST -H 'Content-Type: application/json' -d '{}'
# Should return: []
```

If a service shows `unhealthy` for more than a minute after startup, inspect its logs (`docker compose logs <service>`) — startup grace periods are 30 s for the server and 90 s for the backup container; longer than that points at a real problem.

---

## 6. Connect a display

### Fire TV Stick

Build the APK on your development machine:
```bash
bash tools/scripts/build_apk.sh
```

Then follow the printed sideload instructions (`adb connect` -> `adb install`). See the [Fire TV guide](fire_tv_guide.md) for the full APK and sideload workflow.

### Raspberry Pi (separate display device)

The simplest path is the pre-built image — see the [Raspberry Pi Guide](raspberry_pi_guide.md). It handles the binary build, server image, WiFi, and auto-start in one command.

For a manual install on an existing Pi, see [Option B in the Raspberry Pi Guide](raspberry_pi_guide.md#option-b-manual-setup-on-existing-pi-os).

### Any Android device

Install via `adb install` the same APK used for Fire TV.

---

## 7. Open the display app

On first launch, the app will ask for your server address. Enter:
- `http://<SERVER_IP>:8080` for local network — replace `<SERVER_IP>` with the server machine's IP address (run `hostname -I` on it to find it)
- `https://<your-domain>` if you have a domain with SSL via Caddy

---

## 8. Connect calendar and photo accounts

Open the display, tap anywhere to reveal the gear icon (bottom-right), then tap it to open Settings → Accounts.

The Accounts tab shows copyable OAuth URLs. Open the URL on your phone or laptop — it takes you through the standard Google or Microsoft consent flow. The display updates automatically once you authorize.

---

## Backups

The `backup` container runs `pg_dump` at 2 AM daily and keeps the last 7 dumps in a Docker volume. To access them:

```bash
docker run --rm \
  -v landfall_backup_data:/backups \
  -v $(pwd):/out \
  alpine cp -r /backups /out/
```

---

## Updates

```bash
git pull
cd deploy
docker compose -f docker-compose.prod.yml build --no-cache
docker compose -f docker-compose.prod.yml up -d
```

Serverpod applies any new migrations automatically on startup.

---

## Health monitoring

The server exposes a health endpoint at `http://<server>:8081`. You can point a free [UptimeRobot](https://uptimerobot.com) monitor at it to get notified if the server goes down.

## Validation

Run the fast deployment checks before a Pi image build or release candidate:

```bash
bash deploy/tests/run_deploy_tests.sh
```

For the Pi image staging contract, run:

```bash
bash deploy/pi-gen/build.sh --stage-only
```

---

## Troubleshooting

**Server won't start:**
```bash
docker compose -f docker-compose.prod.yml logs server
```

**Sign-in email never arrives:**
Check the SMTP values in `deploy/.env`, then restart the server:
```bash
docker compose -f docker-compose.prod.yml restart server
docker compose -f docker-compose.prod.yml logs server
```

**Database connection errors:**
Ensure `DB_HOST=postgres` in your `.env` — the Postgres container is reachable at that hostname within the Docker network.

**Calendar not syncing:**
Check that your OAuth redirect URI in the `.env` exactly matches what you registered in the Google Cloud or Azure console, including the scheme (`https://` vs `http://`).

---

## OAuth without a public domain

Google rejects OAuth redirect URIs that point at `.local` hostnames or bare IP addresses. If your Pi is only reachable at `landfall.local` (the default) or `192.168.x.x`, the normal calendar connect flow won't work — you'll hit "redirect_uri_mismatch" or "Access blocked" before Google's consent screen even loads.

You have three options, ordered by recommendation:

### Option A — Use a real domain (recommended for permanent installs)

Get a domain you control (any TLD Google accepts — `.com`, `.net`, `.io`, `.dev`, etc.) and point an `A` record at your home IP. Forward HTTPS traffic from your router to the Pi. Caddy in the deploy stack will obtain a Let's Encrypt cert automatically when it sees the new `LANDFALL_DOMAIN`.

Set `LANDFALL_DOMAIN=your-domain.example` in `.env`, register `https://your-domain.example/calendar/oauth/callback` in the Google Cloud Console, restart, and connect normally.

### Option B — Tunnel a Google-resolvable domain, then connect from the companion (one-time, advanced)

You don't need a permanent public domain to *complete* OAuth — you only need one that Google can resolve during the consent redirect. Connecting itself is done from the companion app, which is already signed in and authorizes the flow with a short-lived, single-use ticket (no manual tokens, no bearer secrets in URLs).

1. Pick or generate a real, public-internet-resolvable domain. Even a free dynamic-DNS hostname works — the constraint is that Google can resolve it during the consent flow.

2. Register `https://<that-domain>/calendar/oauth/callback` in your Google Cloud Console OAuth client, and set the matching `googleOAuthRedirectUri` in your `.env`.

3. Point that domain at your Pi for the duration of the link:
   - On your phone: connect to the same WiFi; some routers let you add custom DNS entries.
   - Simpler: use a tunnelling tool (e.g. `ngrok`) that fronts the Pi's web server.

4. On your phone, open the companion at `/c/<displayId>` (scan the QR on the companion card), sign in, and open **Settings → Accounts → Connect Google Calendar**. The companion mints a short-lived ticket and opens the consent flow — no token to copy.

5. Complete the consent flow. Google redirects back to your domain → your Pi → the credential is stored.

There is no secret to clear afterwards: the link ticket is single-use and expires within minutes, and identity is always derived from the signed-in companion session (SEC-06), never from a value in the URL.

### Option C — Switch photos to a service account (skips OAuth entirely for Drive)

If the only thing you need from Google is Drive photos, you can avoid OAuth altogether: use a service account. See the [Google Drive photos](#4-add-optional-integrations) instructions above — the service account flow has no browser step, no redirect URI to register, and no `.local` constraint.

Calendar still needs OAuth (there's no service account flow for personal Calendar). If you want Calendar too, fall back to Option A or B.

---

## For AI assistants

Key facts for helping users set up or debug a self-hosted Landfall instance:

- **Stack:** Serverpod backend (Dart) + Postgres + Redis + Caddy, all in Docker Compose. Config at `deploy/.env`. Start: `docker compose -f deploy/docker-compose.prod.yml up -d` from the `deploy/` directory.
- **Health check:** `curl http://<server>:8081` or `docker compose ps` — each service has a healthcheck. `server` and `backup` have grace periods of 30s and 90s respectively.
- **OTP sign-in in dev:** set `OTP_LOG_CODES=true` in `.env` to write codes to the server log. Never set this in production.
- **Google Calendar OAuth** needs a real domain (not `.local` or a bare IP). The redirect URI must match exactly — scheme included. See the [OAuth without a public domain](#oauth-without-a-public-domain) section for the setup-token bootstrap path.
- **Google Drive photos:** service account is the recommended path. It has no browser step, no redirect URI to register, never expires, and works with `.local` hostnames. Set `GOOGLE_DRIVE_FOLDER_ID`, `GOOGLE_SERVICE_ACCOUNT_EMAIL`, and `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY` in `.env`.
- **API keys:** minted via `tools/scripts/mint_api_key.sh` or via the API endpoint using `API_KEY_MANAGEMENT_TOKEN`. The plaintext key is shown once at mint time — it cannot be recovered.
- **Logs:** `docker compose logs <service>` from the `deploy/` directory. Server logs go to stdout (captured by Docker).
- **`deploy/.env` is per-instance.** Never commit it — it holds JWT keys, DB password, OAuth encryption keys, and the API key HMAC secret. Losing it invalidates all encrypted OAuth tokens.
