# Keybinds — plugin shortcut editor

The intermediate layer between the core and the plugins for keyboard
shortcuts: every plugin declares its binds (in its `hypr.lua`, via
`mod.bind`), and this plugin shows them and lets the user change their **key**
— or mute a single bind — without touching the plugin itself.

- **The plugin owns the action; the user owns the key.** A bind's dispatcher
  stays in the plugin's fragment; overrides only replace the key string (or
  disable that one bind while the plugin stays enabled).
- **Where it reads**: `~/.cache/equisdots/plugins-report.json`, written by the
  Hyprland loader on every config load (labels, ids, effective keys,
  overrides, plus the last-known binds of disabled plugins, marked cached).
- **Where it writes**: the plugin's **own settings file**
  (`~/.config/hypr/plugins/<id>/settings.json`), under `<scope>.binds.<id>`:
  `"SUPER + SHIFT + C"` to rebind, `false` to disable that single bind.
  "Reset" deletes the entry (back to the plugin's default).
- **How it applies**: every write triggers `hyprctl reload`; the loader
  re-evaluates the fragments with the overrides applied and rewrites the
  report, which this page watches live.

The page lives in the Plugins group (enabled by default). A disabled plugin
keeps its last known binds visible (`cached`) so you can see what would come
back — and pre-set keys — before re-enabling it.

## Plugin authoring notes

- `mod.bind(key, dispatcher, { label = "…", id = "…" })`: the `label` feeds
  this editor (and `hyprctl`'s bind description); the optional `id` is the
  stable override key (default: a slug of the label — set an explicit `id`
  when labels may change).
- Duplicate ids inside one plugin log a warning in the report
  (`plugins-report.json` → `logs`); keep ids unique per plugin.
