# Conversion roadmap

Features of the equisdots stack move from the core repos (`hyprland`,
`shell`) into self-contained plugins under the standard in `plugins.md`.
Every converted plugin lands in the **`plugins/`** concentration folder.

Order (working list):

1. `screenshots` — screenshots + recording (script + binds + UI overlay) —
   **staged** at `plugins/screenshots/`; still shipped by `hyprland` +
   `shell` until the deploy (F1) and the cutover land.
2. `idle-lock` — hypridle + lock (PAM / sudoers touchpoints)
3. `monitors` — monitor manager + scale menu + display-config restorer

Graduation to a standalone repo stays possible at any time: copy the folder
out; the manifest makes the deploy identical.
