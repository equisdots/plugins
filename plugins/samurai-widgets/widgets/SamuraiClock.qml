import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 240
    property real minHeight: 120
    property real maxWidth: 720
    property real maxHeight: 420
    property real minAspect: 1.2
    property real maxAspect: 3.0
    property bool isRound: false
    property bool windowShown: true

    property var now: new Date()
    readonly property string timeText: pad2(root.now.getHours()) + ":" + pad2(root.now.getMinutes())
    readonly property string secondText: pad2(root.now.getSeconds())
    readonly property string dateText: Qt.formatDate(root.now, "dddd, dd MMMM yyyy").toUpperCase()
    readonly property real secondProgress: root.now.getSeconds() / 60

    function pad2(n) { return (n < 10 ? "0" : "") + n; }

    Timer {
        interval: 1000
        running: root.windowShown
        repeat: true
        onTriggered: root.now = new Date()
    }

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
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "侍"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(15, Math.min(24, height * 0.14))
                color: Theme.text
            }
            Text {
                text: "S A M U R A I"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(7, Math.min(10, height * 0.055))
                font.letterSpacing: 1.5
                color: Theme.subtext0
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "●"
                font.family: Theme.fontFamily
                font.pixelSize: 8
                color: Theme.green
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Text {
                text: root.timeText
                font.family: Theme.fontFamily
                font.pixelSize: Math.min(root.height * 0.33, root.width * 0.13)
                font.weight: Font.Black
                color: Theme.text
                Layout.alignment: Qt.AlignBottom
            }
            Text {
                text: root.secondText
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(10, Math.min(15, root.height * 0.08))
                font.weight: Font.Bold
                color: Theme.red
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: Math.max(4, height * 0.06)
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.12)
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.dateText
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(7, Math.min(10, height * 0.052))
                font.letterSpacing: 1.0
                color: Theme.subtext0
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Item {
                width: Math.max(42, parent.width * 0.14)
                height: 2
                Rectangle {
                    width: parent.width * root.secondProgress
                    height: parent.height
                    color: Theme.red
                    Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
