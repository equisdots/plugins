# Disks

Filesystem usage: mountpoint, used/total and a threshold-coloured bar.

```
diskusage/
  plugin.json             manifest (type: shell; provides.panels.df)
  defaults.json           settings seed ("diskusage")
  ui/
    DiskUsage.qml         the panel: one row per filesystem
  scripts/
    diskusage.sh          `df -P -h` filtered to real filesystems
  settings/
    DiskUsagePage.qml     plugin settings page
  README.md
```

- Kind: **panel** (`provides.panels.df`), opened with `qs_manager.sh toggle df`.
- Size: 700 x 540 (1920x1080 base units).
- Value producer: `scripts/diskusage.sh` — `df -P -h`, skipping tmpfs, overlay,
  devtmpfs, squashfs and the other kernel pseudo filesystems; one line per
  filesystem `mount|used|size|use%|fs`.
- Each row shows the mountpoint, `used / total` and a bar with the use%.
  Colour threshold: below 70 % green, below 90 % yellow, otherwise red
  (`Theme.green` / `Theme.yellow` / `Theme.red`).

## Settings

`settings.json` -> `"diskusage"`: `refreshMs`. Seeded from `defaults.json`;
the panel re-reads it live.

## Dependencies

`df` (coreutils). No other tools required.
