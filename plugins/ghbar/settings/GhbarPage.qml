import QtQuick
import QtQuick.Layouts
import qs.core

// GitHub settings (Plugins → GitHub). Minimal: shows the bar module glyph.
Item {
    id: page
    property var bar: null
    property var host: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text { text: "GitHub"; font.family: "Hack Nerd Font"; font.bold: true; font.pixelSize: 20; color: Theme.text }
        Text { text: "Unread GitHub notifications (gh CLI)"; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0; Layout.fillWidth: true; wrapMode: Text.WordWrap }

        Rectangle {
            Layout.fillWidth: true
            radius: Theme.radiusLg
            color: Theme.surfaceContainerLow
            border.width: 1; border.color: Theme.outlineVariant
            implicitHeight: inner.implicitHeight + Theme.gapLg * 2
            ColumnLayout {
                id: inner
                anchors.fill: parent; anchors.margins: Theme.gapLg; spacing: Theme.gapSm
                Text { text: "Glyph"; font.family: "Hack Nerd Font"; font.pixelSize: 12; color: Theme.text }
                Text { text: "󰊤"; font.family: "Hack Nerd Font"; font.pixelSize: 18; color: Theme.mauve }
            }
        }
        PluginPositionRow {
            host: page.host
            Layout.fillWidth: true
        }
        Item { Layout.fillHeight: true }
    }
}
