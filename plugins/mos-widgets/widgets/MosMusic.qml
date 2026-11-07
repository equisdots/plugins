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
    property real minHeight: 100
    property real maxWidth: 780
    property real maxHeight: 340
    property real minAspect: 1.2
    property real maxAspect: 3.0
    property bool isRound: false
    property bool windowShown: true

    readonly property string musicDir: {
        let v = Quickshell.env("QS_RUN_MUSIC");
        if (v !== "" && v !== undefined && v !== null) return v;
        return (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell/music";
    }
    readonly property string musicPath: root.musicDir + "/music_info.json"
    property var musicData: null
    property string artSource: ""
    readonly property string title: root.musicData && root.musicData.title ? String(root.musicData.title) : "Not Playing"
    readonly property string artist: root.musicData && root.musicData.artist ? String(root.musicData.artist) : ""
    readonly property string state: root.musicData && root.musicData.status ? String(root.musicData.status) : "Stopped"
    readonly property bool playing: root.state === "Playing" || root.state === "Paused"
    readonly property real progress: {
        if (!root.musicData) return 0;
        let n = Number(root.musicData.percent);
        return isNaN(n) ? 0 : Math.max(0, Math.min(1, n / 100));
    }

    function readMusic(text) {
        let t = String(text || "").trim();
        if (t === "") return;
        try { root.musicData = JSON.parse(t); } catch (e) { return; }
        let art = root.musicData.artUrl ? String(root.musicData.artUrl) : "";
        root.artSource = (art !== "" && art.indexOf("placeholder_blank") === -1) ? art : "";
    }

    Process {
        id: reader
        command: ["bash", "-c", "cat '" + root.musicPath + "' 2>/dev/null || true"]
        stdout: StdioCollector { onStreamFinished: root.readMusic(this.text) }
    }

    Timer {
        interval: 2000
        running: root.windowShown
        repeat: true
        onTriggered: { reader.running = false; reader.running = true; }
    }

    Component.onCompleted: reader.running = true

    Rectangle {
        anchors.fill: parent
        radius: Math.min(width, height) * 0.14
        color: "#1c1c1e"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.10)
        clip: true

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0.32, 0.20, 0.52, 0.55) }
                GradientStop { position: 1.0; color: Qt.rgba(0.08, 0.08, 0.11, 0.90) }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Math.max(10, Math.min(18, width * 0.045))
        spacing: Math.max(10, Math.min(16, width * 0.035))

        Rectangle {
            Layout.preferredWidth: Math.min(parent.height, parent.height)
            Layout.fillHeight: true
            radius: Math.min(width, height) * 0.12
            color: Qt.rgba(1, 1, 1, 0.10)
            clip: true
            Image {
                anchors.fill: parent
                source: root.artSource
                visible: root.artSource !== ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                layer.enabled: true
                layer.smooth: true
            }
            Text {
                anchors.centerIn: parent
                visible: root.artSource === ""
                text: "󰝚"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(22, Math.min(42, height * 0.35))
                color: "rgba(255,255,255,0.65)"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: root.state === "Playing" ? "NOW PLAYING" : "MUSIC"
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.max(7, Math.min(10, height * 0.028))
                    font.letterSpacing: 1.2
                    color: "rgba(255,255,255,0.52)"
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.playing ? "●" : "○"
                    font.family: Theme.fontFamily
                    font.pixelSize: 8
                    color: root.state === "Playing" ? "#34c759" : "rgba(255,255,255,0.35)"
                }
            }
            Text {
                Layout.fillWidth: true
                text: root.title
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(11, Math.min(20, height * 0.095))
                font.weight: Font.Bold
                color: "#ffffff"
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: root.artist
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(8, Math.min(13, height * 0.06))
                color: "rgba(255,255,255,0.62)"
                elide: Text.ElideRight
            }
            Item { Layout.fillHeight: true }
            Rectangle {
                Layout.fillWidth: true
                height: 3
                radius: 2
                color: "rgba(255,255,255,0.16)"
                Rectangle {
                    width: parent.width * root.progress
                    height: parent.height
                    radius: parent.radius
                    color: "#ffffff"
                    Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: root.musicData && root.musicData.positionStr ? root.musicData.positionStr : "--:--"
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.max(7, Math.min(10, height * 0.03))
                    color: "rgba(255,255,255,0.45)"
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.musicData && root.musicData.lengthStr ? root.musicData.lengthStr : "--:--"
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.max(7, Math.min(10, height * 0.03))
                    color: "rgba(255,255,255,0.45)"
                }
            }
        }
    }
}
