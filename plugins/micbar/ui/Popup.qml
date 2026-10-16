// Microphone popup — the Microphone plugin's bar-module popup (equisdots
// plugin standard). Rooted on the core PluginPopup base: it self-positions from
// the plugin's own settings ("popupAnchor") and is opened by the bar module via
// `qs_manager.sh toggle micbar`.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

PluginPopup {
    id: root
    pluginId: "micbar"
    scopeName: "micbar"
    title: "Microphone"
    subtitle: "Default source mute state"
    accent: Theme.color1
    popupWidth: 460
    popupHeight: 260

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/micbar/scripts/micbar.sh"

    // Same value producer as bar/Micbar.qml ("muted" / "on" / "n/a").
    property string value: ""

    function refresh() { reader.running = false; reader.running = true; }

    Process {
        id: reader
        command: ["bash", root.scriptPath]
        stdout: StdioCollector { onStreamFinished: root.value = (this.text || "").trim() }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: root.refresh() }

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
            text: "Default input (source) mute state reported by wpctl / pactl."
            font.family: "Hack Nerd Font"
            font.pixelSize: 11
            color: Theme.subtext0
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Item { Layout.fillHeight: true }
    }
}
