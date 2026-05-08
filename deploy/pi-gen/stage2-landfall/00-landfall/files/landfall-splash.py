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
    root.attributes("-fullscreen", True)
    root.configure(bg=BG)
    root.overrideredirect(True)

    frame = tk.Frame(root, bg=BG)
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
