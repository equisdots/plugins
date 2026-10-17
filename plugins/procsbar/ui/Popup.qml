// Processes popup — the Processes plugin's bar-module popup (equisdots plugin
// standard). Rooted on the core PluginPopup base: it self-positions from the
// plugin's own settings ("popupAnchor") and is opened by the bar module via
// `qs_manager.sh toggle procsbar`.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

PluginPopup {
    id: popup
    pluginId: "procsbar"
    scopeName: "procsbar"
    title: "Processes"
    subtitle: "Running process count"
    accent: Theme.color2
    popupWidth: 460
    popupHeight: 300

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/procsbar/scripts/procsbar.sh"

    property string value: ""
    property var procs: []

    function refresh() {
        reader.running = false; reader.running = true;
        lister.running = false; lister.running = true;
    }

    Process {
        id: reader
        command: ["bash", popup.scriptPath]
        stdout: StdioCollector { onStreamFinished: popup.value = (this.text || "").trim() }
    }
    // Same source the value producer reads (`ps -e`): a short list of names.
    Process {
        id: lister
        command: ["bash", "-c", "ps -e -o comm= | sed '/^[[:space:]]*$/d' | head -n 5"]
        stdout: StdioCollector {
            onStreamFinished: popup.procs = (this.text || "").split("\n").filter(function (l) { return l.trim() !== "" })
        }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: popup.refresh() }

    Component.onCompleted: refresh()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text {
            text: popup.value !== "" ? popup.value : "—"
            font.family: "Hack Nerd Font"
            font.pixelSize: 48
            font.weight: Font.Black
            color: Theme.text
        }
        Text {
            text: "Live process count and the first names reported by `ps -e` (value producer: scripts/procsbar.sh)."
            font.family: "Hack Nerd Font"
            font.pixelSize: 11
            color: Theme.subtext0
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.gapXs
            Repeater {
                model: popup.procs
                delegate: Text {
                    required property string modelData
                    text: "• " + modelData
                    font.family: "Hack Nerd Font"
                    font.pixelSize: 12
                    color: Theme.subtext0
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
