# plugins — the concentration folder

Every plugin lives here, one folder per plugin, **folder name = the plugin
`id`** (`plugin.json → id`) — regardless of where it comes from:

| Origin | Example |
|---|---|
| converted from the equisdots stack | `screenshots/` |
| sample / fixture | `hello/` |
| community / third-party | contributions land here too |
| scaffold (not a plugin) | `_template/` |

Rules:

- Each folder is **self-contained**: `plugin.json` plus its payload
  (`hypr.lua`, `scripts/`, `ui/`, README).
- Directories starting with `_` are scaffolds, not plugins.
- Plugins that keep their own repo (like Nyx) are referenced from their repo;
  a copy lands here only when the plugin ships through this repo (see
  `docs/nyx.md` for the rationale).
- Graduation to a standalone repo is a copy of the folder — the manifest
  makes the deploy identical either way.
