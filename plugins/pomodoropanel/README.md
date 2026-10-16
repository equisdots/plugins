# Pomodoro

Pomodoro timer panel: 25/5 work-break sessions writing the shared state file.

- Kind: **panel** (`provides.panels.pomodoro`, opened with
  `qs_manager.sh toggle pomodoro`)
- Value producer / writer: `scripts/pomodoropanel.sh`
- Settings: Plugins -> Pomodoro (`settings/PomodoroPanelPage.qml`)

> Note: the plugin id is `pomodoropanel` (the empty panel name `pomodoro` is
> declared in `provides.panels.pomodoro` to match the bar module it drives).

## Files

```
pomodoropanel/
  plugin.json                     manifest (type: shell; provides.panels.pomodoro)
  defaults.json                   settings seed (work/break minutes)
  ui/PomodoroPanel.qml            the panel: ring, mm:ss, Start/Pause/Reset
  scripts/pomodoropanel.sh        start / pause / reset / status
  settings/PomodoroPanelPage.qml  settings page
  README.md
```

## Behaviour

- Work = 25 min, Break = 5 min. A thin `Theme.mauve` ring fills as the phase
  progresses; the centre shows `mm:ss` and the current phase.
- **Start** writes `end = now + seconds` to
  `$XDG_RUNTIME_DIR/equisdots-pomodoro`; **Pause** clears the file; **Reset**
  clears it and returns to a fresh 25:00 work session.
- On finish: a `notify-send` notification fires; after work the break starts
  automatically, after the break the timer stops on a fresh work session.
- The state file is the same one the `pomodoro` bar module reads, so the bar
  shows the countdown while the panel is closed.
- Pause keeps the remaining time in the panel only (the state file must stay a
  single epoch number for the bar module); a restored session always resumes a
  work phase.

## Commands

```
pomodoropanel.sh start <seconds>
pomodoropanel.sh pause
pomodoropanel.sh reset
pomodoropanel.sh status          # idle | done | <seconds left>
```
