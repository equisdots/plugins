import QtQuick
import QtQuick.Layouts
import qs.core

// XFetch Themes settings (Plugins → XFetch Themes).
Item {
    id: page
    property var bar: null

    ColumnLayout {
        anchors.fill: parent; anchors.margins: Theme.gapLg; spacing: Theme.gapMd
        Text { text: "XFETCH THEMES"; font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: 18; color: Theme.text }
        Text {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: "Browse and apply the terminal xfetch themes. theme-sync generates one per palette in ~/.config/xfetch/themes; this panel lets you pick the active one without leaving the shell."
            font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0
        }
        Item { Layout.fillHeight: true }
    }
}
