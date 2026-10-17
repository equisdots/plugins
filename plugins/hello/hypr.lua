-- hello — POC fixture for the equisdots plugin standard.
--
-- The loader evaluates this file with the SDK injected as `...`:
--   mod.id      plugin id ("hello")
--   mod.dir     the plugin's own folder
--   mod.script  mod.script("name.sh") -> "<dir>/scripts/name.sh"
--   mod.exec    mod.exec("cmd") -> an exec dispatcher
--   mod.bind    hl.bind plus a recorded human label
--   mod.log     writes into plugins-report.json
local mod = ...

-- Greet with a desktop notification (notify-send; any command works).
mod.bind("SUPER + SHIFT + H",
         mod.exec("notify-send -a hello 'Hello from a plugin' 'This bind came from ~/.config/hypr/plugins-user/hello/hypr.lua'"),
         { label = "Hello: greet" })

mod.log("hello loaded from " .. mod.dir)
