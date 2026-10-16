import QtQuick
import QtQuick.Layouts
import qs.core

// Cheatsheet settings (Plugins → Cheatsheet).
Item {
    id: page
    property var bar: null

    ColumnLayout {
        anchors.fill: parent; anchors.margins: Theme.gapLg; spacing: Theme.gapMd
        Text { text: "KEYBIND CHEATSHEET"; font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: 18; color: Theme.text }
        Text {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: "Every active keybind (core + plugins) in a searchable list, read live from hyprctl. The Keybinds plugin is the editor; this is the read-only cheat sheet. Open with `qs_manager.sh toggle cheatsheet`."
            font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0
        }
        Item { Layout.fillHeight: true }
    }
}
