#!/usr/bin/env python3
"""
Landfall boot splash — shown by Openbox autostart while the server starts.
Polls http://localhost:8080/ every 2 seconds and exits when the server responds,
handing the screen over to the Flutter display app.

Branding follows the Landfall identity (see site/index.html + ui_kit
landfall_colors.dart): Navy background, lowercase "landfall" wordmark,
Periwinkle tagline, Cyan loading accent.

Logo: if a PNG mark is present next to this script (or at $LANDFALL_SPLASH_LOGO)
it is rendered above the wordmark. The expected asset is a square, transparent
PNG ("the mark" only) at 1024x1024. When no asset is found the splash falls
back to the wordmark alone, so the splash is always on-brand even before the
logo file is installed.
"""
import os
import tkinter as tk
import threading
import urllib.request
import time

SERVER_URL = "http://localhost:8080/"
POLL_INTERVAL = 2

# ── Brand palette (landfall_colors.dart) ─────────────────────────────────────
BG        = "#0B1021"  # Navy   — primary display background
FG_TITLE  = "#FFFFFF"  # White  — wordmark
FG_SUB    = "#A3B1FF"  # Periwinkle — tagline / secondary text
FG_STATUS = "#778199"  # Steel  — tertiary status text
ACCENT    = "#00E5FF"  # Cyan   — loading accent

DOTS = ["   ", ".  ", ".. ", "..."]

# On-screen height for the logo mark, as a fraction of screen height. The mark
# asset carries ~18% transparent padding, so the visible card reads a bit
# smaller than this box.
LOGO_SCREEN_FRACTION = 0.28


def poll_server(on_ready):
    while True:
        try:
            urllib.request.urlopen(SERVER_URL, timeout=3)
            on_ready()
            return
        except Exception:
            time.sleep(POLL_INTERVAL)


def _logo_path():
    """Resolve the logo asset path, or None if none is configured/present."""
    override = os.environ.get("LANDFALL_SPLASH_LOGO")
    if override and os.path.isfile(override):
        return override
    here = os.path.dirname(os.path.abspath(__file__))
    default = os.path.join(here, "landfall-logo.png")
    return default if os.path.isfile(default) else None


def _load_logo(target_px):
    """
    Load the brand logo scaled to roughly target_px tall.

    Prefers Pillow for smooth scaling; falls back to Tk's integer subsample so
    the splash still works on a minimal image without Pillow installed. Returns
    a Tk-compatible image object (kept referenced by the caller) or None.
    """
    path = _logo_path()
    if not path:
        return None
    # Smooth path: Pillow resize to the exact target height.
    try:
        from PIL import Image, ImageTk  # type: ignore

        img = Image.open(path).convert("RGBA")
        w, h = img.size
        if h > 0:
            scale = target_px / h
            img = img.resize((max(1, int(w * scale)), max(1, int(h * scale))))
        return ImageTk.PhotoImage(img)
    except Exception:
        pass
    # Fallback path: Tk PhotoImage with integer subsample (downscale only).
    try:
        photo = tk.PhotoImage(file=path)
        if photo.height() > target_px:
            factor = max(1, round(photo.height() / target_px))
            photo = photo.subsample(factor, factor)
        return photo
    except Exception:
        return None


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

    # Optional brand mark above the wordmark. Keep a reference on the widget so
    # the image is not garbage-collected (a classic Tk footgun).
    logo = _load_logo(int(sh * LOGO_SCREEN_FRACTION))
    if logo is not None:
        logo_label = tk.Label(frame, image=logo, bg=BG, borderwidth=0)
        logo_label.image = logo
        logo_label.pack(pady=(0, 24))

    tk.Label(
        frame, text="landfall",
        fg=FG_TITLE, bg=BG,
        font=("sans-serif", 52, "bold"),
    ).pack()

    tk.Label(
        frame, text="your home display",
        fg=FG_SUB, bg=BG,
        font=("sans-serif", 16),
    ).pack(pady=(6, 36))

    status_var = tk.StringVar(value="Starting up" + DOTS[0])
    tk.Label(
        frame,
        textvariable=status_var,
        fg=FG_STATUS, bg=BG,
        font=("monospace", 13),
    ).pack()

    # Thin accent rule under the status line — the only saturated brand colour
    # on the splash, so the eye lands on the "still working" signal.
    accent_rule = tk.Frame(frame, bg=ACCENT, height=2, width=48)
    accent_rule.pack(pady=(18, 0))

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
