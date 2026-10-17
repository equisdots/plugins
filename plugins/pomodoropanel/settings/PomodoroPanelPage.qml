import QtQuick
import QtQuick.Layouts
import qs.core

// Pomodoro panel settings (Plugins -> Pomodoro). Describes the 25/5 session
// and the shared state file the panel writes for the bar module.
Item {
    id: page
    property var bar: null
    property var host: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text { text: "Pomodoro"; font.family: "Hack Nerd Font"; font.bold: true; font.pixelSize: 20; color: Theme.text }
        Text { text: "Pomodoro timer panel with 25 minute work and 5 minute break sessions. On finish it raises a notify-send notification."; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0; Layout.fillWidth: true; wrapMode: Text.WordWrap }

        Rectangle {
            Layout.fillWidth: true
            radius: Theme.radiusLg
            color: Theme.surfaceContainerLow
            border.width: 1; border.color: Theme.outlineVariant
            implicitHeight: inner.implicitHeight + Theme.gapLg * 2
            ColumnLayout {
                id: inner
                anchors.fill: parent; anchors.margins: Theme.gapLg; spacing: Theme.gapSm
                Text { text: "Durations"; font.family: "Hack Nerd Font"; font.pixelSize: 12; color: Theme.text }
                Text { text: "Work 25:00  -  Break 05:00"; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0 }
                Text { text: "State file: $XDG_RUNTIME_DIR/equisdots-pomodoro (epoch end time)"; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                Text { text: "Read by the Pomodoro bar module (provides.bar.modules.pomodoro)."; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
