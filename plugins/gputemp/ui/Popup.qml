// GPU popup — the GPU plugin's bar-module popup (equisdots plugin standard).
// Rooted on the core PluginPopup base: it self-positions from the plugin's own
// settings ("popupAnchor") and is opened by the bar module via
// `qs_manager.sh toggle gputemp`.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

PluginPopup {
    id: root
    pluginId: "gputemp"
    scopeName: "gputemp"
    title: "GPU"
    subtitle: "Utilisation / temperature"
    accent: Theme.color1
    popupWidth: 460
    popupHeight: 300

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/gputemp/scripts/gputemp.sh"

    property string value: ""
    function refresh() { reader.running = false; reader.running = true; }
    Process {
        id: reader
        command: ["bash", root.scriptPath]
        stdout: StdioCollector { onStreamFinished: root.value = (this.text || "").trim() }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: root.refresh() }

    Component.onCompleted: refresh()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text {
            text: root.value !== "" ? root.value : "…"
            font.family: "Hack Nerd Font"
            font.pixelSize: 48
            font.weight: Font.Black
            color: Theme.text
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Text {
            text: "GPU utilisation and temperature (nvidia-smi, falling back to lm-sensors)."
            font.family: "Hack Nerd Font"
            font.pixelSize: 11
            color: Theme.subtext0
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Item { Layout.fillHeight: true }
    }
}
