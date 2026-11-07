import QtQuick
import QtQuick.Layouts
import qs.core

// Centered Cartesian plane: X = CPU load, Y = RAM load.
// The axes cross in the middle; the live point and its fading trail move as
// the machine usage changes. Coordinates are normalized around 50% so the
// plane uses all four quadrants instead of only the top-right corner.
Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 260
    property real minHeight: 160
    property real maxWidth: 1000
    property real maxHeight: 520
    property real minAspect: 1.0
    property real maxAspect: 5.0
    property bool isRound: false
    property bool windowShown: true

    readonly property bool active: root.visible && root.windowShown
    property bool subscribed: false
    property var trail: []
    readonly property real xNorm: Math.max(-1, Math.min(1, (Number(SysData.cpu) - 50) / 50))
    readonly property real yNorm: Math.max(-1, Math.min(1, (Number(SysData.ramPercent) - 50) / 50))
    readonly property int cpu: Math.round(Number(SysData.cpu) || 0)
    readonly property int ram: Math.round(Number(SysData.ramPercent) || 0)

    function syncData() {
        let want = root.active;
        if (want === root.subscribed)
            return;
        if (want) SysData.subscribe();
        else SysData.unsubscribe();
        root.subscribed = want;
    }

    function point() {
        return { "x": root.xNorm, "y": root.yNorm };
    }

    function tick() {
        let next = root.trail.slice();
        next.push(root.point());
        if (next.length > 42)
            next = next.slice(next.length - 42);
        root.trail = next;
        plane.requestPaint();
    }

    onActiveChanged: root.syncData()
    Component.onCompleted: {
        root.trail = [root.point()];
        root.syncData();
    }
    Component.onDestruction: if (root.subscribed) SysData.unsubscribe()

    Timer {
        interval: 2000
        running: root.active
        repeat: true
        onTriggered: root.tick()
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
        anchors.margins: Math.max(12, Math.min(20, height * 0.10))
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "SIGNAL"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(8, Math.min(11, root.height * 0.06))
                font.weight: Font.Bold
                font.letterSpacing: 1.5
                color: Theme.text
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "CARTESIAN  ·  CPU × RAM"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(7, Math.min(9, root.height * 0.045))
                font.weight: Font.Bold
                font.letterSpacing: 1.0
                color: Theme.subtext0
            }
            Text {
                text: "●"
                font.family: Theme.fontFamily
                font.pixelSize: 8
                color: Theme.red
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            Text {
                text: "X  " + root.cpu + "%"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(9, Math.min(12, root.height * 0.06))
                font.weight: Font.Bold
                color: Theme.text
            }
            Text {
                text: "Y  " + root.ram + "%"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(9, Math.min(12, root.height * 0.06))
                font.weight: Font.Bold
                color: Theme.text
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "(" + root.xNorm.toFixed(2) + ", " + root.yNorm.toFixed(2) + ")"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(8, Math.min(10, root.height * 0.05))
                color: Theme.red
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.12)
        }

        Canvas {
            id: plane
            Layout.fillWidth: true
            Layout.fillHeight: true
            antialiasing: true
            onPaint: {
                let ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                let left = 24;
                let right = 10;
                let top = 10;
                let bottom = 22;
                let gw = Math.max(1, width - left - right);
                let gh = Math.max(1, height - top - bottom);
                let cx = left + gw / 2;
                let cy = top + gh / 2;

                // Quadrant grid
                ctx.strokeStyle = "rgba(255,255,255,0.08)";
                ctx.lineWidth = 1;
                for (let i = -2; i <= 2; i++) {
                    let x = cx + (gw / 2) * i / 2;
                    let y = cy + (gh / 2) * i / 2;
                    ctx.beginPath();
                    ctx.moveTo(x, top);
                    ctx.lineTo(x, top + gh);
                    ctx.stroke();
                    ctx.beginPath();
                    ctx.moveTo(left, y);
                    ctx.lineTo(left + gw, y);
                    ctx.stroke();
                }

                // Centered axes
                ctx.strokeStyle = "rgba(255,255,255,0.42)";
                ctx.lineWidth = 1.2;
                ctx.beginPath();
                ctx.moveTo(left, cy);
                ctx.lineTo(left + gw, cy);
                ctx.moveTo(cx, top);
                ctx.lineTo(cx, top + gh);
                ctx.stroke();

                // Tick marks
                ctx.strokeStyle = "rgba(255,255,255,0.30)";
                ctx.lineWidth = 1;
                for (let i = -2; i <= 2; i++) {
                    if (i === 0) continue;
                    let x = cx + (gw / 2) * i / 2;
                    let y = cy + (gh / 2) * i / 2;
                    ctx.beginPath();
                    ctx.moveTo(x, cy - 3);
                    ctx.lineTo(x, cy + 3);
                    ctx.moveTo(cx - 3, y);
                    ctx.lineTo(cx + 3, y);
                    ctx.stroke();
                }

                // Trail: recent CPU/RAM coordinates fade toward the present
                let points = root.trail || [];
                for (let i = 1; i < points.length; i++) {
                    let a = points[i - 1];
                    let b = points[i];
                    let alpha = 0.06 + (i / Math.max(1, points.length - 1)) * 0.28;
                    ctx.strokeStyle = "rgba(255,69,58," + alpha.toFixed(3) + ")";
                    ctx.lineWidth = 1.2;
                    ctx.beginPath();
                    ctx.moveTo(cx + a.x * gw / 2, cy - a.y * gh / 2);
                    ctx.lineTo(cx + b.x * gw / 2, cy - b.y * gh / 2);
                    ctx.stroke();
                }

                // Current coordinate
                let px = cx + root.xNorm * gw / 2;
                let py = cy - root.yNorm * gh / 2;
                ctx.strokeStyle = "rgba(255,69,58,0.34)";
                ctx.setLineDash([3, 4]);
                ctx.beginPath();
                ctx.moveTo(px, cy);
                ctx.lineTo(px, py);
                ctx.lineTo(cx, py);
                ctx.stroke();
                ctx.setLineDash([]);

                ctx.fillStyle = "#ff453a";
                ctx.beginPath();
                ctx.arc(px, py, 4, 0, Math.PI * 2);
                ctx.fill();
                ctx.strokeStyle = "rgba(255,255,255,0.85)";
                ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.arc(px, py, 7, 0, Math.PI * 2);
                ctx.stroke();

                // Axis labels
                ctx.fillStyle = "rgba(245,245,247,0.65)";
                ctx.font = Math.max(8, Math.min(10, height * 0.07)) + "px sans-serif";
                ctx.fillText("CPU →", left + gw - 42, cy - 7);
                ctx.save();
                ctx.translate(cx - 7, top + 8);
                ctx.rotate(-Math.PI / 2);
                ctx.fillText("RAM →", 0, 0);
                ctx.restore();
                ctx.fillStyle = "rgba(255,255,255,0.30)";
                ctx.font = Math.max(7, Math.min(9, height * 0.06)) + "px sans-serif";
                ctx.fillText("-1", left, cy + 13);
                ctx.fillText("0", cx + 4, cy + 13);
                ctx.fillText("+1", left + gw - 14, cy + 13);
            }
        }
    }

    onWidthChanged: plane.requestPaint()
    onHeightChanged: plane.requestPaint()
    onTrailChanged: plane.requestPaint()
}
