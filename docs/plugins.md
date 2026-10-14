# equisdots · Plugins — Standard v0

> **Status: draft — POC implemented** (2026-10, `branch/experimental`). Nyx is
> plugin #1; the shell ships the Plugins group (manager + per-plugin pages),
> the Hyprland config runs the loader and `dots` has the `plugins` command.
> Scope: the Hyprland stack (`dots`, `hyprland`, `shell`, `nyx`, `plugins`).
> niri is explicitly out of scope for this document.

A **plugin** is a self-contained feature that declares itself with a
`plugin.json` manifest. Plugins are:

- **installed** — their manifest lives in a plugins registry folder
  (managed by `dots`, or user-owned),
- **discovered** — hosts scan folders; no host code knows plugin ids,
- **enabled/disabled** — state in `settings.json`, resolved through the
  plugin's own switch when it declares one,
- **toggleable live** — flipping the state updates the desktop without
  reinstalling.

Model references: the **Nyx module** (self-contained repo, injected
dependencies, folder discovery) and **GNOME Extensions** (installed list +
toggles — a store is a later phase).

Three states, deliberately separated:

| State | Meaning | v0? |
|---|---|---|
| Installed | a manifest exists in a registry folder | ✅ yes |
| Enabled | its switch in `settings.json` is true | ✅ yes |
| Available | known in a registry/store, not installed | ❌ later phase |

---

## 1. Folders

| Folder | Owner | Notes |
|---|---|---|
| `~/.config/hypr/plugins/<id>/` | `dots` | managed deploy (`rsync --delete`), one directory per installed plugin |
| `~/.config/hypr/plugins-user/<id>/` | user | personal / development plugins; **wins** on `id` collision |

Discovery = any directory containing a `plugin.json`. The user folder is
scanned first, so a user plugin with the same `id` shadows the managed one
(same rule as Nyx species/cards).

The registry folder holds the **manifest**; payload lives wherever the plugin
needs it. A `hypr` plugin keeps its `hypr.lua` next to its manifest; a shell
plugin's QML stays deployed by its own install path (e.g. Nyx keeps its QML at
`ui/nyx/` — only its manifest lands in the registry).

`plugins/` is the **installed registry**, not necessarily where the code
lives. This keeps discovery cheap and unambiguous.

---

## 2. Manifest — `plugin.json`

```json
{
  "id": "nyx",
  "name": "Nyx",
  "version": "0.1.0",
  "author": "equisdots",
  "description": "Mascot island and control-center notch for the shell",
  "type": "shell",
  "compat": { "shell": ">=0.1.0" },
  "toggle": "mascots.enabled",
  "settingsTab": "mascots"
}
```

| Field | Required | Type | Notes |
|---|---|---|---|
| `id` | ✅ | slug | stable; used in settings keys, folder names and the CLI |
| `name` | ✅ | string | display name |
| `version` | ✅ | semver | `"0.1.0"` |
| `author` | ✅ | string | `"equisdots"` or a user handle |
| `description` | ✅ | string | one line, shown on the plugin card |
| `type` | ✅ | `shell` \| `hypr` \| `mixed` \| `cli` | badge + payload expectations |
| `compat` | — | object | `{ "hyprland": ">=0.55", "shell": ">=0.1.0" }` — informational in v0, enforced by `dots doctor` in F1 |
| `toggle` | — | settings path | where the enable switch lives; default: `plugins.<id>.enabled` |
| `settingsTab` | — | string | id of an existing shell settings tab — renders the "Configure" button on the card |
| `defaultEnabled` | — | bool (default `false`) | effective state when no switch exists in `settings.json` yet |

Minimal `hypr` example (the POC fixture):

```json
{
  "id": "hello",
  "name": "Hello Plugin",
  "version": "0.0.1",
  "author": "equisdots",
  "description": "POC fixture: a keybind that greets",
  "type": "hypr",
  "compat": { "hyprland": ">=0.55" }
}
```

---

## 3. Enablement contract

- **Key**: `plugins.<id>.enabled` by default. A plugin that already has its own
  master switch declares it in `toggle` (Nyx → `mascots.enabled`), so the
  plugin card never duplicates an existing switch.
- **Written by**: the shell Plugins page and `dots plugins enable|disable <id>`
  — atomically, following the existing `settings.json` contract. Plugins never
  write their own enable state.
- **Missing key**: `defaultEnabled` applies (default `false` — opt-in).
- **Live application**:
  - shell side: the settings watcher already applies keys live;
  - hypr side: `reload.sh` (`hyprctl reload`) re-evaluates the config, so a
    fragment enters/leaves the session on toggle. No reinstalling.

