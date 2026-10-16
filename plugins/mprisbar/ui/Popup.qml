// Media popup — the Media plugin's bar-module popup (equisdots plugin
// standard). Rooted on the core PluginPopup base: it self-positions from the
// plugin's own settings ("popupAnchor") and is opened by the bar module via
// `qs_manager.sh toggle mprisbar`.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

PluginPopup {
    id: popup
    pluginId: "mprisbar"
    scopeName: "mprisbar"
    title: "Media"
    subtitle: "Now playing · playerctl"
    accent: Theme.color5
    popupWidth: 460
    popupHeight: 300

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/mprisbar/scripts/mprisbar.sh"

    property string value: ""
    function refresh() { reader.running = false; reader.running = true; }
    Process {
        id: reader
        command: ["bash", popup.scriptPath]
        stdout: StdioCollector { onStreamFinished: popup.value = (this.text || "").trim() }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: popup.refresh() }

    Component.onCompleted: refresh()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text {
            text: popup.value !== "" ? popup.value : "stopped"
            font.family: "Hack Nerd Font"
            font.pixelSize: 44
            font.weight: Font.Black
            color: Theme.text
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        Text {
            text: "Now-playing artist - title from playerctl (value producer: scripts/mprisbar.sh)."
            font.family: "Hack Nerd Font"
            font.pixelSize: 11
            color: Theme.subtext0
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Item { Layout.fillHeight: true }
    }
}
