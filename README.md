# equisdots · plugins

Plugin standard and the concentration folder for every equisdots plugin —
converted from the stack, samples, or third-party contributions.

| Path | What |
|---|---|
| `docs/plugins.md` | **Plugin standard** — manifest, folders, enablement, scan + loader + CLI contracts |
| `docs/conversion.md` | Conversion roadmap: which stack features become plugins, and their status |
| `docs/nyx.md` | Review: completing Nyx's conversion and its extensibility through the plugin system |
| `docs/testing.md` | How to deploy the experimental branches on a live session (checklist + rollback) |
| `plugins/` | **Every plugin lives here** — one folder per plugin, folder name = `plugin.json → id`, any origin; `_template/` is the scaffold |
| `registry.json` | Install-time index: every known plugin and its source repo (for `dots plugins add`, future store) |

## How it works (v0)

- A plugin declares itself with `plugin.json` and is discovered by **scanning
  folders**: `~/.config/hypr/plugins/<id>/` (managed by `dots`) and
  `~/.config/hypr/plugins-user/<id>/` (yours; wins on `id` collisions).
- The settings panel grows a **Plugins** group: every installed plugin shows
  up with an enable/disable toggle and a Configure shortcut to its own page.
- Enable state lives in `settings.json` — `plugins.<id>.enabled` by default,
  or the plugin's own switch when its manifest says so (`toggle`); Nyx, for
  example, points at `mascots.enabled` so there is only one switch.
- `hypr` / `mixed` plugins ship a `hypr.lua` fragment that the Hyprland config
  runs at load time with an injected SDK (`mod.*`). A failing plugin never
  aborts the config; errors land in `~/.cache/equisdots/plugins-report.json`.
- `dots plugins list|enable|disable <id>` does the same from the CLI.

Try the sample:

```sh
mkdir -p ~/.config/hypr/plugins-user
cp -r plugins/hello ~/.config/hypr/plugins-user/
# Settings → Plugins → enable "Hello Plugin", then press SUPER + SHIFT + H
```

Status: **POC** — the standard is a draft; see `docs/plugins.md` for the
contracts, the acceptance criteria and the open questions.

## License

MIT — see [LICENSE](LICENSE).
