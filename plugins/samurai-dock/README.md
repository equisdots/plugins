# Samurai Dock

A separate bottom dock in the **Samurai** design language. It is independent
from `samurai-bar`; both can be enabled at the same time.

- Kind: **host adapter** (`host` in `plugin.json`)
- Surface: floating, click-through bottom overlay with a 1px hairline border
- Zones:
  - per-output workspace numbers
  - configurable app launchers
  - clock -> flat calendar
  - SYS -> resource telemetry (sparklines + top processes)
  - power -> session actions with confirmation
- Scripts: `workspaces.sh`, `stats.sh`, `top.sh`, `battery.sh`
- Settings: Plugins -> Samurai Dock (`settings/SamuraiDockPage.qml`); the launcher list is editable there (label, glyph and command)
- `defaultEnabled` is false; enable it from the Plugins card.
