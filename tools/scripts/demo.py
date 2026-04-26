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
            resp = self.run_api_request("/apiKey/generateKey", {"name": "demo"})
            self.api_key = resp["plainTextKey"]
            ok(f"API key generated: {Colours.BOLD}{self.api_key}{Colours.RESET}")
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

        self.push_card("agent.research", "New paper: LLM reasoning benchmarks", "Three Stanford papers dropped overnight.")
        ok("Card 4 — agent.research (open endpoint)")

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

        # Step 8: MCP info (Skipping printing all MCP text for brevity in log, but keeping it for user)
        pause("All of the above is also available as MCP tools.")
        step("MCP server (landfall_mcp)")
        print(f"\n  {Colours.BOLD}Server URL:{Colours.RESET} {SERVER_URL}")
        print(f"  {Colours.BOLD}API Key:{Colours.RESET}    {self.api_key}\n")

        # Step 9-14: Educational steps (Summary)
        step("Built-in widgets & Features")
        info("• Weather widget (OpenWeatherMap)")
        info("• Calendar widget (Google/Microsoft)")
        info("• Photo frame (Google Drive)")
        info("• Settings & Layout editor")
        info("• First-run wizard")

        if not self.weather_live:
            warn("Weather cards will show a placeholder (OWM key not set).")

        step("Seeding demo calendar events")
        if self.seed_demo_calendar_data():
            ok("5 demo events inserted")
        else:
            warn("Could not seed calendar data.")

        # Step 15: Launch Display
        pause("Ready to launch. The app will open in a new window. Press Cmd+Q to quit.")
        step("Launching Landfall display (macOS)")

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

