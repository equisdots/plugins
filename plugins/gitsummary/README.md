# Git

Git repositories under $HOME: branch, dirty count and open-in-terminal.

```
gitsummary/
  plugin.json              manifest (type: shell; provides.panels.git)
  defaults.json            settings seed ("gitsummary")
  ui/
    GitSummary.qml         the panel: repo rows + open-in-terminal
  scripts/
    gitsummary.sh          repo lister (path|branch|dirty per line)
  settings/
    GitSummaryPage.qml     plugin settings page
  README.md
```

- Kind: **panel** (`provides.panels.git`), opened with `qs_manager.sh toggle git`.
- Size: 720 x 560 (1920x1080 base units).
- Value producer: `scripts/gitsummary.sh` — bounded `find` under `$HOME`
  (Documents, .config and a few common project roots, max depth 4, capped at
  `GITSUMMARY_MAX` repos), one line per repo `path|branch|dirty`.
- Click a row to open a terminal in the repository
  (`xdg-terminal-exec`, then `kitty`, then `foot`).

## Settings

`settings.json` -> `"gitsummary"`: `refreshMs`, `maxRepos`. Seeded from
`defaults.json`; the panel re-reads it live.

## Dependencies

`git` (required; the panel shows an empty list without it) and `find`.
