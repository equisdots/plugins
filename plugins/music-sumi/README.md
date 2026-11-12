# Samurai Music (music-sumi)

A sumi-e ink desktop widget for the equisdots shell: paper card, open enso
around the cover, red seal, serif title, brush progress and a compact 10-band
ink EQ. It follows the active palette through `Theme` from `qs.core`, so it
works on dark and light palettes.

## Face

`music-sumi` / variant `sumi`. Default 420x220, responsive 240x120 to
900x420 (aspect 1.1 to 3.4). The EQ panel appears only when the widget is at
least 360x380, so the card stays complete without it at its default size and
never crowds the controls on short widgets.

## Data and controls

Reads `$XDG_RUNTIME_DIR/quickshell/music/music_info.json` (or the directory in
`QS_RUN_MUSIC`), refreshed every 2 s only while the widget window is shown.
The position advances locally while Playing.

- play/pause/previous/next/seek: `player_control.sh` (falls back to the
  player reported by the music JSON).
- EQ: `equalizer.sh` (`get`, `set_band`, `apply`, `preset`) with the same
  optimistic-update guard as the native music popup.
- No `Quickshell.Mpris` usage.

## Requirements

- The shell's music popup scripts at
  `~/.config/hypr/scripts/quickshell/ui/bar/popups/music/`.
- `playerctl` for the media player.
- `easyeffects` only when using the EQ.
- A CJK serif font for the ink typography (Noto Serif CJK JP is preferred;
  the system fallback is used otherwise).

Managed plugins may import `qs.core`; user-mode copies must provide their own
theme import.
