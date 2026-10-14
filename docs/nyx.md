# Nyx — completing the conversion, and its extensibility (review)

Status: **review only** — nothing in this document is implemented yet. It
assesses what keeps Nyx from being a fully decoupled plugin and how its
extension points should work through the plugin system.

## Where Nyx still couples to the shell

| Coupling | Location | Effect |
|---|---|---|
| Static overlay import | `shell/ui/Mascots.qml` — `import "./plugins/nyx/front"` plus a direct `MascotsOverlay {}` instance | Nyx only works from the managed deploy path; a missing Nyx is a QML error; a user-cloned Nyx does not render |
| Hardcoded species path | `shell/core/MascotsCatalog.qml` — `mascotsShipped` points at `ui/plugins/nyx/mascots` | Species only come from the managed deploy; no other plugin can contribute species |
| Hardcoded deploy | `dots` — the `nyx)` case | Retires with the manifest-driven deploy (F1); Nyx is the first rider |
| Shell-owned notch defaults | `shell/notch/defaults.json` | Nyx's notch cards ship with the shell instead of the plugin |

## Complete conversion — plan

1. **Dynamic overlay** (`ui/Mascots.qml`): resolve the overlay through the
   plugin catalog — managed plugins from the shell-tree deploy, user plugins
   via `file://` — and load it with a `Loader`:
   - `setSource(url, { ... })` injects the documented API properties
     (palette, settings path, widget hooks, catalog, stats, favorites);
   - reactive values (palette, catalog, favorites, ...) update through an
     en-bloc of `Binding` objects guarded by `loader.item`;
   - the `favoriteToggled` handler connects in `onLoaded`;
   - Nyx absent: the loader stays empty — no error, no island.
2. **Dynamic species and cards** (`core/MascotsCatalog.qml`): the scans gain
   a third source — installed plugins that *provide* species/cards (below).
   The hardcoded Nyx path disappears; Nyx becomes a provider like any other.
3. **Deploy**: F1 generic (`dots plugins add`); no Nyx-specific case.
4. Optional: move `shell/notch/defaults.json` into Nyx (`notch/`), leaving
   the shell with no shipped cards.

Feasibility: the injection contract is already public (Nyx's README lists the
overlay API), the wrapper is the static import's only consumer, and the
property set is fixed — the change is contained to `ui/Mascots.qml` and the
catalog. The delicate part is property-injection timing (initial properties
vs. reactive bindings); the known-good pattern is `setSource` for the initial
set and `Binding` for anything that changes afterwards.

## Extensibility through the plugin system

Goal: Nyx defines *extension points*; other plugins plug in without touching
Nyx or the shell — drop a plugin in `plugins/`, enable it, and the island
grows.

Manifest addition (v0.2 proposal):

```json
"provides": {
  "mascots": { "species": "mascots" },
  "notch":   { "cards": "notch" }
}
```

Resolution rules (extends the current catalog contract):

- Sources: the user dir (`~/.config/hypr/mascots/species/`) wins on `id`;
  then every provider plugin, in plugin-scan order (user plugins first, then
  managed, by name). First definition of an `id` wins.
- Entries keep `_base` so relative QML (`entry`, `popover`) resolves exactly
  the way it does today.
- With a single provider (Nyx) the behavior is identical to today; extra
  providers only add entries or override by `id`.
- The editor (Plugins → Nyx) already renders any catalog entry with its
  `customizable` / `controls` options — species contributed by other plugins
  show up with their controls automatically.

This makes Nyx the first plugin with extension points. Natural follow-ups
after it: bar modules, panels and palettes as provider surfaces.

## Does the hub carry Nyx's code?

Recommendation: **no**. The concentration folder (`plugins/`) is for plugins
that ship through this repo. Nyx keeps its own repo as the single source of
truth, and the hub references it (F1's registry will map ids to sources).
Vendoring a copy here would only add drift risk.

## Open points

- Injection timing details for the dynamic overlay.
- Precedence policy when two providers ship the same species `id`.
- Whether `provides` deserves a schema entry in `plugins.md` at v0.2.
