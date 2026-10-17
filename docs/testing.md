# Testing the experimental stack on a real session

> Cross-repo manual deploy for testing `branch/experimental` on a live
> Hyprland machine, **without touching the dots-managed clones** (they
> hard-reset to `main` on every `dots install/update`).
> Rollback is a plain `dots install` from main.

## 1. Get the experimental checkouts

```sh
EXP=~/equisdots-exp
mkdir -p "$EXP" && cd "$EXP"
for r in hyprland shell nyx dots plugins; do
    [ -d "$r" ] || git clone -b branch/experimental "https://github.com/equisdots/$r"
done
```

Do **not** run `$EXP/dots/dots install` or `update`: those operate on the
managed clones in `~/.local/share/equisdots` (which track `main`). The CLI
subcommands (`plugins`, `list`) are safe to run from the checkout.

## 2. Deploy (mirrors the dots convention)

```sh
HYPR=~/.config/hypr
QS="$HYPR/scripts/quickshell"

# hyprland config (Lua modules) + scripts
rsync -a --exclude 'docs/' --exclude '.git*' "$EXP/hyprland/config/hypr/" "$HYPR/"
rsync -a --exclude '.git*' "$EXP/hyprland/scripts/" "$HYPR/scripts/"
chmod +x "$HYPR/scripts"/*.sh

# shell (whole tree; dock/, ui/plugins/ and ui/timex/ survive)
rsync -a --delete --exclude '.git*' --exclude 'docs/' \
      --exclude 'dock/' --exclude 'ui/plugins/' --exclude 'ui/timex/' \
      "$EXP/shell/" "$QS/"
find "$QS" -name '*.sh' -exec chmod +x {} +

# nyx plugin UI (whole repo) + manifest registry
mkdir -p "$QS/ui/plugins/nyx" "$HYPR/plugins/nyx"
rsync -a --delete --exclude '.git*' --exclude 'docs/' "$EXP/nyx/" "$QS/ui/plugins/nyx/"
rm -rf "$QS/ui/nyx"
cp -f "$EXP/nyx/plugin.json" "$HYPR/plugins/nyx/"

# reload the shell
~/.config/hypr/scripts/reload.sh
```

## 3. Checklist

| # | Check | Expected |
|---|---|---|
| 1 | `ls $QS/ui/plugins/nyx/{host,catalog,settings,front}` | all present |
| 2 | `ls $QS/ui/Mascots.qml $QS/core/MascotsCatalog.qml` | both gone |
| 3 | `ls $HYPR/plugins/nyx/plugin.json` | present |
| 4 | Settings panel | new **Plugins** group: *Plugins* (manager) + *Nyx*; Mascots is no longer under Theme |
| 5 | Manager toggle on Nyx | writes `mascots.enabled` (same switch as the Nyx page) |
| 6 | Nyx page | every former Mascots option (lineup, island/notch, dock, watcher, profiles) |
| 7 | The island | renders exactly as before; the toggle hides/shows it live |
| 8 | Theme → Frame | option renamed "Hug host overlays" (legacy `frame.notchMascot` in settings.json still reads) |
| 9 | `hyprctl configerrors` | empty |
| 10 | `cat ~/.cache/equisdots/plugins-report.json` | one entry per known plugin (`hello` when installed in `plugins-user`) |
| 11 | `$EXP/dots/dots plugins` | lists `nyx` (+ `hello`) |

## 4. If something breaks, capture

```sh
# run the shell in a terminal and watch stderr
quickshell -p ~/.config/hypr/scripts/quickshell/Shell.qml
hyprctl configerrors
cat ~/.cache/equisdots/plugins-report.json
jq '.plugins, .mascots, .frame' ~/.config/hypr/settings.json
```

## 5. Rollback (back to main)

```sh
~/.local/bin/dots install
~/.config/hypr/scripts/reload.sh
```

The managed clones still track `main`; the reinstall overwrites every
experimental payload.
