# Dock

A configurable application dock for the equisdots shell: your launchers on any
screen edge, with live dimensions, colors and automatic palette following.

- **Type**: `shell` (host adapter + its own settings page).
- **Master switch**: `dock.enabled` (the manifest's `toggle`).
- **Settings**: everything lives in `settings.json` → `dock`.
- **Host**: `host/Dock.qml` — one layer-surface panel per screen on the
  configured edge; mounted generically by `ui/PluginHosts.qml`.
- **Page**: `settings/DockPage.qml` — the Plugins group's dynamic `p_dock`
  page (apps, layout, appearance, live preview).
- **Script**: `scripts/apps.sh` — lists installed `.desktop` apps as JSON for
  the in-page picker (self-contained; no shell-kit dependency).

## Palette

`background: "auto"` (default) follows the shell's active palette through the
`Colors` singleton, so the dock re-themes with the rest of the desktop.
`background: "custom"` uses an explicit palette role or a `#rrggbb` color.

## Settings schema (`settings.json` → `dock`)

| Key | Default | Meaning |
|---|---|---|
| `enabled` | `false` | master switch (feature on/off) |
| `position` | `"bottom"` | `top` \| `bottom` \| `left` \| `right` |
| `iconSize` | `44` | icon box size in px (16–96) |
| `spacing` | `10` | gap between icons |
| `padding` | `10` | inner padding of the panel |
| `margin` | `8` | gap from the screen edge |
| `radius` | `20` | panel corner radius |
| `reserve` | `false` | reserve the dock edge so windows clear it |
| `showLabels` | `false` | label under each icon |
| `magnify` / `magnifyScale` | `true` / `1.35` | hover zoom |
| `opacity` | `0.85` | panel background opacity |
| `background` | `"auto"` | `auto` (shell palette) \| `custom` |
| `color` | `"surface0"` | palette role or `#rrggbb` when custom |
| `border` / `borderColor` | `true` / `"surface1"` | panel border |
| `apps` | `[]` | `[{ id, label, icon, exec }]`, in display order |

## Layout

```
dock/
├── plugin.json
├── host/Dock.qml
├── settings/DockPage.qml
└── scripts/apps.sh
```

No plugin-internal directory imports are used, so no `qmldir` is required
(the page and host import the shell kit by deployed relative path).
