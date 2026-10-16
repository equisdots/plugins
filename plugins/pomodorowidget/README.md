# Pomodoro (Widget)

Desktop widget: the pomodoro remaining time, state-file driven.

- Kind: **widget face** (`provides.widgets.faces.pomodoro`, variant `card`)
- Face: `widgets/PomodoroCard.qml`
- Value producer: `scripts/pomodoro.sh` (prints `<seconds> <state>`)
- Default size: 320 x 220, refresh every 1 s

Self-contained: the script is the source of truth — it reads the epoch end
from `$XDG_RUNTIME_DIR/equisdots-pomodoro`, prints the remaining seconds and
a state word (`focus` while running, `idle` otherwise). The face renders a big
mm:ss plus a Focus/Idle label and follows the active palette through `Theme`
tokens.
