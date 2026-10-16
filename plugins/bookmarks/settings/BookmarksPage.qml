import QtQuick
import QtQuick.Layouts
import qs.core

// Bookmarks panel settings (Plugins -> Bookmarks). Shows where quick links are
// stored. Links are edited from the panel's Add row, not here.
Item {
    id: page
    property var bar: null
    property var host: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text { text: "Bookmarks"; font.family: "Hack Nerd Font"; font.bold: true; font.pixelSize: 20; color: Theme.text }
        Text { text: "Quick links panel. Open a link with xdg-open; append new ones from the panel's Add row."; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0; Layout.fillWidth: true; wrapMode: Text.WordWrap }

        Rectangle {
            Layout.fillWidth: true
            radius: Theme.radiusLg
            color: Theme.surfaceContainerLow
            border.width: 1; border.color: Theme.outlineVariant
            implicitHeight: inner.implicitHeight + Theme.gapLg * 2
            ColumnLayout {
                id: inner
                anchors.fill: parent; anchors.margins: Theme.gapLg; spacing: Theme.gapSm
                Text { text: "Storage"; font.family: "Hack Nerd Font"; font.pixelSize: 12; color: Theme.text }
                Text { text: "~/.config/hypr/plugins/bookmarks/settings.json"; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                Text { text: "Scope: bookmarks - Key: links (array of { label, url })"; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                Text { text: "Open with: qs_manager.sh toggle bookmarks"; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0 }
                Text { text: "Seeded from defaults.json by the plugin installer."; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0 }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
