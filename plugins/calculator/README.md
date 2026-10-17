# Calculator

Keypad calculator with `qalc` evaluation, a safe fallback evaluator and a
short history.

- Kind: **panel** (`provides.panels.calculator`, opened with
  `qs_manager.sh toggle calculator`)
- Value producer: `scripts/calculator.sh` (`qalc -t "<expr>"`, prints
  `__NO_QALC__` when qalc is missing)
- Settings: Plugins -> Calculator (`settings/CalculatorPage.qml`)

## Files

```
calculator/
  plugin.json                     manifest (type: shell; provides.panels.calculator)
  defaults.json                   settings seed
  ui/Calculator.qml               the panel: display, keypad, history
  scripts/calculator.sh           qalc-backed evaluator
  settings/CalculatorPage.qml     settings page
  README.md
```

## Behaviour

- Buttons `0-9 . + - * / ( )`, `=`, `C`, `+/-` and `%`.
- `=` evaluates through `scripts/calculator.sh`; if qalc is not installed the
  script returns `__NO_QALC__` and the panel uses its own recursive-descent
  evaluator, which only understands numbers and `+ - * / ( )` (never `eval`).
- `%` rewrites the trailing number `N` to `(N/100)`.
- The copy button pipes the current result (or expression) to `wl-copy`.
- History keeps the last `historyLimit` results; click a row to reload it.

Keyboard: digits/operators type, Enter computes, Backspace deletes, Escape
closes the panel.
