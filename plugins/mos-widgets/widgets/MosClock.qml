import QtQuick
import qs.core

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 180
    property real minHeight: 180
    property real maxWidth: 620
    property real maxHeight: 620
    property real minAspect: 0.8
    property real maxAspect: 1.25
    property bool isRound: false
    property bool windowShown: true

    property var now: new Date()
    readonly property real dialRadius: Math.min(width, height) * 0.39
    readonly property int hour: root.now.getHours() % 12
    readonly property int minute: root.now.getMinutes()
    readonly property int second: root.now.getSeconds()
    readonly property string dateLine: Qt.formatDate(root.now, "dddd d MMMM")

    Timer {
        interval: 1000
        running: root.windowShown
        repeat: true
        onTriggered: {
            root.now = new Date();
            dial.requestPaint();
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Math.min(width, height) * 0.22
        color: "#f5f5f7"
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.08)

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.85) }
                GradientStop { position: 1.0; color: Qt.rgba(0.92, 0.92, 0.95, 0.95) }
            }
        }
    }

    Canvas {
        id: dial
        anchors.fill: parent

        onPaint: {
            let ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            let cx = width / 2;
            let cy = height * 0.46;
            let r = Math.min(width, height) * 0.38;
            let tickOuter = r * 0.94;
            let tickInner = r * 0.84;

            ctx.strokeStyle = "rgba(0,0,0,0.18)";
            ctx.lineWidth = Math.max(1, r * 0.012);
            ctx.lineCap = "round";
            for (let i = 0; i < 60; i++) {
                let a = (i / 60) * Math.PI * 2 - Math.PI / 2;
                let outer = tickOuter;
                let inner = (i % 5 === 0) ? r * 0.78 : tickInner;
                if (i % 5 !== 0 && i % 1 !== 0) continue;
                ctx.beginPath();
                ctx.moveTo(cx + Math.cos(a) * inner, cy + Math.sin(a) * inner);
                ctx.lineTo(cx + Math.cos(a) * outer, cy + Math.sin(a) * outer);
                ctx.stroke();
            }

            ctx.strokeStyle = "rgba(0,0,0,0.14)";
            ctx.lineWidth = Math.max(1, r * 0.018);
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, Math.PI * 2);
            ctx.stroke();

            let hourAngle = ((root.hour + root.minute / 60) / 12) * Math.PI * 2 - Math.PI / 2;
            let minuteAngle = ((root.minute + root.second / 60) / 60) * Math.PI * 2 - Math.PI / 2;
            let secondAngle = (root.second / 60) * Math.PI * 2 - Math.PI / 2;

            ctx.strokeStyle = "#1d1d1f";
            ctx.lineWidth = Math.max(2, r * 0.055);
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(cx, cy);
            ctx.lineTo(cx + Math.cos(hourAngle) * r * 0.50, cy + Math.sin(hourAngle) * r * 0.50);
            ctx.stroke();

            ctx.lineWidth = Math.max(2, r * 0.035);
            ctx.beginPath();
            ctx.moveTo(cx, cy);
            ctx.lineTo(cx + Math.cos(minuteAngle) * r * 0.72, cy + Math.sin(minuteAngle) * r * 0.72);
            ctx.stroke();

            ctx.strokeStyle = "#ff453a";
            ctx.lineWidth = Math.max(1, r * 0.016);
            ctx.beginPath();
            ctx.moveTo(cx - Math.cos(secondAngle) * r * 0.12, cy - Math.sin(secondAngle) * r * 0.12);
            ctx.lineTo(cx + Math.cos(secondAngle) * r * 0.80, cy + Math.sin(secondAngle) * r * 0.80);
            ctx.stroke();

            ctx.fillStyle = "#ff453a";
            ctx.beginPath();
            ctx.arc(cx, cy, Math.max(2, r * 0.045), 0, Math.PI * 2);
            ctx.fill();
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(8, height * 0.045)
        text: root.dateLine
        font.family: Theme.fontFamily
        font.pixelSize: Math.max(9, Math.min(15, height * 0.045))
        font.weight: Font.Medium
        color: "#86868b"
        elide: Text.ElideRight
        width: parent.width * 0.8
        horizontalAlignment: Text.AlignHCenter
    }

    onWidthChanged: dial.requestPaint()
    onHeightChanged: dial.requestPaint()
    onNowChanged: dial.requestPaint()
}
