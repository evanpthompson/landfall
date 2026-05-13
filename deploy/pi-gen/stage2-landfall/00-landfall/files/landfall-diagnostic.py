#!/usr/bin/env python3
"""
Landfall on-screen diagnostic — fallback when the display app fails to launch.
Shows hostname, LAN IP, SSH instructions, the relevant logs, and runs a quick
set of live probes so the operator knows which subsystem is actually broken
before SSH'ing in.
"""
import socket
import subprocess
import threading
import tkinter as tk
import urllib.request
from urllib.error import URLError

BG       = "#0a0a0a"
FG_HEAD  = "#ff7a7a"   # warm red for the error heading
FG_TITLE = "#ffffff"
FG_BODY  = "#cccccc"
FG_DIM   = "#666666"
FG_MONO  = "#7ad9ff"   # cyan for commands
FG_OK    = "#7aff8c"   # green
FG_WARN  = "#ffd07a"   # amber
FG_FAIL  = "#ff7a7a"   # red

POLL_INTERVAL_SEC = 5


def hostname() -> str:
    try:
        return socket.gethostname()
    except Exception:
        return "(unknown)"


def primary_ip() -> str:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("1.1.1.1", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        pass
    try:
        out = subprocess.check_output(
            ["hostname", "-I"], stderr=subprocess.DEVNULL, timeout=2
        ).decode().strip()
        if out:
            return out.split()[0]
    except Exception:
        pass
    return "(no network)"


def probe_server(port: int) -> tuple[str, str]:
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/", timeout=3):
            return ("ok", f"port {port}: responding")
    except URLError as exc:
        return ("fail", f"port {port}: {exc.reason}")
    except Exception as exc:
        return ("fail", f"port {port}: {exc}")


def probe_systemd_unit(name: str) -> tuple[str, str]:
    try:
        out = subprocess.check_output(
            ["systemctl", "is-active", name],
            stderr=subprocess.DEVNULL, timeout=3,
        ).decode().strip()
    except subprocess.CalledProcessError as exc:
        out = (exc.output or b"").decode().strip()
    except Exception as exc:
        return ("fail", f"{name}: {exc}")

    if out == "active":
        return ("ok", f"{name}: active")
    if out in ("activating", "reloading"):
        return ("warn", f"{name}: {out}")
    return ("fail", f"{name}: {out or 'unknown'}")


def probe_clock_sync() -> tuple[str, str]:
    try:
        out = subprocess.check_output(
            ["timedatectl", "show", "-p", "NTPSynchronized", "--value"],
            stderr=subprocess.DEVNULL, timeout=3,
        ).decode().strip().lower()
    except Exception as exc:
        return ("warn", f"clock: {exc}")
    if out == "yes":
        return ("ok", "clock: synchronised via NTP")
    return ("fail", "clock: NOT synchronised — OAuth tokens may be rejected")


def probe_disk() -> tuple[str, str]:
    try:
        out = subprocess.check_output(
            ["df", "-m", "/"], stderr=subprocess.DEVNULL, timeout=3,
        ).decode().splitlines()
        free_mb = int(out[1].split()[3])
    except Exception as exc:
        return ("warn", f"disk: {exc}")
    if free_mb > 1024:
        return ("ok", f"disk free: {free_mb} MB")
    if free_mb > 256:
        return ("warn", f"disk free: {free_mb} MB — getting tight")
    return ("fail", f"disk free: {free_mb} MB — system will go read-only soon")


def probe_firstboot() -> tuple[str, str]:
    try:
        with open("/var/lib/landfall/.initialized"):
            return ("ok", "firstboot: completed")
    except FileNotFoundError:
        return ("fail", "firstboot: NOT completed — .env may be missing")
    except Exception as exc:
        return ("warn", f"firstboot: {exc}")


PROBES = [
    ("firstboot",          probe_firstboot),
    ("clock",              probe_clock_sync),
    ("disk",               probe_disk),
    ("docker",             lambda: probe_systemd_unit("docker")),
    ("landfall-server",    lambda: probe_systemd_unit("landfall-server")),
    ("API (:8080)",        lambda: probe_server(8080)),
    ("Web (:8082)",        lambda: probe_server(8082)),
    ("lightdm",            lambda: probe_systemd_unit("lightdm")),
]


def status_color(status: str) -> str:
    return {"ok": FG_OK, "warn": FG_WARN, "fail": FG_FAIL}.get(status, FG_DIM)


def status_glyph(status: str) -> str:
    return {"ok": "●", "warn": "●", "fail": "●"}.get(status, "○")


def main():
    root = tk.Tk()
    root.update_idletasks()
    sw = root.winfo_screenwidth()
    sh = root.winfo_screenheight()
    root.geometry(f"{sw}x{sh}+0+0")
    root.configure(bg=BG)
    root.attributes("-fullscreen", True)
    root.attributes("-topmost", True)
    root.config(cursor="none")

    canvas = tk.Frame(root, bg=BG)
    canvas.place(x=0, y=0, relwidth=1, relheight=1)

    inner = tk.Frame(canvas, bg=BG)
    inner.place(relx=0.5, rely=0.5, anchor="center")

    tk.Label(
        inner, text="landfall display did not start",
        fg=FG_HEAD, bg=BG, font=("sans-serif", 28, "bold"),
    ).pack(pady=(0, 12))

    tk.Label(
        inner,
        text=(
            "The Flutter display binary crashed repeatedly.\n"
            "The rest of the system is running so you can connect over the network."
        ),
        fg=FG_BODY, bg=BG, font=("sans-serif", 14), justify="center",
    ).pack(pady=(0, 24))

    # ── Identity rows
    grid = tk.Frame(inner, bg=BG)
    grid.pack()

    def kv(label: str, value: str, value_fg: str = FG_TITLE) -> None:
        row = tk.Frame(grid, bg=BG)
        row.pack(anchor="w", pady=2)
        tk.Label(
            row, text=label, fg=FG_DIM, bg=BG,
            font=("sans-serif", 12), width=14, anchor="w",
        ).pack(side="left")
        tk.Label(
            row, text=value, fg=value_fg, bg=BG,
            font=("monospace", 13),
        ).pack(side="left")

    host = hostname()
    ip = primary_ip()
    kv("Hostname:", f"{host}.local")
    kv("LAN IP:",   ip)
    kv("SSH:",      f"ssh landfall@{ip}",  FG_MONO)

    # ── Probes
    tk.Label(
        inner, text="Live subsystem status", fg=FG_DIM, bg=BG,
        font=("sans-serif", 12),
    ).pack(pady=(24, 6))

    probe_frame = tk.Frame(inner, bg=BG)
    probe_frame.pack()
    probe_labels: dict[str, tuple[tk.Label, tk.Label]] = {}
    for name, _ in PROBES:
        row = tk.Frame(probe_frame, bg=BG)
        row.pack(anchor="w", pady=1)
        glyph_lbl = tk.Label(
            row, text=status_glyph("..."), fg=FG_DIM, bg=BG,
            font=("monospace", 14),
        )
        glyph_lbl.pack(side="left", padx=(0, 6))
        text_lbl = tk.Label(
            row, text=f"{name}: probing...", fg=FG_DIM, bg=BG,
            font=("monospace", 12), anchor="w",
        )
        text_lbl.pack(side="left")
        probe_labels[name] = (glyph_lbl, text_lbl)

    # ── Commands
    tk.Label(
        inner,
        text="Useful commands once SSH'd in:",
        fg=FG_DIM, bg=BG, font=("sans-serif", 12),
    ).pack(pady=(24, 6))
    for cmd in (
        "landfall-doctor",
        "landfall-bug-report",
        "journalctl -t landfall-display -b --no-pager",
        "cd ~/landfall/deploy && docker compose logs --tail=200 server",
    ):
        tk.Label(
            inner, text=cmd, fg=FG_MONO, bg=BG, font=("monospace", 12),
        ).pack(anchor="w")

    # ── Probe loop
    def run_probes() -> None:
        for name, probe in PROBES:
            try:
                status, message = probe()
            except Exception as exc:  # noqa: BLE001
                status, message = ("warn", f"{name}: probe error: {exc}")
            color = status_color(status)
            glyph = status_glyph(status)
            glyph_lbl, text_lbl = probe_labels[name]
            # Tk is not thread-safe — schedule the update on the main loop.
            root.after(0, glyph_lbl.config, {"text": glyph, "fg": color})
            root.after(0, text_lbl.config, {"text": message, "fg": FG_BODY})

    def probe_loop() -> None:
        while True:
            run_probes()
            import time
            time.sleep(POLL_INTERVAL_SEC)

    threading.Thread(target=probe_loop, daemon=True).start()
    root.mainloop()


if __name__ == "__main__":
    main()
