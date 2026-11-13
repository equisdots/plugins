# _template — starting point for a plugin

1. Copy this folder to `plugins/<id>/` (the folder name is your plugin `id`).
2. Edit `plugin.json` (name, author, description, type; add `toggle` if the
   plugin reuses an existing settings switch, or `settings` if it ships its
   own settings page — see step 5).
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

## License

This scaffold is **Apache-2.0** — see [LICENSE](LICENSE). When you copy it to
`plugins-user/<id>/` you may keep Apache-2.0 or replace it with your own
license; user plugins are separate works and may keep their own attribution.
The `plugins` hub and its bundled plugins are **AGPL-3.0-or-later**. Plugins
loaded by the shell are covered by the shell's plugin exception
(`equisdots/shell/PLUGIN-EXCEPTION.md`).
