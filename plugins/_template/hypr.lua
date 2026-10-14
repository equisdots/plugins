-- The loader evaluates this file with the SDK injected as `...`:
--   mod.id      plugin id (matches plugin.json)
--   mod.dir     this plugin's folder
--   mod.script  mod.script("name.sh") -> "<dir>/scripts/name.sh"
--   mod.exec    mod.exec("cmd") -> an exec dispatcher
--   mod.bind    hl.bind plus a recorded human label
--   mod.log     writes into plugins-report.json
local mod = ...

-- mod.bind("SUPER + SHIFT + K", mod.exec("notify-send 'hi from " .. mod.id .. "'"),
--          { label = "My Plugin: greet" })

mod.log("template loaded (nothing bound yet)")
