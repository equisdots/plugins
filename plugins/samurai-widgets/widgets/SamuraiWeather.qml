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
    property real minHeight: 140
    property real maxWidth: 700
    property real maxHeight: 440
    property real minAspect: 1.0
    property real maxAspect: 3.0
    property bool isRound: false
    property bool windowShown: true

    readonly property string cacheDir: {
        let v = Quickshell.env("QS_CACHE_TIMEX");
        return (v !== "" && v !== undefined && v !== null) ? v : Quickshell.env("HOME") + "/.cache/quickshell/timex";
    }
    property var weatherData: null
    readonly property string tempText: {
        let t = root.weatherData && root.weatherData.current_temp;
        if (t === undefined || String(t).trim() === "") return "--°";
        let n = Math.round(Number(t));
        return isNaN(n) ? "--°" : n + "°";
    }
    readonly property string iconText: root.weatherData && root.weatherData.current_icon ? String(root.weatherData.current_icon) : "󰖐"
    readonly property string condition: {
        let f = root.weatherData && root.weatherData.forecast;
        return f && f.length > 0 && f[0] && f[0].desc ? String(f[0].desc) : "WEATHER";
    }
    property var hourly: []

    function parse(text) {
        let t = String(text || "").trim();
        if (t === "") return;
        try { root.weatherData = JSON.parse(t); } catch (e) { return; }
        let out = [];
        let f = root.weatherData && root.weatherData.forecast;
        if (f && f.length > 0 && f[0] && f[0].hourly) {
            for (let i = 0; i < Math.min(3, f[0].hourly.length); i++) out.push(f[0].hourly[i]);
        }
        root.hourly = out;
    }

    Process {
        id: reader
        command: ["bash", "-c", "cat '" + root.cacheDir + "/weather.json' 2>/dev/null || true"]
        stdout: StdioCollector { onStreamFinished: root.parse(this.text) }
    }

    Timer {
        interval: 150000
        running: root.windowShown
        repeat: true
        onTriggered: { reader.running = false; reader.running = true; }
    }
    Component.onCompleted: reader.running = true

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
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "WEATHER"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(8, Math.min(11, height * 0.06))
                font.weight: Font.Bold
                font.letterSpacing: 1.5
                color: Theme.text
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.condition.toUpperCase()
                font.family: Theme.fontFamily
                font.pixelSize: 8
                color: Theme.subtext0
                elide: Text.ElideRight
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.12) }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            Canvas {
                id: pixelCloud
                Layout.preferredWidth: Math.max(40, root.width * 0.15)
                Layout.preferredHeight: Math.max(28, root.height * 0.16)
                Layout.alignment: Qt.AlignBottom
                antialiasing: false
                onPaint: {
                    let ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    let rows = [
                        "000000000000",
                        "000011100000",
                        "000111111000",
                        "001111111100",
                        "011111111110",
                        "111111111111",
                        "011111111110"
                    ];
                    let cols = 12;
                    let cw = width / cols;
                    let ch = height / rows.length;
                    for (let y = 0; y < rows.length; y++) {
                        for (let x = 0; x < cols; x++) {
                            if (rows[y].charAt(x) !== "1")
                                continue;
                            ctx.fillStyle = (y === 4 && x === 9) ? "#ff453a" : "rgba(245,245,247,0.92)";
                            ctx.fillRect(Math.floor(x * cw), Math.floor(y * ch), Math.ceil(cw), Math.ceil(ch));
                        }
                    }
                }
            }
            Text {
                text: root.tempText
                font.family: Theme.fontFamily
                font.pixelSize: 34
                font.weight: Font.Black
                color: Theme.text
                Layout.alignment: Qt.AlignBottom
            }
            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            Repeater {
                model: root.hourly
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        Layout.fillWidth: true
                        text: modelData.time ? String(modelData.time).slice(0, 5) : ""
                        font.family: Theme.fontFamily
                        font.pixelSize: 8
                        color: Theme.subtext0
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.temp !== undefined ? Math.round(Number(modelData.temp)) + "°" : "--°"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Theme.text
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
