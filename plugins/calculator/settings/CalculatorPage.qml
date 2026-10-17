import QtQuick
import QtQuick.Layouts
import qs.core

// Calculator settings (Plugins -> Calculator). Declares the panel and explains
// the evaluation backend; the panel itself owns history and the qalc fallback.
Item {
    id: page
    property var bar: null
    property var host: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text { text: "Calculator"; font.family: "Hack Nerd Font"; font.bold: true; font.pixelSize: 20; color: Theme.text }
        Text { text: "Keypad calculator panel. Evaluates with qalc when available and falls back to a safe + - * / evaluator."; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0; Layout.fillWidth: true; wrapMode: Text.WordWrap }

        Rectangle {
            Layout.fillWidth: true
            radius: Theme.radiusLg
            color: Theme.surfaceContainerLow
            border.width: 1; border.color: Theme.outlineVariant
            implicitHeight: inner.implicitHeight + Theme.gapLg * 2
            ColumnLayout {
                id: inner
                anchors.fill: parent; anchors.margins: Theme.gapLg; spacing: Theme.gapSm
                Text { text: "Panel"; font.family: "Hack Nerd Font"; font.pixelSize: 12; color: Theme.text }
                Text { text: "Open with: qs_manager.sh toggle calculator"; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0 }
                Text { text: "Copy uses wl-copy; history keeps the last few results."; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0 }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
