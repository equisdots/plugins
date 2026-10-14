# Sysmon

A configurable floating system monitor for the equisdots desktop: a small card
showing live **CPU / RAM / temperature** bars, placed in any corner.

Demonstrates the plugin architecture end-to-end:

- **Host adapter** (`host/Sysmon.qml`) — publishes an overlay surface through
  the SDK **surface manager** (`surfaces` descriptor) and reads live stats via
  the injected handle (`host.stats` = SysData) and the palette (`host.colors`).
- **Settings page** (`settings/SysmonPage.qml`) — the Plugins group's dynamic
  `p_sysmon` page, built with the stable public kit (`qs.ui.bar.edit`).
- **Manifest** — `toggle: sysmon.enabled`, `scope: sysmon`, `api.requires`,
  `compat.host`.

## Settings schema (`settings.json` → `sysmon`)

| Key | Default | Meaning |
|---|---|---|
| `enabled` | `false` | master switch (manifest toggle) |
| `position` | `"top-right"` | `top-left` \| `top-right` \| `bottom-left` \| `bottom-right` |
| `uiScale` | `1.0` | card scale (0.6–2.0) |
| `opacity` | `0.85` | panel background opacity |
| `showCpu` / `showRam` / `showTemp` | `true` | which metrics to draw |

## Layout

```
sysmon/
├── plugin.json
├── host/Sysmon.qml
├── settings/SysmonPage.qml
└── README.md
```
