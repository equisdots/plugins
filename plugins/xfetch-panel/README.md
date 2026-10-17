# XFetch Panel

An **xfetch-style system fetch inside the shell**: a system logo, a monospace
key/value field list (OS, kernel, uptime, shell, WM, CPU, memory, disk) and the
live palette strip. Opened as a popup (`qs_manager.sh toggle xfetch`).

- Kind: **panel** (`provides.panels.xfetch`, 720x420)
- UI: `ui/XfetchPanel.qml`
- Value producer: `scripts/fetch-info.sh` (prints `key|value` lines)
- Settings: Plugins → XFetch Panel

Complements the terminal `xfetch` (whose per-palette themes `theme-sync`
already generates): same information, rendered natively with the active palette.
