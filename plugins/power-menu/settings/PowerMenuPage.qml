import QtQuick
import QtQuick.Layouts
import qs.core

// Power Menu settings (Plugins → Power Menu).
Item {
    id: page
    property var bar: null

    ColumnLayout {
        anchors.fill: parent; anchors.margins: Theme.gapLg; spacing: Theme.gapMd
        Text { text: "POWER MENU"; font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: 18; color: Theme.text }
        Text {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: "Session actions (lock, log out, suspend, reboot, shutdown) in a popup; destructive actions ask for a confirmation. Open with `qs_manager.sh toggle power`."
            font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0
        }
        Item { Layout.fillHeight: true }
    }
}
