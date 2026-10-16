// Docker popup — the Docker plugin's bar-module popup (equisdots plugin
// standard). Rooted on the core PluginPopup base: it self-positions from the
// plugin's own settings ("popupAnchor") and is opened by the bar module via
// `qs_manager.sh toggle dockerbar`.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

PluginPopup {
    id: root
    pluginId: "dockerbar"
    scopeName: "dockerbar"
    title: "Docker"
    subtitle: "Running Docker containers"
    accent: Theme.color6
    popupWidth: 460
    popupHeight: 320

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/dockerbar/scripts/dockerbar.sh"

    // Same count producer as bar/Dockerbar.qml.
    property string value: ""
    // First running container names (list-type module).
    property var names: []

    function refresh() {
        reader.running = false; reader.running = true;
        lister.running = false; lister.running = true;
    }

    Process {
        id: reader
        command: ["bash", root.scriptPath]
        stdout: StdioCollector { onStreamFinished: root.value = (this.text || "").trim() }
    }
    Process {
        id: lister
        command: ["bash", "-c", "docker ps --format '{{.Names}}' 2>/dev/null | head -n 5"]
        stdout: StdioCollector {
            onStreamFinished: root.names = (this.text || "").split("\n")
                .map(function(l) { return l.trim(); })
                .filter(function(l) { return l.length > 0; })
        }
    }
    Timer { interval: 15000; running: true; repeat: true; onTriggered: root.refresh() }

    Component.onCompleted: refresh()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text {
            text: root.value
            font.family: "Hack Nerd Font"
            font.pixelSize: 52
            font.weight: Font.Black
            color: Theme.text
        }
        Text {
            text: "Running Docker containers reported by docker ps."
            font.family: "Hack Nerd Font"
            font.pixelSize: 11
            color: Theme.subtext0
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Column {
            Layout.fillWidth: true
            spacing: s(2)
            Repeater {
                model: root.names.length > 0 ? root.names : ["no containers running"]
                delegate: Text {
                    required property string modelData
                    width: parent.width
                    text: root.names.length > 0 ? "› " + modelData : "no containers running"
                    font.family: "Hack Nerd Font"
                    font.pixelSize: 11
                    color: Theme.subtext0
                    elide: Text.ElideRight
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
