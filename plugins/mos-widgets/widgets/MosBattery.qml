import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 160
    property real minHeight: 160
    property real maxWidth: 620
    property real maxHeight: 620
    property real minAspect: 0.75
    property real maxAspect: 1.3
    property bool isRound: false
    property bool windowShown: true

    property bool present: false
    property int capacity: 0
    property string status: ""
    readonly property bool charging: root.status === "Charging" || root.status === "Full"
    readonly property color accent: !root.present ? "#8e8e93" : (root.capacity <= 15 ? "#ff453a" : (root.capacity <= 35 ? "#ffd60a" : "#34c759"))

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
        radius: Math.min(width, height) * 0.20
        color: "#f5f5f7"
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.08)
    }

    Canvas {
        id: ring
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) * 0.56
        height: width

        onPaint: {
            let ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            let cx = width / 2;
            let cy = height / 2;
            let r = Math.min(width, height) * 0.42;
            let lw = Math.max(4, r * 0.14);
            ctx.lineWidth = lw;
            ctx.lineCap = "round";
            ctx.strokeStyle = "rgba(0,0,0,0.08)";
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, Math.PI * 2);
            ctx.stroke();
            if (root.present) {
                ctx.strokeStyle = root.accent;
                ctx.beginPath();
                ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0, Math.min(100, root.capacity)) / 100);
                ctx.stroke();
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 0
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.present ? String(root.capacity) + "%" : "AC"
            font.family: Theme.fontFamily
            font.pixelSize: Math.min(parent.width * 0.9, height * 0.22)
            font.weight: Font.Black
            color: "#1d1d1f"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.present ? root.status.toUpperCase() : "POWER ADAPTER"
            font.family: Theme.fontFamily
            font.pixelSize: Math.max(7, Math.min(10, height * 0.032))
            font.letterSpacing: 1.0
            color: "#86868b"
        }
    }

    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Math.max(10, height * 0.06)
        spacing: 5
        Text {
            text: root.charging ? "󰂄" : (root.present ? "󰁹" : "󰚥")
            font.family: Theme.fontFamily
            font.pixelSize: Math.max(12, Math.min(20, height * 0.07))
            color: "#86868b"
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "BATTERY"
            font.family: Theme.fontFamily
            font.pixelSize: Math.max(7, Math.min(10, height * 0.03))
            font.letterSpacing: 1.2
            color: "#86868b"
        }
    }

    onCapacityChanged: ring.requestPaint()
    onPresentChanged: ring.requestPaint()
    onWidthChanged: ring.requestPaint()
    onHeightChanged: ring.requestPaint()
}
