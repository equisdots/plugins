# Todo (Widget)

Desktop widget: the open items of `~/.local/share/equisdots/todo.txt`.

- Kind: **widget face** (`provides.widgets.faces.todo`, variant `card`)
- Face: `widgets/TodoCard.qml`
- Value producer: `scripts/todo.sh` (prints the open lines)
- Settings: `todowidget.maxRows` (default `6`)
- Default size: 360 x 260, refresh every 10 s

Self-contained: the script is the source of truth (every non-empty line that
does not start with `x ` or `#`); the face shows a count header plus up to
`maxRows` rows (in file order). The face follows the active palette through
`Theme` tokens.
