# XFetch Themes

Browse and apply the terminal **xfetch** themes from a shell popup. `theme-sync`
generates one xfetch theme per palette (`~/.config/xfetch/themes/<slug>.jsonc`)
and sets the active one; this plugin lets you switch without leaving the shell.

- Kind: **panel** (`provides.panels.xfetch-themes`, 560x600)
- UI: `ui/XfetchThemes.qml`
- Value producer: `scripts/themes.sh` (`list` / `current` / `set <slug>` — textual
  edit of `~/.config/xfetch/config.jsonc`, keeps comments)
- Settings: Plugins → XFetch Themes

Open with `qs_manager.sh toggle xfetch-themes`.
