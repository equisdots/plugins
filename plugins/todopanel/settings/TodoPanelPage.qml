import QtQuick
import QtQuick.Layouts
import qs.core

// Todo panel settings (Plugins -> Todo). Shows where tasks are stored and how
// the panel toggles / deletes them.
Item {
    id: page
    property var bar: null
    property var host: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text { text: "Todo"; font.family: "Hack Nerd Font"; font.bold: true; font.pixelSize: 20; color: Theme.text }
        Text { text: "Task list panel backed by ~/.local/share/equisdots/todo.txt (one task per line; a line starting with \"x \" is done)."; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0; Layout.fillWidth: true; wrapMode: Text.WordWrap }

        Rectangle {
            Layout.fillWidth: true
            radius: Theme.radiusLg
            color: Theme.surfaceContainerLow
            border.width: 1; border.color: Theme.outlineVariant
            implicitHeight: inner.implicitHeight + Theme.gapLg * 2
            ColumnLayout {
                id: inner
                anchors.fill: parent; anchors.margins: Theme.gapLg; spacing: Theme.gapSm
                Text { text: "Task file"; font.family: "Hack Nerd Font"; font.pixelSize: 12; color: Theme.text }
                Text { text: "~/.local/share/equisdots/todo.txt"; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0 }
                Text { text: "Open with: qs_manager.sh toggle todo"; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0 }
                Text { text: "Shared with the Todo bar module (provides.bar.modules.todobar)."; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
