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
| `tests/smoke.sh` | Local checks (no CI): manifests, `qmldir` imports, scan resolution, lints **plus hub id integrity** (duplicate ids, registry consistency, every hub plugin registered) |

## How it works (v0)

- A plugin declares itself with `plugin.json` and is discovered by **scanning
  folders**: `~/.config/hypr/plugins/<id>/` (managed by `dots`) and
  `~/.config/hypr/plugins-user/<id>/` (yours; wins on `id` collisions).
- The settings panel grows a **Plugins** group: every installed plugin shows
  up with an enable/disable toggle and a Configure shortcut to its own page.
- Enable state lives in the plugin's **own settings file**
  (`~/.config/hypr/plugins/<id>/settings.json`) under the manifest's `toggle`
  path (`plugins.<id>.enabled` by default, or the plugin's own switch — Nyx,
  for example, points at `mascots.enabled` so there is only one switch); the
  core `settings.json` only carries the config-menu flag.
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

AGPL-3.0-or-later — see [LICENSE](LICENSE). Copyright (C) 2026 xscriptor <x@xscriptor.com>.

This repository is licensed under the GNU Affero General Public License, version 3 or any later version. If you modify the software and let users interact with it over a network, you must offer them the corresponding source.

Releases published before 2026-11-13 were distributed under the MIT License and remain available under those terms.

Third-party components, fonts, icons, images, sounds, vendored code and other assets keep their original licenses and are not covered by this license. See THIRD-PARTY.md / CREDITS.md where present.

Bundled third-party plugins may keep their own license and attribution; the
`_template/` scaffold is Apache-2.0 for user-created plugins. See
[PLUGIN-LICENSING.md](PLUGIN-LICENSING.md).
