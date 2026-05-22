# Beta Known Limitations

Items in this list are **shipped-as-is for the public beta**. Each one has
a working path users can follow today; the entry documents that workflow
and links to the future work that will improve it.

If you hit something here, it is expected behavior — not a bug to file.
For anything *not* listed here that misbehaves, please open an issue.

---

## Fire TV — on-screen keyboard appearance on text fields not yet verified

**What you see:** On Fire TV, the supported sign-in path for the beta is
the "Sign in with a code from your phone" link, not the email field
directly. Typing into the email field with a TV remote is not a
guaranteed path: whether the Amazon IME pops on focus has not been
confirmed on hardware.

**Workflow today:** Use the "Sign in with a code from your phone" link
below the email form on the login screen. It opens the companion
device-flow on a phone or laptop — no typing on the TV required.

**Future work:** Verify the keyboard-on-focus behavior on a physical
Fire TV. If it does not appear reliably, escalate to the mDNS-driven
companion handoff in [`firetv_remote_nav_plan.md`](firetv_remote_nav_plan.md).

---

## `LandfallFocusable` widget is available but not yet adopted

**What you see:** Nothing at runtime. The shared `LandfallFocusable`
widget in `packages/ui_kit` provides a consistent focus ring + scale
animation, but no production screens use it yet — focus treatment in
the display app is still per-screen.

**Workflow today:** No user-visible action required.

**Future work:** Migrate existing focusable surfaces to
`LandfallFocusable` (see `packages/ui_kit/lib/src/widgets/landfall_focusable.dart`
and its tests/goldens). Tracked under Phase 1c of
[`firetv_remote_nav_plan.md`](firetv_remote_nav_plan.md).

---

## 1920×1080 golden coverage for the display screen is incomplete

**What you see:** Nothing at runtime. The Fire TV layout normalization
that maps Android to a 1920×1080 logical coordinate space is verified
manually on hardware but does not yet have golden-test coverage at
that exact size for the full display screen.

**Workflow today:** None — the layout works correctly on hardware.

**Future work:** Add `test/src/features/display/screens/display_screen_golden_test.dart`
at 1920×1080 to lock in the normalized layout against regressions.

---

## Agent cards from prior servers may appear when reusing an account

**What you see:** If you sign in to a fresh install with a Landfall
account that was previously associated with other servers, cards
pushed under that account from those prior servers may appear in the
agent card feed alongside the live server's cards.

**Workflow today:** Either sign in with a fresh account, or delete the
stale cards from the companion once they appear.

**Future work:** Scope the card store to the currently-configured
server identity, so the display only renders cards pushed to *this*
server — not the union of every server the account has ever touched.

---

## For AI assistants

- This doc is the beta surface for "things we chose not to fix before
  launch." Each entry must have **(1)** what the user sees, **(2)** the
  working path today, **(3)** the future-work pointer.
- Do not add items here unless they are intentionally deferred. Real
  bugs go to the issue tracker.
- Before adding an entry, **verify the limitation against current
  code** — handover notes go stale. If the work has already landed,
  do not list it here.
- When a deferred item lands, remove its entry from this file in the
  same commit, and update [`docs/README.md`](README.md) if the file
  ever becomes empty enough to retire.
