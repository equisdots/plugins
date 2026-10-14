# equisdots · Plugins — Standard v0

> **Status: draft — POC implemented** (2026-10, `branch/experimental`). Nyx is
> plugin #1 and ships its **own settings page** (self-contained plugin UI);
> the shell ships the Plugins group (manager + dynamic plugin pages), the
> Hyprland config runs the loader and `dots` has the `plugins` command.
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
| Installed | a manifest exists in a registry folder | yes |
| Enabled | its switch in `settings.json` is true | yes |
| Available | known in a registry/store, not installed | later phase |

---

## 1. Folders

| Folder | Owner | Notes |
|---|---|---|
| `~/.config/hypr/plugins/<id>/` | `dots` | managed deploy (`rsync --delete`), one directory per installed plugin |
| `~/.config/hypr/plugins-user/<id>/` | user | personal / development plugins; **wins** on `id` collision |

Discovery = any directory containing a `plugin.json`. The user folder is
scanned first, so a user plugin with the same `id` shadows the managed one
(same rule as Nyx species/cards).

Deploy convention (managed plugins): the **whole repo** goes to the shell tree
at `ui/plugins/<id>/` (the UI face: settings pages, host adapters, overlays,
wrappers — Nyx's old `ui/nyx` path, generalized), and the **runtime subset**
additionally goes
to the registry `~/.config/hypr/plugins/<id>/`: the manifest (always), plus
`hypr.lua` and `scripts/` when present (what the loader runs; `mod.script()`
resolves there). Nyx needs no restructuring for this — its repo *is* its UI.

`plugins/` is the **installed registry** (discovery + the compositor side);
the shell-tree copy is what Quickshell loads.

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
  "settings": { "page": "settings/NyxPage.qml", "label": "Nyx" }
}
```

| Field | Required | Type | Notes |
|---|---|---|---|
| `id` | yes | slug | stable; used in settings keys, folder names and the CLI |
| `name` | yes | string | display name |
| `version` | yes | semver | `"0.1.0"` |
| `author` | yes | string | `"equisdots"` or a user handle |
| `description` | yes | string | one line, shown on the plugin card |
| `type` | yes | `shell` \| `hypr` \| `mixed` \| `cli` | badge + payload expectations |
| `compat` | — | object | `{ "hyprland": ">=0.55", "shell": ">=0.1.0" }` — informational in v0, enforced by `dots doctor` in F1 |
| `toggle` | — | settings path | where the enable switch lives; default: `plugins.<id>.enabled` |
| `settings` | — | object | the plugin ships its own settings page: `{ page, label?, icon? }`. `page` is a QML file in the repo, deployed with the UI to `ui/plugins/<id>/`; it appears in the Plugins group as `p_<id>` and Configure opens it (see §6) |
| `settingsTab` | — | string | legacy: id of an existing shell settings tab (pre `settings.page`) |
| `host` | — | string | managed plugins only: a QML host adapter (path relative to the plugin UI root) the shell mounts generically (`ui/PluginHosts.qml`). It runs inside the shell tree and may import the core kit; used for always-on UI (overlays, surfaces). Hosts may publish `frameObstacle` rects for the screen frame |
| `provides` | — | object | free-form contributions passed through untouched by the hosts and interpreted by consumers — never by this standard. Namespace keys by consumer (`"<consumer>": { ... }`) to avoid collisions |
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
- **Config menu**: `plugins.<id>.config` (bool, default `true`) — whether the
  plugin's settings page appears in the Plugins group. The manager card shows
  both switches; the master switch hides the page regardless, so everything
  the plugin owns follows it.
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
    "config": true,
    "settings": { "page": "settings/NyxPage.qml", "label": "Nyx" },
    "_base": "/home/user/.config/hypr/plugins/nyx"
  }
]
```

Consumers: the shell **Plugins group** (manager page + per-plugin pages),
`dots plugins`, and (later) an xturing tab. One implementation, three
surfaces.

Hosts pass manifest fields through untouched (e.g. `provides`), so consumers
implement their own contribution rules without changes to this standard.

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

## 6. Plugin settings pages (own config menu)

A plugin that declares `settings.page` ships **its own configuration UI**; the
shell wires it dynamically:

- **Deploy**: `dots` copies the whole plugin into the shell tree at
  `ui/plugins/<id>/` (the Nyx precedent, generalized from the old `ui/nyx`);
  the runtime subset (`plugin.json`, `hypr.lua`, `scripts/`) also lands in the
  registry (see §1).
- **Nav**: `EditorNav.withPlugins()` appends one item per plugin with a
  settings page — id `p_<id>`, `label`/`icon` from the manifest — but only
  while the plugin is enabled and its config menu is on (§3); the item stays
  hideable/orderable through `settings.editor` like any other.
