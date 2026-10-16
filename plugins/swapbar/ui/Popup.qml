// Swap popup — the Swap plugin's bar-module popup (equisdots plugin standard).
// Rooted on the core PluginPopup base: it self-positions from the plugin's own
// settings ("popupAnchor") and is opened by the bar module via
// `qs_manager.sh toggle swapbar`.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

PluginPopup {
    id: root
    pluginId: "swapbar"
    scopeName: "swapbar"
    title: "Swap"
    subtitle: "Swap usage"
    accent: Theme.color4
    popupWidth: 460
    popupHeight: 300

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/swapbar/scripts/swapbar.sh"

    property string value: ""
    readonly property int pct: {
        var n = parseInt(root.value);
        return isNaN(n) ? 0 : Math.max(0, Math.min(100, n));
    }
    function refresh() { reader.running = false; reader.running = true; }
    Process {
        id: reader
        command: ["bash", root.scriptPath]
        stdout: StdioCollector { onStreamFinished: root.value = (this.text || "").trim() }
    }
    Timer { interval: 10000; running: true; repeat: true; onTriggered: root.refresh() }

    Component.onCompleted: refresh()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text {
            text: root.value !== "" ? root.value + "%" : "…"
            font.family: "Hack Nerd Font"
            font.pixelSize: 52
            font.weight: Font.Black
            color: Theme.text
        }
        Rectangle {
            Layout.fillWidth: true
            height: s(10)
            radius: 5
            color: Theme.surfaceContainerHighest
            Rectangle {
                width: parent.width * (root.pct / 100)
                height: parent.height
                radius: 5
                color: Theme.color4
                Behavior on width { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.OutCubic } }
            }
        }
        Text {
            text: "Percentage of configured swap currently in use."
            font.family: "Hack Nerd Font"
            font.pixelSize: 11
            color: Theme.subtext0
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Item { Layout.fillHeight: true }
    }
}
