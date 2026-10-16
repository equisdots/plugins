import QtQuick
import QtQuick.Layouts
import qs.core

// XFetch Panel settings (Plugins → XFetch Panel).
Item {
    id: page
    property var bar: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text { text: "XFETCH PANEL"; font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: 18; color: Theme.text }
        Text {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: "An xfetch-style system fetch panel: system logo, key/value system info and the live palette strip. Open it with `qs_manager.sh toggle xfetch` (bind a key in the Keybinds editor) or from the launcher."
            font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0
        }
        Item { Layout.fillHeight: true }
    }
}
