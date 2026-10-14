# template — starting point for a plugin

1. Copy this folder and rename it to your plugin `id` (`plugin.json → id`).
2. Edit `plugin.json` (name, author, description, type; add `toggle` if the
   plugin reuses an existing settings switch, or `settingsTab` if it ships a
   settings page in the shell).
3. `hypr` / `mixed` plugins: write your binds and rules in `hypr.lua` using
   the injected SDK (`local mod = ...`). Extra files (scripts, assets) live
   next to it; `mod.script("name.sh")` resolves them.
4. Test it from the user dir:

   ```sh
   cp -r . ~/.config/hypr/plugins-user/<id>
   # enable in Settings → Plugins, then reload: hyprctl reload
   ```

5. Optional — your own settings menu: declare
   `"settings": { "page": "settings/Page.qml", "label": "My Plugin" }` in
   `plugin.json` and ship `settings/Page.qml` (a root `Item` with
   `property var bar`). It appears under Plugins with a Configure button.

The full contract is in `docs/plugins.md` (standard v0).
