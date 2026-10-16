# Todo

Task list panel backed by `~/.local/share/equisdots/todo.txt` (add, toggle,
delete).

- Kind: **panel** (`provides.panels.todo`, opened with
  `qs_manager.sh toggle todo`)
- Value producer / writer: `scripts/todopanel.sh`
- Settings: Plugins -> Todo (`settings/TodoPanelPage.qml`)

## Files

```
todopanel/
  plugin.json                     manifest (type: shell; provides.panels.todo)
  defaults.json                   settings seed
  ui/TodoPanel.qml                the panel: add row, list, per-row trash
  scripts/todopanel.sh            list / add / toggle / delete
  settings/TodoPanelPage.qml      settings page
  README.md
```

## Storage

- File: `~/.local/share/equisdots/todo.txt`
- One task per physical line; a line starting with `x ` is done.
- `toggle`/`delete` address a task by its 1-based physical line number, which
  the `list` output reports as the first field, so the UI and the file never
  drift. Every mutation rewrites the file through a temp file + `mv` (atomic).
- The same file is read by the `todobar` bar module.

## Commands

```
todopanel.sh list             # <n>\t<0|1>\t<text> per task
todopanel.sh add <text...>
todopanel.sh toggle <n>
todopanel.sh delete <n>
```
