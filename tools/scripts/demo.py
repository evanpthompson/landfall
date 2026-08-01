#!/usr/bin/env python3
"""
Landfall interactive demo launcher (Python version).
Starts the full stack, generates an API key, pushes demo cards, and
launches the display with verbose persistent logging.
"""

import os
import sys
import subprocess
import time
import json
import logging
import signal
import shutil
import re
from datetime import datetime
from pathlib import Path
from typing import Optional, List, Dict, Any
from urllib import request, error

# ── Configuration & Paths ──────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).parent.resolve()
REPO_ROOT = SCRIPT_DIR.parent.parent
SERVER_DIR = REPO_ROOT / "server" / "landfall_server"
DISPLAY_DIR = REPO_ROOT / "apps/display"
PASSWORDS_YAML = SERVER_DIR / "config" / "passwords.yaml"
SERVER_URL = "http://localhost:8080"

# Logs
LOG_DIR = REPO_ROOT / "logs"
LOG_DIR.mkdir(exist_ok=True)
DEMO_LOG = LOG_DIR / f"demo_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
SERVER_LOG = LOG_DIR / "server_output.log"

# ── Colours ────────────────────────────────────────────────────────────────
class Colours:
    BOLD = '\033[1m'
    DIM = '\033[2m'
    CYAN = '\033[1;36m'
    GREEN = '\033[1;32m'
    YELLOW = '\033[1;33m'
    RED = '\033[1;31m'
    RESET = '\033[0m'

# ── Logging Setup ─────────────────────────────────────────────────────────
class CustomFormatter(logging.Formatter):
    """Logging Formatter to add colors and count warning / errors"""

    def format(self, record):
        log_fmt = "%(asctime)s - %(levelname)s - %(message)s"
        if record.levelno == logging.INFO:
            if hasattr(record, 'is_step') and record.is_step:
                record.msg = f"{Colours.CYAN}▶  {record.msg}{Colours.RESET}"
            elif hasattr(record, 'is_ok') and record.is_ok:
                record.msg = f"{Colours.GREEN}✓  {record.msg}{Colours.RESET}"
            elif hasattr(record, 'is_info') and record.is_info:
                record.msg = f"{Colours.DIM}   {record.msg}{Colours.RESET}"
        elif record.levelno == logging.WARNING:
            record.msg = f"{Colours.YELLOW}⚠  {record.msg}{Colours.RESET}"
        elif record.levelno == logging.ERROR:
            record.msg = f"{Colours.RED}✗  {record.msg}{Colours.RESET}"

        return super().format(record)

def setup_logging():
    # File logger (detailed)
    file_handler = logging.FileHandler(DEMO_LOG)
    file_handler.setLevel(logging.DEBUG)
    file_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    file_handler.setFormatter(file_formatter)

    # Console logger (formatted)
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.INFO)
    # Simple formatter for console, we'll add colors in the methods
    console_formatter = logging.Formatter('%(message)s')
    console_handler.setFormatter(console_formatter)

    root = logging.getLogger()
    root.setLevel(logging.DEBUG)
    root.addHandler(file_handler)
    root.addHandler(console_handler)

logger = logging.getLogger("LandfallDemo")

# ── Helper Methods ────────────────────────────────────────────────────────
def step(msg: str):
    logger.info(f"{Colours.CYAN}▶  {msg}{Colours.RESET}", extra={"is_step": True})

def ok(msg: str):
    logger.info(f"{Colours.GREEN}✓  {msg}{Colours.RESET}", extra={"is_ok": True})

def info(msg: str):
    logger.info(f"{Colours.DIM}   {msg}{Colours.RESET}", extra={"is_info": True})

def warn(msg: str):
    logger.warning(msg)

def die(msg: str):
    logger.error(msg)
    sys.exit(1)

def pause(msg: str):
    print(f"\n{Colours.BOLD}{msg}{Colours.RESET}")
    input(f"   Press Enter to continue... ")

