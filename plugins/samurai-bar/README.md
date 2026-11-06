# Samurai Bar

Complete bar in the **Samurai design language**: monochrome canvas, flat
surfaces separated by 1px hairlines, monospace ALL-CAPS labels, dense and
content-fitting. Colour appears only to encode a status (critical CPU/temp/
battery), never as decoration.

- Kind: **complete plugin bar** (`provides.bar.provider`)
- Component: `bar/SamuraiBar.qml` (its own `PanelWindow` per screen)
- Widgets (all its own — nothing reused from the core bar): workspaces, clock +
  date, CPU, memory, temperature, network, battery
- Click the clock for a flat Samurai calendar popup; click any resource
  segment for a dense system telemetry panel (CPU, memory, thermal, network,
  storage, load, uptime, processes, swap, battery)
- The telemetry panel keeps 60-sample sparklines for CPU/RAM/temperature and
  lists the five busiest processes
- Value producers: `scripts/workspaces.sh`, `scripts/battery.sh` (+ the shared
  core `SysData` singleton for CPU/RAM/temp/net)
- Settings: Plugins → Samurai Bar (`settings/SamuraiBarPage.qml`)

Enable the plugin, then turn the **core bar** off (Settings → Bar → General) so
this one owns the screen edge. `defaultEnabled` is false — it is opt-in.
