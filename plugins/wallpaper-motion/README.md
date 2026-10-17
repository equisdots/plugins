# Wallpaper Motion

Frame rate of the **animated wallpaper** (the `xwww` scene davincix runs),
controllable live from the bar without adding options to davincix.

- **Island** `󰈆 N fps` — the live rate of the running scene (`static` when no
  scene is active). Click opens the popup.
- **Popup** — presets `15 / 24 / 30 / 45 / 60 fps`. Applying relaunches the
  running scene with the same argv but a new `--fps`, so palette, transition,
  outputs and timeout are preserved.
- **Sticky** — the plugin's `host` watches the scene; whenever a new scene
  starts (e.g. you apply another wallpaper in the picker) it re-applies the
  chosen rate.
- **Settings** (`Plugins → Configure`) — the rate + the popup position.

## Why this does not touch davincix

`davincix` already launches scenes with `--fps ${DAVINCIX_SCENE_FPS:-15}`
(`davincix/apply.sh`). This plugin does not add a davincix option: it reads the
live scene process argv, swaps the `--fps` value and relaunches the exact same
command. davincix keeps owning "which wallpaper"; this plugin only owns "how
smooth it moves".

## Notes

- `xwww` runs scenes at **15 fps** by default. Higher values cost GPU/CPU.
- Static images and videos are not affected (no scene process, or mpvpaper).
