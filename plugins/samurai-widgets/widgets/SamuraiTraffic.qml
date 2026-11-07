import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 260
    property real minHeight: 150
    property real maxWidth: 1000
    property real maxHeight: 480
    property real minAspect: 1.0
    property real maxAspect: 5.0
    property bool isRound: false
    property bool windowShown: true

    readonly property bool active: root.visible && root.windowShown
    property bool subscribed: false
    property var samples: []
    property real scaleMax: 1
    property string iface: "--"
    property int sampleCount: 24
    property real phase: 0

    // A low idle oscillation keeps every bar alive when the network is quiet;
    // real RX/TX traffic always wins over the idle baseline.
    function idleLevel(i, offset) {
        return 0.045 + 0.075 * (0.5 + 0.5 * Math.sin(root.phase * 1.7 + i * 0.72 + offset));
    }

    function barLevel(value, i, offset) {
        let actual = Math.max(0, Math.min(1, (Number(value) || 0) / Math.max(1, root.scaleMax)));
        return Math.max(actual, root.idleLevel(i, offset));
    }

    function syncData() {
        let want = root.active;
        if (want === root.subscribed)
            return;
        if (want) SysData.subscribe();
        else SysData.unsubscribe();
        root.subscribed = want;
    }

    function tick() {
        let rx = Math.max(0, Number(SysData.netRx) || 0);
        let tx = Math.max(0, Number(SysData.netTx) || 0);
        let next = root.samples.slice();
        next.push({ "rx": rx, "tx": tx });
        if (next.length > root.sampleCount)
            next = next.slice(next.length - root.sampleCount);
        root.samples = next;

        let peak = 1;
        for (let i = 0; i < next.length; i++)
            peak = Math.max(peak, next[i].rx, next[i].tx);
        root.scaleMax = Math.max(1, root.scaleMax * 0.80 + peak * 0.20);
        chart.requestPaint();
    }

    function fmt(v) {
        let n = Math.max(0, Number(v) || 0);
        if (n >= 1048576) return (n / 1048576).toFixed(1) + " MB/s";
        if (n >= 1024) return (n / 1024).toFixed(1) + " KB/s";
        return n.toFixed(0) + " B/s";
    }

    onActiveChanged: root.syncData()
    Component.onCompleted: {
        let seed = [];
        for (let i = 0; i < root.sampleCount; i++) seed.push({ "rx": 0, "tx": 0 });
        // Seed the scale with whatever SysData already knows so the first
        // preview does not sit at a misleading 1 B/s axis.
        let rx = Math.max(0, Number(SysData.netRx) || 0);
        let tx = Math.max(0, Number(SysData.netTx) || 0);
        seed[root.sampleCount - 1] = { "rx": rx, "tx": tx };
        root.samples = seed;
        root.scaleMax = Math.max(1, rx, tx);
        root.syncData();
        netInfo.running = true;
    }
    Component.onDestruction: if (root.subscribed) SysData.unsubscribe()

    Timer {
        interval: 2000
        running: root.active
        repeat: true
        onTriggered: root.tick()
    }

    Timer {
        interval: 60
        running: root.visible
        repeat: true
        onTriggered: {
            root.phase += 0.22;
            if (root.phase > 10000) root.phase = 0;
            chart.requestPaint();
        }
    }

    Timer {
        interval: 15000
        running: root.active
        repeat: true
        onTriggered: { netInfo.running = false; netInfo.running = true; }
    }

    Process {
        id: netInfo
        command: ["bash", "-c", "ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i==\"dev\") {print $(i+1); exit}}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let s = String(this.text || "").trim();
                root.iface = s !== "" ? s : "--";
            }
        }
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
                text: "NETWORK"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(8, Math.min(11, height * 0.06))
                font.weight: Font.Bold
                font.letterSpacing: 1.5
                color: Theme.text
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.iface.toUpperCase()
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(7, Math.min(9, height * 0.045))
                font.letterSpacing: 1.0
                color: Theme.subtext0
            }
            Text {
                text: "●"
                font.family: Theme.fontFamily
                font.pixelSize: 8
                color: Theme.green
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                text: "↓ " + root.fmt(SysData.netRx)
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(9, Math.min(13, height * 0.065))
                font.weight: Font.Bold
                color: Theme.text
            }
            Text {
                text: "↑ " + root.fmt(SysData.netTx)
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(9, Math.min(13, height * 0.065))
                font.weight: Font.Bold
                color: Theme.red
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "RX / TX  ·  24 SAMPLES"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(7, Math.min(9, height * 0.04))
                color: Theme.overlay0
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.12)
        }

        Canvas {
            id: chart
            Layout.fillWidth: true
            Layout.fillHeight: true
            antialiasing: true
            onPaint: {
                let ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                let left = 4;
                let right = 4;
                let top = 8;
                let bottom = 15;
                let gw = Math.max(1, width - left - right);
                let gh = Math.max(1, height - top - bottom);

                ctx.strokeStyle = "rgba(255,255,255,0.10)";
                ctx.lineWidth = 1;
                for (let i = 0; i <= 3; i++) {
                    let y = top + gh * i / 3;
                    ctx.beginPath();
                    ctx.moveTo(left, y);
                    ctx.lineTo(left + gw, y);
                    ctx.stroke();
                }

                let data = root.samples || [];
                if (data.length > 0) {
                    let group = gw / data.length;
                    let bar = Math.max(1, group * 0.28);
                    for (let i = 0; i < data.length; i++) {
                        let x = left + i * group + group * 0.5;
                        let hRx = Math.max(2, root.barLevel(data[i].rx, i, 0) * gh);
                        let hTx = Math.max(2, root.barLevel(data[i].tx, i, 2.1) * gh);
                        ctx.fillStyle = "rgba(245,245,247,0.82)";
                        ctx.fillRect(x - bar - 1, top + gh - hRx, bar, hRx);
                        ctx.fillStyle = "rgba(255,69,58,0.88)";
                        ctx.fillRect(x + 1, top + gh - hTx, bar, hTx);
                        ctx.fillStyle = "rgba(255,255,255,0.95)";
                        ctx.fillRect(x - bar - 1, top + gh - hRx, bar, 1);
                        ctx.fillStyle = "rgba(255,69,58,0.95)";
                        ctx.fillRect(x + 1, top + gh - hTx, bar, 1);
                    }
                }

                // Moving scanline adds a little life even on a quiet network.
                let scan = left + ((root.phase * 2.2) % gw);
                ctx.fillStyle = "rgba(255,69,58,0.14)";
                ctx.fillRect(scan, top, 1, gh);

                ctx.fillStyle = "rgba(255,255,255,0.34)";
                ctx.font = Math.max(7, Math.min(9, height * 0.06)) + "px sans-serif";
                ctx.fillText(root.fmt(root.scaleMax), left + 1, top + 7);
                ctx.fillText("0", left + 1, top + gh - 2);
                ctx.fillText("NOW", left + gw - 22, top + gh + 11);
            }
        }
    }

    onWidthChanged: chart.requestPaint()
    onHeightChanged: chart.requestPaint()
    onSamplesChanged: chart.requestPaint()
}
