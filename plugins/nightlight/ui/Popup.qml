// Night Light popup — the Night Light plugin's bar-module popup (equisdots
// plugin standard). Rooted on the core PluginPopup base: it self-positions from
// the plugin's own settings ("popupAnchor") and is opened by the bar module via
// `qs_manager.sh toggle nightlight`.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

PluginPopup {
    id: popup
    pluginId: "nightlight"
    scopeName: "nightlight"
    title: "Night Light"
    subtitle: "Hyprsunset temperature or off"
    accent: Theme.color4
    popupWidth: 460
    popupHeight: 300

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/nightlight/scripts/nightlight.sh"

    property string value: ""
    function refresh() { reader.running = false; reader.running = true; }
    Process {
        id: reader
        command: ["bash", popup.scriptPath]
        stdout: StdioCollector { onStreamFinished: popup.value = (this.text || "").trim() }
    }
    Timer { interval: 10000; running: true; repeat: true; onTriggered: popup.refresh() }

    Component.onCompleted: refresh()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text {
            text: popup.value !== "" ? popup.value : "off"
            font.family: "Hack Nerd Font"
            font.pixelSize: 48
            font.weight: Font.Black
            color: popup.value === "on" ? Theme.text : Theme.subtext0
        }
        Text {
            text: "Hyprsunset active state via `pgrep hyprsunset` (value producer: scripts/nightlight.sh)."
            font.family: "Hack Nerd Font"
            font.pixelSize: 11
            color: Theme.subtext0
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Item { Layout.fillHeight: true }
    }
}
