# World Clock (Widget)

Desktop widget: a second-timezone clock card (big HH:MM, date, tz label).

- Kind: **widget face** (`provides.widgets.faces.worldclock`, variant `card`)
- Face: `widgets/WorldclockCard.qml`
- Value producer: `scripts/worldclock.sh` (arg 1 = timezone, default `UTC`)
- Settings: `worldclock.tz` (default `UTC`), scope `worldclock`
- Default size: 300 x 180, refresh every 1 s

Self-contained: the face reads the timezone from the settings store and
runs the value producer each second. The script is the source of truth and
prints the time (line 1) then the date (line 2); the face follows the active
palette through `Theme` tokens.
