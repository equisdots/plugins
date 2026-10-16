import QtQuick
import QtQuick.Layouts
import qs.core

// Samurai Bar settings (Plugins → Samurai Bar). The bar is a complete plugin
// bar; enable it here (master switch) and disable the core bar in the Bar group
// so this one owns the screen edge.
Item {
    id: page
    property var bar: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text { text: "SAMURAI BAR"; font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: 18; color: Theme.text }
        Text {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: "A complete bar in the Samurai design language: monochrome, flat, typographic and dense, with its own widgets. Toggle it on here (Plugins card) and turn the core bar off in the Bar group so it owns the edge."
            font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0
        }

        Rectangle {
            Layout.fillWidth: true; radius: Theme.radiusLg
            color: Theme.surfaceContainerLow; border.width: 1; border.color: Theme.outlineVariant
            implicitHeight: inner.implicitHeight + Theme.gapLg * 2
            ColumnLayout {
                id: inner
                anchors.fill: parent; anchors.margins: Theme.gapLg; spacing: Theme.gapSm
                Repeater {
                    model: ["Workspaces", "Clock + date", "CPU", "Memory", "Temperature", "Network", "Battery"]
                    delegate: Text { required property var modelData; text: "· " + modelData; font.family: "Hack Nerd Font"; font.pixelSize: 12; color: Theme.text }
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
