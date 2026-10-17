# Pomodoro

Pomodoro timer remaining time (state file driven).

- Kind: **bar module** (`provides.bar.modules.pomodoro`)
- Value producer: `scripts/pomodoro.sh`
- Settings: Plugins → Pomodoro (`settings/PomodoroPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
