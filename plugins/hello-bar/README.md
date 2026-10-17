# Hello Bar — POC fixture

A **minimal complete bar** shipped by a plugin. It exists to exercise the
`provides.bar.provider` surface end to end: discovery, generic mounting,
master switch, own settings page and live palette.

## What it does

- Ships one reserved `PanelWindow` per screen (34 px band on the top edge)
  with a clock and an optional date — see `bar/HelloBar.qml`.
- Declares `provides.bar.provider` in `plugin.json`, so `ui/PluginHosts.qml`
  mounts it while the plugin is enabled (exactly like a host adapter).
- Owns its settings (`defaults.json` → scope `hello-bar`, stored in the
  plugin's own settings file) and its own page — `settings/HelloBarPage.qml`
  — as its menu in the Plugins group.

## Try it

```sh
dots plugins add hello-bar        # deploy + enable
# it ships disabled-sensitive: enable it in the Plugins manager
# disable the core bar in the Bar group when Hello Bar should own the edge
```

## Notes

- The core bar and plugin bars are independent: each has its own switch.
  If both stay on the same edge they stack — disable the core bar (Bar group
  → General → Bar enabled) when a plugin bar should own the screen edge.
- Placement is deliberately hardcoded (top edge, 34 px) — a real bar plugin
  would expose edge/size from its own page, exactly like this page exposes
  the date toggle.
