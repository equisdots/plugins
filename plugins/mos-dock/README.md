# mos Dock

A macOS Golden Gate-inspired bottom dock, independent from `mos-topbar` and
`samurai-dock`.

- Kind: **host adapter** (`host` in `plugin.json`)
- Floating Liquid Glass capsule with a bright rim and soft shadow; click-through
  outside the dock
- Full-bleed app icons resolved through `Quickshell.iconPath` (system icon name
  or absolute path), with a Nerd Font glyph fallback
- Apple-like hover behaviour: magnification of the hovered icon and its
  neighbours, hover label, running-app dots and a small launch bounce
- Thin separator plus fixed Downloads and Trash items at the right
- Editable launchers: label, icon, glyph, command and optional `match` classes
  for the running indicator
- Live appearance settings: icon size, spacing, opacity, magnification,
  magnification scale, labels, Liquid Glass, running dots, bounce, Downloads
  and Trash
- Settings: Plugins -> mos Dock (`settings/MosDockPage.qml`)
- `defaultEnabled` is false
