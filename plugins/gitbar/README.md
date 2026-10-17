# Git Bar

Current git branch and dirty-file count for the focused repo.

- Kind: **bar module** (`provides.bar.modules.gitbar`)
- Value producer: `scripts/gitbar.sh`
- Settings: Plugins → Git Bar (`settings/GitbarPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
