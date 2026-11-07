import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 260
    property real minHeight: 140
    property real maxWidth: 900
    property real maxHeight: 440
    property real minAspect: 1.0
    property real maxAspect: 4.0
    property bool isRound: false
    property bool windowShown: true

    readonly property bool active: root.windowShown && root.visible && root.width > 0 && root.height > 0
    readonly property var metrics: [
        { label: "CPU", value: SysData.cpu, unit: "%", color: Theme.red },
        { label: "RAM", value: SysData.ramPercent, unit: "%", color: Theme.text },
        { label: "TEMP", value: SysData.temp, unit: "°", color: SysData.temp >= 80 ? Theme.red : Theme.subtext0 }
    ]

    onActiveChanged: {
        if (root.active) SysData.subscribe();
        else SysData.unsubscribe();
    }
    Component.onDestruction: SysData.unsubscribe()

    Rectangle {
        anchors.fill: parent
        radius: 2
        color: "#0a0a0b"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.16)
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
        color: Theme.red
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(12, Math.min(20, height * 0.12))
        spacing: Math.max(4, height * 0.035)

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "SYSTEM"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(8, Math.min(11, height * 0.06))
                font.weight: Font.Bold
                font.letterSpacing: 1.5
                color: Theme.text
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "LIVE"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(7, Math.min(9, height * 0.045))
                font.letterSpacing: 1.0
                color: Theme.green
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.12)
        }

        Repeater {
            model: root.metrics
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 8
                Text {
                    Layout.preferredWidth: 42
                    text: modelData.label
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.max(7, Math.min(10, height * 0.05))
                    font.letterSpacing: 1.0
                    color: Theme.subtext0
                }
                Item {
                    Layout.fillWidth: true
                    height: 3
                    Rectangle {
                        width: parent.width
                        height: parent.height
                        color: Qt.rgba(1, 1, 1, 0.10)
                    }
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, Number(modelData.value) / 100))
                        height: parent.height
                        color: modelData.color
                        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                    }
                }
                Text {
                    Layout.preferredWidth: 42
                    text: String(modelData.value) + modelData.unit
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.max(8, Math.min(11, height * 0.05))
                    font.weight: Font.Bold
                    color: Theme.text
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "NET"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(7, Math.min(9, height * 0.045))
                font.letterSpacing: 1.0
                color: Theme.subtext0
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "↓ " + (SysData.netRx / 1024).toFixed(1) + "   ↑ " + (SysData.netTx / 1024).toFixed(1) + " MB/s"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(7, Math.min(9, height * 0.045))
                color: Theme.subtext0
            }
        }
    }
}
