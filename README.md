# equisdots · plugins

Plugin standard, sample, template and the workshop where equisdots stack
features get converted into plugins.

| Path | What |
|---|---|
| `docs/plugins.md` | **Plugin standard** — manifest, folders, enablement, scan + loader + CLI contracts |
| `samples/hello/` | POC fixture: a minimal `hypr` plugin (one keybind) |
| `template/` | Copy this to start a new plugin |
| `converted/` | Features extracted from the stack become plugins here (screenshots is first) |

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
cp -r samples/hello ~/.config/hypr/plugins-user/
# Settings → Plugins → enable "Hello Plugin", then press SUPER + SHIFT + H
```

Status: **POC** — the standard is a draft; see `docs/plugins.md` for the
contracts, the acceptance criteria and the open questions.

## License

MIT — see [LICENSE](LICENSE).
