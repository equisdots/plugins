// World Clock popup — the World Clock plugin's bar-module popup (equisdots
// plugin standard). Rooted on the core PluginPopup base: it self-positions from
// the plugin's own settings ("popupAnchor") and is opened by the bar module via
// `qs_manager.sh toggle worldclock`.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

PluginPopup {
    id: popup
    pluginId: "worldclock"
    scopeName: "worldclock"
    title: "World Clock"
    subtitle: "Time in a second timezone (UTC by default)"
    accent: Theme.color6
    popupWidth: 460
    popupHeight: 300

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/worldclock/scripts/worldclock.sh"

    property string value: ""
    function refresh() { reader.running = false; reader.running = true; }
    Process {
        id: reader
        command: ["bash", popup.scriptPath]
        stdout: StdioCollector { onStreamFinished: popup.value = (this.text || "").trim() }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: popup.refresh() }

    Component.onCompleted: refresh()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text {
            text: popup.value !== "" ? popup.value : "—:—"
            font.family: "Hack Nerd Font"
            font.pixelSize: 52
            font.weight: Font.Black
            color: Theme.text
        }
        Text {
            text: "Second-timezone clock (value producer: scripts/worldclock.sh · TZ via WORLDCLOCK_TZ)."
            font.family: "Hack Nerd Font"
            font.pixelSize: 11
            color: Theme.subtext0
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Item { Layout.fillHeight: true }
    }
}
