# converted

Plugins extracted from the equisdots stack land here while they are being
converted from core components (`hyprland`, `shell`) into self-contained
plugins under the standard in `docs/plugins.md`.

Order of conversion (working list):

1. `screenshots` — screenshots + recording (script + binds + deps)
2. `idle-lock` — hypridle + lock (PAM / sudoers touchpoints)
3. `monitors` — monitor manager + scale menu + display-config restorer

Each converted plugin gets its own folder with `plugin.json`, its payload and
a README; graduation to a standalone repo stays possible at any time (the
manifest makes the move cheap).
