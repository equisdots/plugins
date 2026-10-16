import QtQuick
import QtQuick.Layouts
import qs.core

// Glyphs settings (Plugins -> Glyphs). Informational: the panel is pure QML and
// driven by ui/Glyphs.js; the only setting is the grid column count in
// ~/.config/hypr/plugins/emojipicker/settings.json (scope "emojipicker"),
// seeded by defaults.json.
Item {
    id: page
    property var bar: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text { text: "Glyphs"; font.family: "Hack Nerd Font"; font.bold: true; font.pixelSize: 20; color: Theme.text }
        Text {
            text: "Searchable Unicode glyph picker. Click a cell to copy the glyph with wl-copy."
            font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0
            Layout.fillWidth: true; wrapMode: Text.WordWrap
        }

        Rectangle {
            Layout.fillWidth: true
            radius: Theme.radiusLg
            color: Theme.surfaceContainerLow
            border.width: 1; border.color: Theme.outlineVariant
            implicitHeight: inner.implicitHeight + Theme.gapLg * 2

            ColumnLayout {
                id: inner
                anchors.fill: parent; anchors.margins: Theme.gapLg; spacing: Theme.gapSm
                Text { text: "Grid columns"; font.family: "Hack Nerd Font"; font.pixelSize: 12; color: Theme.text }
                Text {
                    text: "emojipicker.columns (6-14, default 10)"
                    font.family: "Hack Nerd Font"; font.pixelSize: 12; color: Theme.subtext0
                }
                Text { text: "→  ✓  ★  ⚙  ♥"; font.family: "Hack Nerd Font"; font.pixelSize: 18; color: Theme.mauve }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Data source: ui/Glyphs.js (a JS array of { g, tags }). Edit that file to extend the set."
            font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0
            wrapMode: Text.WordWrap
        }

        Item { Layout.fillHeight: true }
    }
}
