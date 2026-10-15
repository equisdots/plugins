# Conversion roadmap

Features of the equisdots stack move from the core repos (`hyprland`,
`shell`) into self-contained plugins under the standard in `plugins.md`.
Every converted plugin lands in the **`plugins/`** concentration folder.

Order (working list):

1. `screenshots` — screenshots + recording (script + binds + UI overlay) —
   **done (F2)**: cut over; the core copies (hyprland binds + script, shell
   overlay) are removed and `dots` installs the plugin by default
   (`DEFAULT_PLUGINS`).
2. `timex` — calendar/weather popup + engine + settings page — **done**:
   the plugin ships the panel (`provides.panels.calendar`), the SUPER+S bind
   (`hypr.lua`) and the settings page (`p_timex`); the shell core keeps only
   the generic panel host and the `weather.sh` shim.
3. `rss-reader` — feed reader panel — **done**: moved to the hub with a
   rebuilt UI, its own feed manager/settings page and the SUPER+O bind.

**Staying in the core (decided):** `idle-lock` and `monitors` are session
infrastructure (unlock/PAM, display bring-up) — a broken plugin there is not
"a missing feature", it is an unusable session, so they stay in the system
repos by design.

Graduation to a standalone repo stays possible at any time: copy the folder
out; the manifest makes the deploy identical.
2. `idle-lock` — hypridle + lock (PAM / sudoers touchpoints)
3. `monitors` — monitor manager + scale menu + display-config restorer

Graduation to a standalone repo stays possible at any time: copy the folder
out; the manifest makes the deploy identical.
