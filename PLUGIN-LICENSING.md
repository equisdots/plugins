# Plugin licensing

- The `plugins` hub and the plugins bundled in this repository are
  **AGPL-3.0-or-later**.
- The `plugins/_template/` scaffold is **Apache-2.0**. Copy it to
  `~/.config/hypr/plugins-user/<id>/` and keep Apache-2.0 or replace it with
  your own license.
- `plugin-api` and `plugin-sdk` are **Apache-2.0**: permissive contracts for
  plugin authors, with attribution/notice obligations.
- User-created and third-party plugins are separate works and may keep their
  own license and attribution; they do not need to be AGPL just to be loaded
  by the shell.
- Plugins that copy or modify hub code must comply with the AGPL.
- The shell grants an additional permission under AGPL section 7 for
  independent plugins; see `equisdots/shell/PLUGIN-EXCEPTION.md`.