- **Load**: the editor loads the page on demand
  (`ui/plugins/<id>/<settings.page>`) with the same contract as its own
  pages: the QML root receives the editor as an initial property
  (`property var bar`) — `bar.s()`, `bar.colors`, `bar.gotoPage()`.
- **Kit imports**: at the deployed path, the shell's shared editor kit and
  core singletons resolve as `../../../bar/edit` and `../../../../core`.
  Managed pages live in the shell tree so these resolve; **user** plugins
  (`plugins-user/`) load their page via `file://` from their own folder, so
  their page must be self-contained QML (no shell-kit imports). A public kit
  path or an injected host API is a v0.2 item (open question §10.6).
- Nyx is the first adopter: `settings/NyxPage.qml` — the whole mascot/island
  menu moved into the plugin repo; the shell no longer owns that page.

---

## 7. `dots` CLI (v0 minimum)

- `dots plugins` — table of installed plugins from the scan: id, name, version,
  type, enabled.
- `dots plugins enable|disable <id>` — writes the effective toggle and
  reloads Hyprland (`hyprctl reload`).

Deploy in v0: Nyx's UI rsyncs to `ui/plugins/nyx/` and its manifest to
`~/.config/hypr/plugins/nyx/` (its existing deploy step). **Manifest-driven deploy** (`add`/`remove`/
`doctor`) is F1; the POC fixture installs by simply copying its folder into
`plugins-user/hello/` — proving user plugins need zero `dots` changes.

### Registry (install-time index)

`registry.json` (repo root) lists every known plugin and where it comes from —
this repo, `equisdots/nyx`, or any external repo. The runtime never reads it
(installed plugins are discovered by folder scan, §4); it is the **install-time
source list** for `dots plugins add <id>` (F1) and the seed of a future store
view (available vs. installed).

| Field | Req | Notes |
|---|---|---|
| `version` | yes | registry schema version (currently `1`) |
| `plugins[].id` | yes | must match the plugin's `plugin.json → id` |
| `plugins[].source` | yes | `owner/repo` |
| `plugins[].path` | no | subdirectory when one repo hosts several plugins; absent = the repo root is the plugin |
| `plugins[].name` / `.author` / `.description` | no | display hints for listings (the manifest stays the source of truth) |

```json
{ "version": 1, "plugins": [
  { "id": "nyx", "source": "equisdots/nyx" },
  { "id": "screenshots", "source": "equisdots/plugins", "path": "plugins/screenshots" }
] }
```

---

## 8. POC acceptance criteria

Acceptance criteria (parse-level checks verified in this environment; the
live-session checks run on real hardware):

1. **Fixture flow**: `hello` dropped into `plugins-user/` → appears in the
   Plugins page as *disabled* → toggle on → the bind works live → toggle off →
   bind gone. No config reload errors at any point.
2. **Fault isolation**: a deliberately broken plugin loads → session keeps
   running, error recorded in `plugins-report.json`.
3. **Nyx**: appears as a `shell` plugin; its toggle **is** `mascots.enabled`
   (identical to its Mascots page switch); "Configure" opens the plugin's own
   page (dynamic `p_nyx`, loaded from `ui/plugins/nyx/`).
4. **Green checks**: `luac -p` / `luacheck` / `Hyprland --verify-config` /
   `qmllint` / the repos' `scripts/check.sh`.
5. **Visual**: the Plugins page renders live with both plugins listed.

---

## 9. Non-goals (v0)

- Store / registry of *available* plugins.
- `dots plugins add|remove`, version updates, `doctor` enforcement.
- xturing Plugins tab, error badges on the page, keybind editor.
- A public plugin UI kit (v0.1 pages import the shell kit via deployed
  relative paths).
- Anything niri.

---

## 10. Open questions (for review)

1. **`defaultEnabled`** semantics for future extractions (e.g. when
   `screenshots` becomes a plugin, existing users must not lose their binds
   silently — migration policy).
2. **Duplicate binds across plugins** — policy: last loaded wins vs. detected
   and reported.
3. ~~Where the Plugins page lives~~ — **decided**: a Plugins group in the
   settings panel (manager page `d_plugins` + one dynamic page per plugin,
   `p_<id>`, from `plugin.json → settings.page`).
4. Naming: `plugins/` + `plugin.json` + "Plugins" group — confirm, or rename
   (extensions? modules?).
5. ~~Fixture home~~ — **decided**: every plugin concentrates in this repo's
   `plugins/` folder (one folder per plugin, any origin); `_template/` is the
   scaffold; external plugins keep their own repos and are referenced.
6. **Plugin UI kit**: v0.1 pages import the shell's editor kit by deployed
   relative path (`../../../bar/edit`, `../../../../core`). Options for v0.2:
   a stable public kit directory (`ui/sdk/`) vs. an injected host API (no
   imports — the Nyx overlay philosophy applied to settings pages).
