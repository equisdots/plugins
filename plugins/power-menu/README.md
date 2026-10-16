# Power Menu

A session **power menu** popup: Lock, Log out, Suspend, Reboot, Shutdown.
Destructive actions ask for a confirmation before running.

- Kind: **panel** (`provides.panels.power`, 420x470)
- UI: `ui/PowerMenu.qml`
- Action runner: `scripts/power.sh` (`lock|logout|suspend|reboot|shutdown`)
- Settings: Plugins → Power Menu

Open with `qs_manager.sh toggle power`.
