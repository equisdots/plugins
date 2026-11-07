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
    property real maxWidth: 700
    property real maxHeight: 700
    property real minAspect: 0.7
    property real maxAspect: 1.4
    property bool isRound: false
    property bool windowShown: true

    readonly property string cacheDir: {
        let v = Quickshell.env("QS_CACHE_TIMEX");
        return (v !== "" && v !== undefined && v !== null)
            ? v : Quickshell.env("HOME") + "/.cache/quickshell/timex";
    }
    readonly property string weatherPath: root.cacheDir + "/weather.json"
    property var weatherData: null
    property string city: "LOCAL"

    readonly property string tempText: {
        if (!root.weatherData || root.weatherData.current_temp === undefined || String(root.weatherData.current_temp).trim() === "")
            return "--°";
        let n = Math.round(Number(root.weatherData.current_temp));
        return isNaN(n) ? "--°" : n + "°";
    }
    readonly property string iconText: (root.weatherData && root.weatherData.current_icon) ? String(root.weatherData.current_icon) : "󰖐"
    readonly property string condition: {
        let f = root.weatherData && root.weatherData.forecast;
        return (f && f.length > 0 && f[0] && f[0].desc) ? String(f[0].desc) : "Local weather";
    }
    readonly property color accent: {
        let h = root.weatherData && root.weatherData.current_hex ? String(root.weatherData.current_hex) : "";
        return h.length === 7 ? h : "#d9e8ff";
    }
    property var hourly: []

    function updateHourly() {
        let out = [];
        let f = root.weatherData && root.weatherData.forecast;
        if (f && f.length > 0 && f[0] && f[0].hourly) {
            for (let i = 0; i < Math.min(4, f[0].hourly.length); i++) out.push(f[0].hourly[i]);
        }
        root.hourly = out;
    }

    function readWeather(text) {
        let t = String(text || "").trim();
        if (t === "") return;
        try { root.weatherData = JSON.parse(t); } catch (e) { return; }
        root.updateHourly();
    }

    Process {
        id: reader
        command: ["bash", "-c", "cat '" + root.weatherPath + "' 2>/dev/null || true"]
        stdout: StdioCollector { onStreamFinished: root.readWeather(this.text) }
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
        radius: Math.min(width, height) * 0.16
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2f7cf6" }
            GradientStop { position: 0.55; color: "#1655c7" }
            GradientStop { position: 1.0; color: "#0d2d70" }
        }
        clip: true

        Rectangle {
            width: parent.width * 0.9
            height: width
            radius: width / 2
            x: parent.width * 0.32
            y: -parent.height * 0.3
            color: Qt.rgba(0.55, 0.8, 1, 0.16)
        }
        Rectangle {
            width: parent.width * 0.7
            height: width
            radius: width / 2
            x: -parent.width * 0.28
            y: parent.height * 0.62
            color: Qt.rgba(0.4, 0.7, 1, 0.12)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(14, Math.min(24, width * 0.075))
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.city
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(9, Math.min(12, height * 0.032))
                font.weight: Font.DemiBold
                font.letterSpacing: 1.3
                color: "rgba(255,255,255,0.72)"
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "NOW"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(8, Math.min(10, height * 0.027))
                color: "rgba(255,255,255,0.55)"
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Math.max(4, width * 0.02)

            Text {
                Layout.alignment: Qt.AlignBottom
                text: root.tempText
                font.family: Theme.fontFamily
                font.pixelSize: Math.min(parent.height * 0.52, width * 0.30)
                font.weight: Font.Light
                color: "#ffffff"
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: Math.max(4, height * 0.025)
                spacing: 0
                Text {
                    text: root.iconText
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.max(22, Math.min(38, height * 0.12))
                    color: "#ffffff"
                }
                Text {
                    text: root.condition
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.max(8, Math.min(12, height * 0.035))
                    color: "rgba(255,255,255,0.70)"
                    elide: Text.ElideRight
                    Layout.maximumWidth: width * 0.38
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "rgba(255,255,255,0.20)"
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(34, height * 0.16)
            spacing: 0
            Repeater {
                model: root.hourly
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        Layout.fillWidth: true
                        text: modelData.time ? String(modelData.time).slice(0, 5) : ""
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.max(7, Math.min(10, height * 0.028))
                        color: "rgba(255,255,255,0.58)"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.icon ? String(modelData.icon) : ""
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.max(13, Math.min(20, height * 0.06))
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.temp !== undefined ? Math.round(Number(modelData.temp)) + "°" : "--°"
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.max(9, Math.min(13, height * 0.038))
                        font.weight: Font.DemiBold
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
