#!/usr/bin/env python3
"""
Landfall on-screen diagnostic — fallback when the display app fails to launch.
Shows hostname, LAN IP, SSH instructions, and pointers to the relevant logs
so the operator can recover the device without needing a separate monitor.
"""
import socket
import subprocess
import tkinter as tk

BG       = "#0a0a0a"
FG_HEAD  = "#ff7a7a"   # warm red for the error heading
FG_TITLE = "#ffffff"
FG_BODY  = "#cccccc"
FG_DIM   = "#666666"
FG_MONO  = "#7ad9ff"   # cyan for commands

def hostname() -> str:
    try:
        return socket.gethostname()
    except Exception:
        return "(unknown)"

def primary_ip() -> str:
    # Best-effort: pick the first non-loopback IPv4 by opening a UDP
    # socket toward a public-ish IP. No packets are actually sent.
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
    ).pack(pady=(0, 24))

    tk.Label(
        inner,
        text=(
            "The Flutter display binary crashed repeatedly.\n"
            "The rest of the system is running so you can connect over the network\n"
            "and inspect the logs."
        ),
        fg=FG_BODY, bg=BG, font=("sans-serif", 14), justify="center",
    ).pack(pady=(0, 32))

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

    tk.Label(
        inner,
        text="After SSH'ing in, the most useful commands:",
        fg=FG_DIM, bg=BG, font=("sans-serif", 12),
    ).pack(pady=(28, 6))

    for cmd in (
        "tail -200 ~/.landfall-display.log",
        "journalctl -u landfall-firstboot -u landfall-server -b",
        "cd ~/landfall/deploy && docker compose ps",
        "cd ~/landfall/deploy && docker compose logs --tail=200 server",
    ):
        tk.Label(
            inner, text=cmd, fg=FG_MONO, bg=BG, font=("monospace", 12),
        ).pack(anchor="w")

    root.mainloop()

if __name__ == "__main__":
    main()
