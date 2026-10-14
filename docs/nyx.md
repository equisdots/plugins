# Nyx — the complete conversion (record)

Status: **implemented** (2026-10, `branch/experimental`). This document is the
design record: what coupled Nyx to the shell, and how the final architecture
works.

## Final architecture

The shell knows **nothing** about mascots, species, notch cards or Nyx. Its
only generic mechanisms are:

| Shell mechanism | What it does |
|---|---|
| `PluginsCatalog` | scans installed plugins and resolves their UI root (managed: shell-tree deploy; user: own folder) |
| `ui/PluginHosts.qml` | mounts every enabled managed plugin's `host` entry and republishes host `frameObstacle` rects through FrameBus |
| `FrameBus.hostObstacles` | generic bus the screen frame consumes (hug the rects, never reserve `avoidReserve` edges) |
| Plugins group (`p_<id>`) | settings pages declared with `settings.page` |

Nyx ships, in its own repo, everything feature-shaped:

```
nyx/
  host/Mascots.qml       host adapter: imports the core kit, renders the
                         overlay and publishes frameObstacle
  catalog/               species/cards discovery (MascotsCatalog + scan)
  settings/NyxPage.qml   its settings page (Plugins → Nyx)
  front/                 the overlay (island/notch + dock)
  mascots/  notch/       shipped species + default cards
```

Deploy: the whole repo lands in the shell tree (`ui/plugins/nyx/`) plus the
manifest in the registry. The adapter and the catalog reach the shell only
through the documented kit imports (`../../../../core`, `../../../bar`).

## What was coupled (resolutions)

| Coupling | Resolution |
|---|---|
| Static overlay import in a shell wrapper | The wrapper moved into the plugin (`host/`); the shell only mounts host entries generically, loaded relatively |
| Mascots catalog + scan in shell core | Moved to `catalog/` in the plugin; the shell core has no mascot code |
| Frame knew the island geometry (`mascotObstacle`, `settings.mascots`) | Generic `frameObstacle` host contract via FrameBus; the frame hugs any host rect and skips its edge when `avoidReserve` |
| Shell-owned notch defaults | Moved into the plugin (`notch/`) |
| Hardcoded `dots` case | Pending F1 (generic manifest-driven deploy) |

## Nyx's extension rules (plugin-owned)

The standard only knows a generic `provides` passthrough. Nyx defines its own
keys:

```json
"host": "host/Mascots.qml",
"provides": { "mascots": { "species": "mascots", "cards": "notch" } }
```

- `provides.mascots.species` / `.cards`: any installed plugin may declare the
  same keys (paths relative to its UI root) to extend the island; the user
  dirs (`~/.config/hypr/mascots/...`) still win on `id`.
- `host`: shell-tree adapters are a managed-plugin feature (they import the
  shell kit). User plugins ship self-contained settings pages and hypr/script
  payloads instead.

## Notes

- Legacy `frame.notchMascot` still reads as `notchHosts` (settings compat).
- Type-shadowing caveat: plugin pages load with **relative** sources;
  `file://` loading changes unqualified type resolution (QtQuick.Controls
  exports a `Config` that would shadow the core singleton).

## Open points

- F1 deploy (retires the `dots` case; `dots plugins add`).
- Precedence policy when two providers ship the same species `id` (today:
  first wins).
