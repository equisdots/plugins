# screenshots — converted plugin

Screenshots (area / full / edit via satty) and screen recording (virtual
audio routing, gpu-screen-recorder), converted from the `hyprland` core into a
self-contained plugin under the standard in `docs/plugins.md`.

```
screenshots/
  plugin.json              manifest (type: mixed; defaultEnabled: true)
  hypr.lua                 the four Print binds (SDK: mod.bind / mod.script)
  scripts/
    screenshot.sh          entry point (the four binds call it)
    caching.sh             vendored: QS cache/state dirs (qs_ensure_cache)
  ui/
    ScreenshotOverlay.qml  the area-selection / recording UI (standalone
                           quickshell instance launched by the script)
  README.md
```

## Deploy contract (dots, F1)

- The **whole repo** goes to the shell tree at
  `~/.config/hypr/scripts/quickshell/ui/plugins/screenshots/` (UI face: the
  overlay is a standalone `quickshell -p` entry; its imports target the shell
  tree). `screenshot.sh` resolves the overlay at the deployed path first, then
  the current shell copy, then its sibling `ui/` for dev/staging.
- The **runtime subset** also goes to `~/.config/hypr/plugins/screenshots/`:
  `plugin.json`, `hypr.lua`, `scripts/` (the loader evaluates `hypr.lua` there;
  `mod.script()` resolves the scripts).

## Dependencies

`gpu-screen-recorder`, `grim`, `satty`, `wl-clipboard`, `pactl` (PipeWire),
`quickshell`, `zbarimg` (QR), `python3`, `notify-send` (libnotify). The
hyprland installer already installs them.

## Status

Staged in this repo while the feature still ships inside `hyprland`
(`keybinds.lua`) and `shell` (`ScreenshotOverlay.qml`). The cutover removes
those copies once `dots` learns the manifest-driven deploy (F1). Changes vs.
the original: overlay path resolution is plugin-aware; notification titles
lost their emoji; `caching.sh` is vendored unchanged.

## Enable

```sh
# pre-cutover: install it by hand (user plugin) ...
cp -r . ~/.config/hypr/plugins-user/screenshots
# ... then enable it:
#   Settings -> Plugins -> "Screenshots & Recording" (or, once F1 lands:
#   dots plugins enable screenshots)
```
