#!/usr/bin/env python3
"""
Landfall boot splash — shown by Openbox autostart while the server starts.
Polls http://localhost:8080/ every 2 seconds and exits when the server responds,
handing the screen over to the Flutter display app.
"""
import tkinter as tk
import threading
import urllib.request
import time

SERVER_URL = "http://localhost:8080/"
POLL_INTERVAL = 2

BG        = "#0a0a0a"
FG_TITLE  = "#ffffff"
FG_SUB    = "#555555"
FG_STATUS = "#333333"

DOTS = ["   ", ".  ", ".. ", "..."]

def poll_server(on_ready):
    while True:
        try:
            urllib.request.urlopen(SERVER_URL, timeout=3)
            on_ready()
            return
        except Exception:
            time.sleep(POLL_INTERVAL)

def main():
    root = tk.Tk()
    # Force the window to cover the whole screen using detected geometry.
    # `attributes('-fullscreen', True)` alone is unreliable on first boot
    # because the WM may not be fully initialised when the window is mapped;
    # `overrideredirect(True)` strips decorations but causes the WM to ignore
    # the fullscreen hint entirely, so the window keeps Tk's default 200x200
    # size and ends up in the corner. Setting explicit screen-sized geometry
    # before fullscreen request avoids both failure modes.
    root.update_idletasks()
    sw = root.winfo_screenwidth()
    sh = root.winfo_screenheight()
    root.geometry(f"{sw}x{sh}+0+0")
    root.configure(bg=BG)
    root.attributes("-fullscreen", True)
    root.attributes("-topmost", True)
    root.config(cursor="none")

    # Cover the root with a frame matching screen size so layout is centered
    # regardless of any residual WM decoration.
    canvas = tk.Frame(root, bg=BG, width=sw, height=sh)
    canvas.place(x=0, y=0, relwidth=1, relheight=1)

    frame = tk.Frame(canvas, bg=BG)
    frame.place(relx=0.5, rely=0.5, anchor="center")

    tk.Label(
        frame, text="landfall",
        fg=FG_TITLE, bg=BG,
        font=("sans-serif", 52, "bold"),
    ).pack()

    tk.Label(
        frame, text="your home display",
        fg=FG_SUB, bg=BG,
        font=("sans-serif", 16),
    ).pack(pady=(4, 32))

    status_var = tk.StringVar(value="Starting up" + DOTS[0])
    tk.Label(
        frame,
        textvariable=status_var,
        fg=FG_STATUS, bg=BG,
        font=("monospace", 13),
    ).pack()

    dot_index = [0]
    def animate():
        dot_index[0] = (dot_index[0] + 1) % len(DOTS)
        status_var.set("Starting up" + DOTS[dot_index[0]])
        root.after(500, animate)

    animate()

    def on_ready():
        root.after(0, root.destroy)

    threading.Thread(target=poll_server, args=(on_ready,), daemon=True).start()
    root.mainloop()

if __name__ == "__main__":
    main()
