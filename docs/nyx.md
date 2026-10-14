# Nyx — the complete conversion (record)

Status: **implemented** (2026-10, `branch/experimental`). This document is the
design record: what coupled Nyx to the shell, what changed, and the extension
rules Nyx defines through the plugin system.

## What was coupled (and its resolution)

| Coupling | Resolution |
|---|---|
| Static overlay import in `shell/ui/Mascots.qml` | Resolved: the wrapper resolves `provides.mascots.overlay` through the plugin catalog (`PluginsCatalog.uiUrl`) and loads it dynamically — `setSource` injects the constant API, `Binding`s keep live values (palette, catalog, stats, favorites) updated, `favoriteToggled` connects in `onLoaded`, and with no provider installed nothing renders |
| Hardcoded species path in `shell/core/MascotsCatalog.qml` | Resolved: species and card dirs come from provider plugins (`provides.mascots.species` / `.cards`, resolved per plugin origin); the user dirs still win on `id` |
| Shell-owned notch defaults (`shell/notch/defaults.json`) | Resolved: the cards moved into the plugin (`notch/`) |
| Hardcoded deploy in `dots` (the `nyx)` case) | Pending F1 — the manifest-driven deploy retires it |

## Extension rules (defined by this integration, not by the standard)

The plugin *standard* only knows a generic, free-form `provides` object passed
through by the hosts. The mascots integration defines its own keys, and Nyx is
their first provider:

```json
"provides": {
  "mascots": {
    "overlay": "front/MascotsOverlay.qml",
    "species": "mascots",
    "cards": "notch"
  }
}
```

Resolution rules:

- Sources: the user dirs (`~/.config/hypr/mascots/species/` / `notch/`) win on
  `id`; then every provider plugin, in plugin-scan order (user plugins first,
  then managed, by name). First definition of an `id` wins.
- Entries keep `_base`, so relative QML (`entry`, `popover`) resolves exactly
  the way it did before.
- With a single provider (Nyx) the behavior is identical to before; extra
  providers only add entries, or override by `id`.
- The editor (Plugins → Nyx) renders any catalog entry with its
  `customizable` / `controls` options — species contributed by other plugins
  show up with their controls automatically.

Natural follow-ups: bar modules, panels and palettes as provider surfaces,
each with its own rules defined by its consumer (never by this standard).

## Does the hub carry Nyx's code?

Recommendation (unchanged): **no**. The concentration folder (`plugins/`) is
for plugins that ship through this repo. Nyx keeps its own repo as the single
source of truth; the hub references it.

## Open points

- Precedence policy when two providers ship the same species `id` (today:
  first wins) — revisit if it ever happens in practice.
- `provides` may earn a consumer-key convention note in `plugins.md` once a
  second consumer exists (today the generic passthrough is documented and the
  mascots keys live in Nyx's README plus `shell/docs/mascots.md`).
