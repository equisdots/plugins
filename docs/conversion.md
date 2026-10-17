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
4. `clipboard` — clipboard manager panel — **done**: hub plugin with its own
   settings page (items per page + position) and the SUPER+C bind.
5. `quicknotes` — scratch notepad — **done**: hub plugin with its own
   settings page and the SUPER+Y bind.
6. `file-search` — file search panel — **done**: hub plugin with its own
   settings page and the SUPER+apostrophe bind.

The `screenshots` plugin also owns the bar recording indicator now
(`provides.bar.modules.recording` → `bar/Recording.qml`); the shell keeps no
recording state.

Bar islands follow the same route: the `timex` plugin ships the weather island
(`provides.bar.modules.weather` → `bar/Weather.qml`, self-polling its engine —
the shell's `weather.sh` shim and the bar weather poller are gone) and the
`sysmon` plugin ships the CPU/RAM island (`provides.bar.modules.sysmon` →
`bar/Sysmon.qml`, reading the core `SysData`). `sysmon` joins the default set;
its floating monitor became an explicit opt-in toggle (`sysmon.panelEnabled`).

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
