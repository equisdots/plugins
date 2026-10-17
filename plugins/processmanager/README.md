# Processes

Top processes by CPU with per-row kill and live totals.

```
processmanager/
  plugin.json              manifest (type: shell; provides.panels.procman)
  defaults.json            settings seed ("processmanager")
  ui/
    ProcessManager.qml     the panel: process table + kill buttons
  scripts/
    processmanager.sh      ps top-by-CPU table
    kill.sh                terminate a PID (SIGTERM, then SIGKILL)
  settings/
    ProcessManagerPage.qml plugin settings page
  README.md
```

- Kind: **panel** (`provides.panels.procman`), opened with
  `qs_manager.sh toggle procman`.
- Size: 760 x 620 (1920x1080 base units).
- Value producer: `scripts/processmanager.sh` —
  `ps -eo pid,pcpu,pmem,comm --sort=-pcpu | head -n 41` (header + top 40). The
  panel sums the listed rows for the header CPU/RAM totals.
- Actions: per-row kill through `scripts/kill.sh <pid>` (guards invalid PIDs
  and PID 1), refresh button and a 2 s auto-refresh timer.

## Settings

`settings.json` -> `"processmanager"`: `refreshMs`, `limit`. Seeded from
`defaults.json`; the panel re-reads it live.

## Dependencies

`ps` (procps). No other tools required.
