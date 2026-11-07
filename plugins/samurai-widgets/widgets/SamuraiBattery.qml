import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 220
    property real minHeight: 120
    property real maxWidth: 700
    property real maxHeight: 360
    property real minAspect: 1.2
    property real maxAspect: 3.2
    property bool isRound: false
    property bool windowShown: true

    property bool present: false
    property int capacity: 0
    property string status: ""
    readonly property bool charging: root.status === "Charging" || root.status === "Full"

    function refresh() { reader.running = false; reader.running = true; }

    Process {
        id: reader
        command: ["bash", "-c", "p=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1); if [ -n \"$p\" ]; then echo \"$(cat $p/capacity 2>/dev/null)|$(cat $p/status 2>/dev/null)\"; else echo \"|none\"; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = (this.text || "").trim().split("|");
                root.capacity = parseInt(p[0]) || 0;
                root.status = p[1] || "";
                root.present = root.status !== "none" && root.capacity > 0;
            }
        }
    }
    Timer {
        interval: 5000
        running: root.windowShown
        repeat: true
        onTriggered: root.refresh()
    }
    Component.onCompleted: root.refresh()

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
        spacing: 4
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "BATTERY"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(8, Math.min(11, height * 0.06))
                font.weight: Font.Bold
                font.letterSpacing: 1.5
                color: Theme.text
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.present ? root.status.toUpperCase() : "AC POWER"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(7, Math.min(9, height * 0.045))
                color: Theme.subtext0
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.12) }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Text {
                text: root.present ? String(root.capacity) + "%" : "AC"
                font.family: Theme.fontFamily
                font.pixelSize: Math.min(root.height * 0.35, root.width * 0.16)
                font.weight: Font.Black
                color: Theme.text
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.charging ? "󰂄" : (root.present ? "󰁹" : "󰚥")
                font.family: Theme.fontFamily
                font.pixelSize: Math.min(root.height * 0.22, root.width * 0.11)
                color: root.capacity <= 15 && root.present ? Theme.red : Theme.subtext0
            }
        }
        Item {
            Layout.fillWidth: true
            height: 5
            Rectangle { anchors.fill: parent; color: Qt.rgba(1, 1, 1, 0.12) }
            Rectangle {
                width: parent.width * (root.present ? Math.max(0, Math.min(1, root.capacity / 100)) : 1)
                height: parent.height
                color: root.capacity <= 15 && root.present ? Theme.red : Theme.text
                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            }
        }
    }
}
