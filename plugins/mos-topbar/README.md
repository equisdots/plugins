# mos Topbar

A complete macOS 27 menu-bar-style top bar for Hyprland.

- Kind: **complete bar** (`provides.bar.provider`)
- Structure: Apple menu, app menu, File, Edit, Format, View, Window, Help
- Extras: Bluetooth, Wi-Fi, battery, Control Center, Spotlight and clock
- Real actions where the Linux stack supports them: close/fullscreen/float/
  center the active window, lock/sleep/log out, Wi-Fi via `nmcli`, Bluetooth via
  `bluetoothctl`, volume via `wpctl` and brightness via `brightnessctl`
- Menus visually follow macOS: compact white type, rounded translucent
  popovers, hover highlight and shortcuts
- Settings: Plugins -> mos Topbar (`settings/MosTopbarPage.qml`)
  - bar height (20-32 px), item spacing (0-14 px)
  - bar and menu opacity
  - show/hide app name, app menus and each menu-bar extra
  - clock seconds and battery percentage
- `defaultEnabled` is false. Disable the core bar after enabling this one.

The active app name is read from `hyprctl activewindow`; unsupported
app-specific commands are shown disabled, matching the macOS menu-bar behavior
of keeping unavailable commands visible.
