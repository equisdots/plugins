# Torrents

Active torrent downloads (transmission remote).

- Kind: **bar module** (`provides.bar.modules.torrentbar`)
- Value producer: `scripts/torrentbar.sh`
- Settings: Plugins → Torrents (`settings/TorrentbarPage.qml`)

Self-contained: the value producer is the source of truth; the module
shows a glyph + the produced value and follows the active palette.