---

## 4. Scan contract

`core/scripts/plugins_scan.sh` — lives in the **shell** core, mirrors
`core/scripts/mascots_scan.sh` (`shipped`+`user` folders, user wins). It reads
the manifests, resolves the effective `enabled` state from `settings.json`, and
prints a JSON array sorted by `name`:

```json
[
  {
    "id": "nyx",
    "name": "Nyx",
    "version": "0.1.0",
    "author": "equisdots",
    "description": "Mascot island and control-center notch for the shell",
    "type": "shell",
    "toggle": "mascots.enabled",
    "enabled": false,
    "settingsTab": "mascots",
    "_base": "/home/user/.config/hypr/plugins/nyx"
  }
]
```

Consumers: the shell **Plugins group** (manager page + per-plugin pages),
`dots plugins`, and (later) an xturing tab. One implementation, three
surfaces.

---

## 5. Hyprland loader

A new core module (`plugins.lua`, required by `hyprland.lua` **after** the core
modules and **before** the `config/` user overrides):

- scans both folders (user wins), reads `settings.json` (`io` is available in
  the embedded Lua — verified; a small vendored JSON decoder is bundled by the
  SDK), and for each **enabled** plugin that ships a `hypr.lua`, evaluates it
  passing the SDK as `...`;
- **isolation**: `pcall` per plugin. A failing plugin never aborts the config;
  errors are collected into `~/.cache/equisdots/plugins-report.json` for the
  page/CLI to surface (badges: v1);
- **SDK v0** (`mod`):
  - `mod.id`, `mod.dir` — identity and the plugin's own folder;
  - `mod.script(name)` — path helper for the plugin's `scripts/`;
  - `mod.bind(key, cmd, opts)` — thin wrapper over `hl.bind` that also records
    the human label (feeds the future keybind UI);
  - `mod.log(msg)` — prefixed logging.

A `hypr.lua` fragment is plain config code:

```lua
local mod = ...
mod.bind("SUPER + SHIFT + H", hl.dsp.exec_cmd("notify-send 'Hello from a plugin'"),
         { label = "Hello: greet" })
```

---

## 6. `dots` CLI (v0 minimum)

- `dots plugins` — table of installed plugins from the scan: id, name, version,
  type, enabled.
- `dots plugins enable|disable <id>` — writes the effective toggle and calls
  `reload.sh`.

Deploy in v0: Nyx's manifest is placed in `~/.config/hypr/plugins/nyx/` by its
existing deploy step (one line). **Manifest-driven deploy** (`add`/`remove`/
`doctor`) is F1; the POC fixture installs by simply copying its folder into
`plugins-user/hello/` — proving user plugins need zero `dots` changes.

---

## 7. POC acceptance criteria

Acceptance criteria (parse-level checks verified in this environment; the
live-session checks run on real hardware):

1. **Fixture flow**: `hello` dropped into `plugins-user/` → appears in the
   Plugins page as *disabled* → toggle on → the bind works live → toggle off →
   bind gone. No config reload errors at any point.
2. **Fault isolation**: a deliberately broken plugin loads → session keeps
   running, error recorded in `plugins-report.json`.
3. **Nyx**: appears as a `shell` plugin; its toggle **is** `mascots.enabled`
   (identical to the Mascots page switch); "Configure" opens the Mascots tab.
4. **Green checks**: `luac -p` / `luacheck` / `Hyprland --verify-config` /
   `qmllint` / the repos' `scripts/check.sh`.
5. **Visual**: the Plugins page renders live with both plugins listed.

---

## 8. Non-goals (v0)

- Store / registry of *available* plugins.
- `dots plugins add|remove`, version updates, `doctor` enforcement.
- xturing Plugins tab, error badges on the page, keybind editor.
- Generic shell-UI deploy (v1: shell payload conventions).
- Anything niri.

---

## 9. Open questions (for review)

1. **`defaultEnabled`** semantics for future extractions (e.g. when
   `screenshots` becomes a plugin, existing users must not lose their binds
   silently — migration policy).
2. **Duplicate binds across plugins** — policy: last loaded wins vs. detected
   and reported.
3. ~~Where the Plugins page lives~~ — **decided**: a Plugins group in the
   settings panel (manager page `d_plugins` + the plugin's own page, e.g.
   `d_nyx`; `plugin.json → settingsTab` points at it).
4. Naming: `plugins/` + `plugin.json` + "Plugins" group — confirm, or rename
   (extensions? modules?).
5. ~~Fixture home~~ — **decided**: `samples/` in this repo; converted plugins
   live in `converted/` while being extracted.
