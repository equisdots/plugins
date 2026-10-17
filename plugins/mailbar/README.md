# Mail

Unread mail in the Maildir (mbsync/notmuch).

- Kind: **bar module** (`provides.bar.modules.mailbar`)
- Value producer: `scripts/mailbar.sh`
- Settings: Plugins → Mail (`settings/MailbarPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