# ── Demo Class ─────────────────────────────────────────────────────────────
class LandfallDemo:
    def __init__(self):
        self.server_process: Optional[subprocess.Popen] = None
        self.api_key: Optional[str] = None
        self.management_token: Optional[str] = None
        self.weather_live = False
        self.google_oauth_ready = False

    def cleanup(self, signum=None, frame=None):
        print("\n")
        step("Shutting down...")

        if self.server_process:
            logger.debug(f"Terminating server process {self.server_process.pid}")
            self.server_process.terminate()
            try:
                self.server_process.wait(timeout=5)
                ok("Server stopped")
            except subprocess.TimeoutExpired:
                self.server_process.kill()
                ok("Server killed after timeout")

        try:
            logger.debug("Stopping Docker services")
            subprocess.run(
                ["docker", "compose", "down", "--remove-orphans", "-q"],
                cwd=SERVER_DIR,
                capture_output=True,
                check=False
            )
            ok("Docker services stopped")
        except Exception as e:
            logger.debug(f"Error stopping docker: {e}")

        print(f"\n{Colours.CYAN}{Colours.BOLD}Demo complete. Thanks for watching!{Colours.RESET}\n")
        if signum:
            sys.exit(0)

    def _read_yaml_key(self, section: str, key: str) -> Optional[str]:
        """Return the value of `key` inside `section:` in passwords.yaml, or None."""
        if not PASSWORDS_YAML.exists():
            return None
        lines = PASSWORDS_YAML.read_text().splitlines()
        in_section = False
        for line in lines:
            stripped = line.strip()
            if stripped == f"{section}:":
                in_section = True
                continue
            # Any non-indented, non-comment, colon-bearing line starts a new section
            if in_section and stripped and not stripped.startswith('#') \
                    and line[:1] not in (' ', '\t') and ':' in stripped:
                in_section = False
            if in_section and stripped.startswith(f"{key}:"):
                val = stripped[len(f"{key}:"):].strip().strip("'\"")
                return val if val else None
        return None

    def read_management_token(self) -> str:
        """Read apiKeyManagementToken from the development section of passwords.yaml."""
        token = self._read_yaml_key("development", "apiKeyManagementToken")
        if not token:
            die(
                "apiKeyManagementToken not found in passwords.yaml development section.\n"
                "   Copy config/passwords.yaml.example, set a value, and re-run."
            )
        placeholders = {"change-me-dev", "replace_with_strong_secret", "replace_me"}
        if token in placeholders:
            die(
                "apiKeyManagementToken is still set to the placeholder value.\n"
                "   Set it to a real secret in passwords.yaml development section."
            )
        return token

    def run_api_request(self, endpoint: str, data: Dict[str, Any]) -> Dict[str, Any]:
        url = f"{SERVER_URL}{endpoint}"
        logger.debug(f"API Request: {url} - Data: {json.dumps(data)}")
        req = request.Request(
            url,
            data=json.dumps(data).encode('utf-8'),
            headers={'Content-Type': 'application/json'},
            method='POST'
        )
        try:
            with request.urlopen(req) as response:
                body = response.read().decode('utf-8')
                logger.debug(f"API Response ({response.status}): {body}")
                return json.loads(body)
        except error.HTTPError as e:
            body = e.read().decode('utf-8')
            logger.error(f"API Error ({e.code}): {body}")
            raise
        except Exception as e:
            logger.error(f"Connection Error: {e}")
            raise

    def push_card(self, source: str, title: str, body: str = "", layout: str = "medium", priority: str = "normal"):
        inner = {
            "__className__": "CardPushRequest",
            "source": source,
            "title": title,
            "layout": layout,
            "priority": priority
        }
        if body:
            inner["body"] = body

        self.run_api_request("/card/pushCard", {"request": inner})

    def push_card_agent(self, source: str, title: str, body: str = "", layout: str = "medium", priority: str = "normal", external_id: str = ""):
        request_data = {
            "__className__": "CardPushRequest",
            "source": source,
            "title": title,
            "layout": layout,
            "priority": priority
        }
        if body:
            request_data["body"] = body
        if external_id:
            request_data["externalId"] = external_id

        self.run_api_request("/agent/pushCard", {
            "apiKey": self.api_key,
            "request": request_data
        })

    def update_card_agent(self, external_id: str, source: str, title: str, body: str = ""):
        request_data = {
            "__className__": "CardPushRequest",
            "source": source,
            "title": title
        }
        if body:
            request_data["body"] = body

        self.run_api_request("/agent/updateCard", {
            "apiKey": self.api_key,
            "externalId": external_id,
            "request": request_data
        })

    def dismiss_card_agent(self, external_id: str):
        self.run_api_request("/agent/dismissCard", {
            "apiKey": self.api_key,
            "externalId": external_id
        })

    def list_themes(self) -> List[Dict[str, Any]]:
        try:
            return self.run_api_request("/theme/listThemes", {})
        except Exception:
            return []

    def upload_theme(self, yaml: str) -> Dict[str, Any]:
        try:
            return self.run_api_request("/theme/uploadTheme", {"yaml": yaml})
        except Exception as e:
            return {"errors": [{"message": str(e)}]}

    def wait_for_server(self, timeout: int = 40):
        logger.debug(f"Waiting for server at {SERVER_URL} (timeout {timeout}s)")
        start_time = time.time()
        while time.time() - start_time < timeout:
            try:
                # Poll getCards until it returns 200
                req = request.Request(
                    f"{SERVER_URL}/card/getCards",
                    data=b'{}',
                    headers={'Content-Type': 'application/json'},
                    method='POST'
                )
                with request.urlopen(req, timeout=2) as response:
                    if response.status == 200:
                        return True
            except Exception:
                pass
            time.sleep(1)
        return False

    def seed_demo_calendar_data(self):
        sql = """
DELETE FROM calendar_events
  WHERE "credentialId" IN (
    SELECT id FROM calendar_linked_credentials WHERE "providerEmail" = 'demo@landfall.local'
  );
DELETE FROM calendar_linked_credentials WHERE "providerEmail" = 'demo@landfall.local';

INSERT INTO calendar_linked_credentials
  ("authUserId", provider, "providerEmail", "accessToken", "isActive", "createdAt", "updatedAt")
VALUES
  ('00000000-0000-0000-0000-000000000001', 'google', 'demo@landfall.local',
   'demo-access-token', true, now(), now());

WITH cred AS (SELECT id FROM calendar_linked_credentials WHERE "providerEmail" = 'demo@landfall.local')
INSERT INTO calendar_events
  ("credentialId", "calendarId", "calendarName", "externalEventId",
   title, "startTime", "endTime", "isAllDay", "fetchedAt")
SELECT c.id, 'primary',      'Work',     'demo-standup',  'Team standup',
       NOW() + interval '1 hour',         NOW() + interval '1 hour 30 minutes',  false, NOW() FROM cred c
UNION ALL
SELECT c.id, 'primary',      'Work',     'demo-1on1',     '1:1 with Sarah',
       NOW() + interval '3 hours',        NOW() + interval '4 hours',            false, NOW() FROM cred c
UNION ALL
SELECT c.id, 'personal_cal', 'Personal', 'demo-dentist',  'Dentist appointment',
       NOW() + interval '25 hours',       NOW() + interval '26 hours',           false, NOW() FROM cred c
UNION ALL
SELECT c.id, 'family_cal',   'Family',   'demo-soccer',   'Kids soccer game',
       NOW() + interval '27 hours',       NOW() + interval '28 hours 30 minutes', false, NOW() FROM cred c
UNION ALL
SELECT c.id, 'primary',      'Work',     'demo-planning', 'Q3 planning session',
       NOW() + interval '50 hours',       NOW() + interval '52 hours',           false, NOW() FROM cred c;
"""
        cmd = ["docker", "compose", "exec", "-T", "postgres", "psql", "-U", "postgres", "landfall", "-q"]
        logger.debug(f"Seeding calendar data with command: {' '.join(cmd)}")
        try:
            result = subprocess.run(cmd, input=sql.encode('utf-8'), cwd=SERVER_DIR, capture_output=True, check=True)
            logger.debug(f"SQL Output: {result.stdout.decode('utf-8')}")
            return True
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to seed calendar data: {e.stderr.decode('utf-8')}")
            return False

    def preflight(self):
        os.system('clear')
        print(f"\n{Colours.CYAN}{Colours.BOLD}")
        print("  ██╗      █████╗ ███╗   ██╗██████╗ ███████╗ █████╗ ██╗     ██╗")
        print("  ██║     ██╔══██╗████╗  ██║██╔══██╗██╔════╝██╔══██╗██║     ██║")
        print("  ██║     ███████║██╔██╗ ██║██║  ██║█████╗  ███████║██║     ██║")
        print("  ██║     ██╔══██║██║╚██╗██║██║  ██║██╔══╝  ██╔══██║██║     ██║")
        print("  ███████╗██║  ██║██║ ╚████║██████╔╝██║     ██║  ██║███████╗███████╗")
        print("  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝")
        print(f"{Colours.RESET}")
        print(f"  {Colours.DIM}The ambient display layer for the agentic era{Colours.RESET}\n")

        pause("Welcome to the Landfall demo. We'll start the server, generate an API key, push some live cards, and launch the display.")

        step("Checking prerequisites")
        prereqs = ["docker", "dart", "flutter", "curl", "lsof"]
        for p in prereqs:
            if not shutil.which(p):
                die(f"{p} is not installed or not in PATH")
        ok("All prerequisites found")

        step("Checking API key management token")
        if not PASSWORDS_YAML.exists():
            die(f"{PASSWORDS_YAML} not found. Copy config/passwords.yaml.example to get started.")
        self.management_token = self.read_management_token()
        ok(f"apiKeyManagementToken configured")

        step("Checking API key HMAC secret")
        hmac_secret = self._read_yaml_key("development", "apiKeyHmacSecret")
        placeholders = {"change-me-dev-hmac", "replace_with_strong_secret", "replace_me"}
        if not hmac_secret or hmac_secret in placeholders:
            die(
                "apiKeyHmacSecret is not set in passwords.yaml development section.\n"
                "   Add it (generate with: openssl rand -base64 32) and re-run."
            )
        ok("apiKeyHmacSecret configured")

        step("Checking weather configuration")
        if PASSWORDS_YAML.exists():
            content = PASSWORDS_YAML.read_text()
            if "your-owm-api-key-here" in content:
                warn("OpenWeatherMap API key is not configured.")
                info("The weather slot will show a placeholder tile during the demo.")
                info(f"To enable live weather: edit {PASSWORDS_YAML}")
                info("and set openWeatherMapApiKey to your key from openweathermap.org/api")
            else:
                self.weather_live = True
                ok("OpenWeatherMap API key is configured — weather widget will be live")
        else:
            warn(f"{PASSWORDS_YAML} not found. Weather will be placeholder.")

        step("Checking Google Calendar configuration")
        if PASSWORDS_YAML.exists():
            content = PASSWORDS_YAML.read_text()
            if "googleOAuthRedirectUri" in content and "your-redirect-uri" not in content:
                self.google_oauth_ready = True
                ok("Google OAuth credentials configured — live calendar connect available")
                info(f"Connect URL: {SERVER_URL}/calendar/oauth/start?authUserId=<your-uuid>")
            else:
                warn("googleOAuthRedirectUri not configured in passwords.yaml.")
                info("Demo will seed sample calendar events directly.")
        else:
            warn(f"{PASSWORDS_YAML} not found.")

    def run_demo(self):
        # Step 0: Clear stale server
        step("Checking for stale server on :8080")
        try:
            # lsof -ti :8080
            stale_pid_bytes = subprocess.check_output(["lsof", "-ti", ":8080"], stderr=subprocess.DEVNULL)
            stale_pids = stale_pid_bytes.decode('utf-8').split()
            for pid in stale_pids:
                logger.debug(f"Killing stale process {pid}")
                os.kill(int(pid), signal.SIGTERM)
            time.sleep(1)
            ok(f"Stopped stale server(s) on 8080")
        except subprocess.CalledProcessError:
            ok("Port 8080 is free")

        # Step 1: Docker
        step("Starting Postgres and Redis (Docker)")
        try:
            subprocess.run(["docker", "compose", "up", "-d", "--quiet-pull"], cwd=SERVER_DIR, check=True, capture_output=True)
            ok("Postgres listening on :8090  •  Redis on :8091")
        except subprocess.CalledProcessError as e:
            die(f"docker compose up failed: {e.stderr.decode('utf-8')}")

        time.sleep(2)

        # Step 2: Server
        step("Starting Landfall server")
        info(f"Logs → {SERVER_LOG}")
        server_log_file = open(SERVER_LOG, "w")
        self.server_process = subprocess.Popen(
            ["dart", "bin/main.dart", "--apply-migrations"],
            cwd=SERVER_DIR,
            stdout=server_log_file,
            stderr=subprocess.STDOUT
        )

        info("Waiting for server to accept connections...")
        if self.wait_for_server():
            ok(f"Server is up at {SERVER_URL}")
        else:
            warn(f"Server did not respond in 40 s. Check {SERVER_LOG} for errors.")
            die("Aborting demo")

        # Step 3: API key
        pause("Server is running and migrations are applied. Now let's generate an API key.")

        step("Generating demo API key")
        try:
            resp = self.run_api_request("/apiKey/generateKey", {
                "name": "demo",
                "setupToken": self.management_token,
            })
            self.api_key = resp["plainTextKey"]
            ok(f"API key generated: {Colours.BOLD}{self.api_key}{Colours.RESET}")
            info("Key hash stored as HMAC-SHA-256 (A04) — not recoverable from the DB.")
            info("In production, agents store this key securely.")
        except Exception as e:
            die(f"Failed to generate API key: {e}")

        # Step 4: Demo cards
        pause("Key in hand. Now let's push some cards — these simulate live output from AI agents.")
        step("Pushing demo cards via authenticated agent API")

        cards = [
            ("agent.claude", "3 items before your 2 PM", "Reply to Sarah re: Q3 plan, review budget doc, confirm dinner reservation."),
            ("agent.home", "Front door unlocked for 9 min", "No motion detected inside. Lock remotely?", "medium", "ephemeral"),
            ("agent.flights", "Flight DEN→LAX dropped to $287", "Round trip, departing June 14. Sale ends tonight.")
        ]

        for i, card in enumerate(cards, 1):
            self.push_card_agent(*card)
            ok(f"Card {i} — {card[0]} (agent API)")

        self.push_card_agent("agent.research", "New paper: LLM reasoning benchmarks", "Three Stanford papers dropped overnight.")
        ok("Card 4 — agent.research (agent API)")

        # Step 5: Live card update
        pause("Demonstrating live card update (stable externalId).")
        step("Demonstrating live card update")
        build_id = "demo.build.status"
        self.push_card_agent("agent.ci", "Build running…", "CI pipeline started. 0/237 tests passing.", external_id=build_id)
        ok(f"Card pushed: 'Build running…' (externalId: {build_id})")

        info("Simulating CI job completion...")
        time.sleep(2)
        self.update_card_agent(build_id, "agent.ci", "Build passed ✓", "All 237 tests passed in 42 s.")
        ok("Card updated in-place: 'Build passed ✓'")

        # Step 6: Dismissal
        pause("Agents can also dismiss cards programmatically.")
        step("Demonstrating programmatic card dismissal")
        alert_id = "demo.alert.disk"
        self.push_card_agent("agent.monitor", "Disk at 89%", "macOS partition full.", layout="medium", priority="ephemeral", external_id=alert_id)
        ok(f"Alert card pushed (externalId: {alert_id})")

        info("Agent detects the situation is resolved...")
        time.sleep(1)
        self.dismiss_card_agent(alert_id)
        ok("Card dismissed")

        # Step 7: List
        step("Listing the current active board")
        resp = self.run_api_request("/agent/listCards", {"apiKey": self.api_key})
        for c in resp:
            print(f"   • [{c['source']}]  {c['title']}")
        ok(f"{len(resp)} active card(s) on the display")

        # Step 8: MCP info
        pause("All of the above — push, update, dismiss, list — is also available as MCP tools "
              "so AI agents with tool-use support (Claude Desktop, Cursor) can drive the display directly.")
        step("MCP server (landfall_mcp)")
        print(f"\n  {Colours.BOLD}Build the binary:{Colours.RESET}")
        print(f"  {Colours.DIM}dart compile exe server/landfall_mcp/bin/landfall_mcp.dart -o /usr/local/bin/landfall_mcp{Colours.RESET}")
        print(f"\n  {Colours.BOLD}Add to Claude Desktop{Colours.RESET} (~/.config/claude/claude_desktop_config.json):")
        print(f'  {Colours.DIM}{{"mcpServers": {{"landfall": {{"command": "/usr/local/bin/landfall_mcp",')
        print(f'    "env": {{"LANDFALL_URL": "{SERVER_URL}", "LANDFALL_API_KEY": "{self.api_key}"}}}}}}}}{Colours.RESET}')
        print()
        info("Once connected, Claude can call push_card, update_card, list_cards, dismiss_card,")
        info("and push_ticker as native tools.")
        print()

        # Step 9: Weather
        pause("Landfall includes a built-in weather widget — no agent required.")
        step("Weather widget")
        print()
        print(f"  {Colours.BOLD}Two automatic cards:{Colours.RESET}")
        info("• Current conditions  — temperature, description, feels-like, humidity")
        info("• 5-day forecast strip — high/low and icon for each day")
        print()
        info(f"Refresh cadence: every 10 minutes, server-side")
        info("Data source:     OpenWeatherMap (free tier, 60 calls/min)")
        print()
        if self.weather_live:
            ok("Live weather will appear in the display automatically.")
        else:
            warn("OWM key not set — weather cards will show a placeholder.")
            info(f"Set openWeatherMapApiKey in {PASSWORDS_YAML} to enable live data.")

        # Step 10: Calendar
        pause("Landfall also has a built-in calendar widget. It aggregates events from multiple feeds "
              "— work, personal, shared family calendars — into a single upcoming-events view.")
        step("Calendar widget (Session 10)")
        print()
        print(f"  {Colours.BOLD}Provider support:{Colours.RESET}")
        info("• Google Calendar   — OAuth 2.0, all calendars visible to the account")
        info("• Microsoft Outlook — OAuth 2.0, Microsoft Graph API (add Azure credentials to enable)")
        info("• Apple iCloud      — CalDAV + app-specific password (coming soon)")
        print()
        info("Multi-feed: each account is a LinkedCredential row. Events from all active")
        info("credentials merge into one view sorted by start time.")
        info("Refresh cadence: every 15 minutes, server-side")
        print()
        if self.google_oauth_ready:
            print(f"  {Colours.BOLD}Connect a Google Calendar account:{Colours.RESET}")
            print(f"  {Colours.CYAN}  {SERVER_URL}/calendar/oauth/start?authUserId=00000000-0000-0000-0000-000000000001{Colours.RESET}")
            print()

        step("Seeding demo calendar events")
        if self.seed_demo_calendar_data():
            ok("5 demo events inserted across Work, Personal, and Family calendars")
            info("Today:    Team standup  •  1:1 with Sarah")
            info("Tomorrow: Dentist appointment  •  Kids soccer game")
            info("Day 3:    Q3 planning session")
        else:
            warn("Could not seed calendar data — calendar widget will show placeholder.")

        # Step 11: Photo frame + Microsoft Calendar
        pause("Session 11 added a photo frame slot and Microsoft Calendar. Let's walk through both.")
        step("Photo frame (system.photos)")
        print()
        print(f"  {Colours.BOLD}How it works:{Colours.RESET}")
        info("• A 30-min server-side FutureCall syncs image metadata from a Google Drive folder")
        info("• Image bytes are proxied on-demand through GET /photos/{id} — nothing stored on disk")
        info("• Photos rotate every 45 seconds with an animated crossfade")
        info(f"Refresh: metadata every 30 min  •  bytes fetched live on each transition")
        print()
        info("To enable: set googleDriveFolderId in passwords.yaml, restart server.")
        print()
        print(f"  {Colours.BOLD}Microsoft Calendar:{Colours.RESET}")
        info("MicrosoftCalendarService is fully implemented (Microsoft Graph API, OAuth 2.0).")
        info("Routes live at /calendar/microsoft/oauth/start and /calendar/microsoft/oauth/callback.")
        info("Add microsoftClientId + Secret + RedirectUri to passwords.yaml — connect flow works immediately.")

        # Step 12: Settings
        pause("Session 12 added a settings screen, ambient dim mode, and a drag-to-move layout editor.")
        step("Settings screen")
        print()
        print(f"  {Colours.BOLD}How to access:{Colours.RESET}")
        info("Single-tap anywhere on the display — a gear icon (⚙) appears in the bottom-right")
        info("corner. Tap the icon to open Settings. It auto-hides after 5 seconds.")
        print()
        print(f"  {Colours.BOLD}Display tab:{Colours.RESET}")
        info("• Ambient dim — toggle on/off, set start/end hour (default: 10 pm → 7 am)")
        info("• Dim level slider — default 85% opacity")
        info("• Location name — override the label shown on the weather card")
        print()
        print(f"  {Colours.BOLD}Accounts tab:{Colours.RESET}")
        info("• Lists all connected credentials (Google Calendar, Microsoft Calendar)")
        info("• Shows copyable OAuth connect URLs — visit from any device on the same network")
        info("• Agent Keys section — enter management token to view all API keys with their")
        info("  lastUsedAt and lastUsedIp so you can spot anomalous access at a glance (A07)")
        print()
        print(f"  {Colours.BOLD}Layout tab:{Colours.RESET}")
        info("• Drag cards to move anywhere in the 12×8 grid")
        info("• Drag corner handle to resize cards (columnSpan / rowSpan)")
        info("• Tap a card to toggle its visibility (hidden cards keep their slot)")
        info("• Preset switcher — Weekday / Weekend / Night chips at the top")

        # Step 13: Self-hosting
        pause("Session 13 adds the full self-hosting story — Docker Compose, a Raspberry Pi image, "
              "and a Fire TV APK.")
        step("Self-hosting overview (Session 13)")
        print()
        print(f"  {Colours.BOLD}Server stack (any Linux machine):{Colours.RESET}")
        info("• docker compose -f deploy/docker-compose.prod.yml up -d")
        info("• Runs: Serverpod server, Postgres, Redis, Caddy (auto SSL)")
        info("• Postgres backups automatically at 2 AM, 7 days retained")
        info("• First-time setup:  bash deploy/scripts/setup.sh")
        print()
        print(f"  {Colours.BOLD}Display options:{Colours.RESET}")
        info("• Fire TV / Android:  bash tools/scripts/build_apk.sh   (sideloaded via adb)")
        info("• Raspberry Pi:       bash tools/scripts/build_linux.sh  (fullscreen on HDMI)")
        info("• Pi all-in-one image: bash deploy/pi-gen/build.sh — flash, boot, done")
        print()
        print(f"  {Colours.BOLD}Nothing leaves your network:{Colours.RESET}")
        info("• OAuth tokens stored encrypted on your own Postgres instance")
        info("• API keys never transmitted to the display client")
        info("• No telemetry, no external service dependency")
        print()
        info("Full guides: docs/self_hosting_guide.md  •  docs/raspberry_pi_guide.md")

        # Step 14: First-run wizard
        pause("Session 14 adds the first-run setup wizard — the guided path from 'Docker is up' "
              "to 'display is showing my data' without touching a config file.")
        step("First-run setup wizard (Session 14)")
        print()
        print(f"  {Colours.BOLD}What it does:{Colours.RESET}")
        info("• Shown automatically when no server URL is configured (fresh install)")
        info("• Walks through 4 steps: Server URL, Location, Accounts overview, Done")
        info("• Server URL step pings the configured URL before accepting it")
        info("• Partial completion is persisted — resume at the right step after a restart")
        print()
        print(f"  {Colours.BOLD}When the display launches below, the wizard may appear.{Colours.RESET}")
        print(f"  {Colours.CYAN}  Server URL:   http://localhost:8080/{Colours.RESET}")
        print(f"  {Colours.CYAN}  Location:     any city name  (or skip){Colours.RESET}")
        print(f"  {Colours.CYAN}  Accounts:     tap 'Got it'   (connect later from Settings){Colours.RESET}")
        print(f"  {Colours.CYAN}  Done:         tap 'Launch Landfall'{Colours.RESET}")

        # Step 15: Ghost ticker + card actions
        pause("Session 15 adds the ghost ticker — ambient agent heartbeats at the bottom of the display "
              "— and interactive action buttons on cards.")
        step("Ghost ticker & interactive card actions (Session 15)")
        print()
        print(f"  {Colours.BOLD}Ghost ticker:{Colours.RESET}")
        info("• Agents push ticker messages via  POST /agent/pushTicker  or MCP tool push_ticker")
        info("• Appears as a 28px strip at the bottom — scrolls, crossfades, zero height when empty")
        info("• layout: 'ticker' routes a card to the strip; default TTL 30 seconds")
        info("• persistent: true is rejected for ticker cards by design")
        print()
        print(f"  {Colours.BOLD}Interactive card actions:{Colours.RESET}")
        info("• Cards can carry  actions: [{ id, label, type, payload, requireConfirm }]")
        info("• Types: dismiss | openUrl | webhook | openSettings")
        info("• requireConfirm: true shows a confirmation dialog before executing")
        info("• GenericAgentCard renders action buttons in a Wrap below the body")

        # Step 16: Layout presets, resize, server-side persistence
        pause("Session 16 adds Weekday / Weekend / Night layout presets, resize handles in the layout "
              "editor, and server-side layout sync.")
        step("Layout presets & editor improvements (Session 16)")
        print()
        print(f"  {Colours.BOLD}Preset layouts:{Colours.RESET}")
        info("• Three built-in presets: Weekday, Weekend, Night")
        info("• Weekday  — clock, weather, forecast strip, calendar")
        info("• Weekend  — clock, weather, calendar, photos (family-focused)")
        info("• Night    — clock only, minimal display for nightstand mode")
        info("• Presets are customisable — changes persist per preset independently")
        info("• Settings → Layout tab shows the preset switcher (3 chips)")
        print()
        print(f"  {Colours.BOLD}Layout editor improvements:{Colours.RESET}")
        info("• Each card now has a bottom-right resize handle")
        info("• Drag the handle to change columnSpan / rowSpan — snaps to grid cells")
        info("• Ghost outline shows the new size before release")
        print()
        print(f"  {Colours.BOLD}Server-side layout persistence:{Colours.RESET}")
        info("• Layouts are stored in layout_configs table on the Serverpod server")
        info("• LayoutEndpoint: getLayouts, saveLayout, setActiveLayout, deleteLayout")
        info("• All displays sharing a server instance stay in sync automatically")
        info("• Drift (local SQLite) is kept as an offline fallback")

        # Step 17: Monetization — license system + pack marketplace
        pause("Session 17 adds the one-time license system and integration pack marketplace.")
        step("Monetization: License System & Pack Marketplace (Session 17)")
        print()
        print(f"  {Colours.BOLD}License tiers:{Colours.RESET}")
        info("• Free  — 500 API pushes/day, 7-day card history")
        info("• Pro   — unlimited rate limits, 90-day history, multi-display sync  (~$50 one-time)")
        info("• Founding Member — Pro + all packs in first 18 months             (~$80 one-time)")
        print()
        print(f"  {Colours.BOLD}License key flow:{Colours.RESET}")
        info("• User purchases via Stripe payment link (one-time, no subscription)")
        info("• Stripe webhook  POST /stripe/webhook  receives purchase confirmation")
        info("• Server generates  LF-PRO-XXXX-XXXX  key, stored in  license_keys  table")
        info("• User activates in app: Settings → License → Activate a Key")
        info("• License is tied to the Serverpod account — survives app reinstalls")
        print()
        print(f"  {Colours.BOLD}Integration pack marketplace:{Colours.RESET}")
        info("• 6 packs seeded in the database at migration time:")
        info("  Sports Scores ($5)  •  Home Assistant ($7)  •  Todoist / Tasks ($5)")
        info("  RSS Headlines ($5)  •  Countdown Timers ($5)  •  Stocks & Crypto ($8)")
        info("• Stripe webhook grants packs to users on purchase (owned_packs table)")
        info("• PackEndpoint: listPacks (isOwned flag), getOwnedPacks")
        info("• Settings → License → Browse Integration Packs opens the pack browser")
        print()
        print(f"  {Colours.BOLD}New in app:{Colours.RESET}")
        info("• Settings → License tab: tier badge, upgrade links, key entry field")
        info("• Pack browser: grid view of all packs with pricing and owned status")
        info("• LicenseCubit manages loading/activating state with full bloc_test coverage")

        # Step 18: Theme Engine
        pause("Phase 14 adds the theme engine — five built-in themes seeded on startup, "
              "a validator that checks every token at upload time, and endpoints for "
              "applying themes per-profile.")
        step("Theme Engine (Phase 14)")
        print()
        print(f"  {Colours.BOLD}Built-in themes (seeded automatically on server start):{Colours.RESET}")
        info("• Default Dark     — clean dark, the factory default for every new display")
        info("• Default Light    — bright environment variant")
        info("• Neon Arcade      — high-contrast neon on deep black, high energy")
        info("• Deep Blue        — calm navy palette with cyan accent")
        info("• Warm Editorial   — off-white print/magazine aesthetic")
        print()
        print(f"  {Colours.BOLD}Theme token vocabulary (ThemeSchema v1.0):{Colours.RESET}")
        info("• surface    — background type/value, card fill/border/radius/blur/shadow")
        info("• typography — font family, scale, heading/body weight, letter spacing")
        info("• color      — accent, text.primary/secondary/tertiary, success/warning/alert")
        info("• animation  — transition, speed, cardEntry, tickerScroll")
        info("• moods      — urgent, muted, celebratory, success overrides per-card")
        print()
        print(f"  {Colours.BOLD}Derived tokens (resolved at upload time, never stored raw):{Colours.RESET}")
        info("• color.accentMuted   — accent at 15% opacity (auto-derived from accent)")
        info("• color.divider       — text.primary at 10% opacity")
        info("• color.agent.border  — accent at 30% opacity")
        print()

        step("Listing built-in themes from the running server")
        themes = self.list_themes()
        for t in themes:
            marker = "★" if t.get("isBuiltIn") else "○"
            print(f"   {marker} [{t['slug']}]  {t['name']}")
        ok(f"{len(themes)} theme(s) available")

        pause("Themes are validated at upload time — every token is type-checked, enum values "
              "are enforced, numeric ranges are bounded. Here's a live custom theme upload.")

        step("Uploading a custom theme")
        custom_yaml = '''version: "1.0"
meta:
  name: "Demo Custom"
  author: "demo"
  description: "A minimal demo theme uploaded live."
  tags: [demo, minimal]
color:
  accent: "#FF6B6B"
  text:
    primary: "#FFFFFF"
surface:
  background:
    type: solid
    value: "#1A1A2E"
  card:
    fill: "rgba(255,255,255,0.05)"
    border:
      color: "rgba(255,107,107,0.3)"
      width: 1.0
      style: solid
    radius: 6
animation:
  transition: fade
  speed: normal
  cardEntry: fade
  tickerScroll: normal'''

        result = self.upload_theme(custom_yaml)
        if result.get("theme"):
            slug = result["theme"].get("slug", "unknown")
            ok(f"Custom theme uploaded — slug: {slug}")
            info("Resolved tokens (accentMuted, divider, agent.border) were derived automatically.")
        else:
            errors = result.get("errors", [])
            msg = errors[0].get("message", "unknown error") if errors else "unknown error"
            warn(f"Upload skipped — {msg}")

        print()
        print(f"  {Colours.BOLD}ThemeEndpoint — full surface area:{Colours.RESET}")
        info("• listThemes()                — all available themes, ordered by name")
        info("• uploadTheme(yaml)           — validate + store; returns errors on failure")
        info("• importTheme(url)            — HTTPS fetch + validate + store (10 s timeout)")
        info("• previewTheme(id)            — returns the resolved token JSON string")
        info("• applyTheme(themeId,         — links theme to a named profile")
        info("             profileId)")
        info("• deleteTheme(id)             — removes imported themes; built-ins are protected")
        print()

        # Security hardening overview
        pause("Before we launch: Landfall went through a full OWASP Top 10:2025 audit. "
              "Here's what was hardened.")
        step("Security hardening (OWASP Top 10:2025)")
        print()
        print(f"  {Colours.BOLD}A01 — Broken Access Control:{Colours.RESET}")
        info("• ApiKeyEndpoint (generateKey / listKeys / revokeKey) is auth-gated behind")
        info("  apiKeyManagementToken from passwords.yaml — no unauthenticated key creation")
        print()
        print(f"  {Colours.BOLD}A04 — Cryptographic Failures:{Colours.RESET}")
        info("• API key hashes stored as HMAC-SHA-256 keyed with apiKeyHmacSecret")
        info("• Offline brute force is impossible even if the database is fully compromised")
        info("• Empty secret fails loudly at startup — no silent SHA-256 fallback")
        print()
        print(f"  {Colours.BOLD}A05 — Injection:{Colours.RESET}")
        info("• actionsJson validated server-side: size cap (8 KB), max 5 actions,")
        info("  type allowlist, label length limit, URL scheme whitelist (https/http only)")
        print()
        print(f"  {Colours.BOLD}A06 — Insecure Design:{Colours.RESET}")
        info("• Card action URLs validated client-side: no javascript:, file://, data: schemes")
        info("• Webhook targets blocked on private IPs / loopback / cloud metadata endpoints")
        info("• importTheme() blocks private IP ranges server-side (SSRF prevention)")
        print()
        print(f"  {Colours.BOLD}A07 — Authentication Failures:{Colours.RESET}")
        info("• lastUsedIp recorded on every authenticated request")
        info("• Settings → Accounts → Agent Keys surfaces prefix, lastUsedAt, lastUsedIp")
        info("  for all keys — anomalous access is visible at a glance")
        print()
        print(f"  {Colours.BOLD}A09 — Security Logging:{Colours.RESET}")
        info("• Auth failures log api_key.auth_failed (warning) with key prefix + caller IP")
        info("• Management token rejections log api_key.setup_token_rejected")
        info("• generateKey and revokeKey log api_key.generated / api_key.revoked (info)")
        print()
        ok("See SECURITY.md for the hardening scope and disclosure process")

        # Launch display
        pause("Ready to launch. The wizard will appear on a fresh install — walk through it, "
              "then the full display loads with all the demo cards we pushed.")
        step("Launching Landfall display (macOS)")
        info("The app will open in a new window. Press Cmd+Q to quit when done.")
        print()

        try:
            subprocess.run(["flutter", "run", "-d", "macos", "lib/main.dart"], cwd=DISPLAY_DIR)
        except KeyboardInterrupt:
            pass

if __name__ == "__main__":
    setup_logging()
    demo = LandfallDemo()

    # Register signals for cleanup
    signal.signal(signal.SIGINT, demo.cleanup)
    signal.signal(signal.SIGTERM, demo.cleanup)

    try:
        demo.preflight()
        demo.run_demo()
    except Exception as e:
        logger.exception("An error occurred during the demo")
        die(f"Fatal error: {e}")
    finally:
        demo.cleanup()

