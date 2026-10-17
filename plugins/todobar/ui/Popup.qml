// Todo popup — the Todo plugin's bar-module popup (equisdots plugin
// standard). Rooted on the core PluginPopup base: it self-positions from the
// plugin's own settings ("popupAnchor") and is opened by the bar module via
// `qs_manager.sh toggle todobar`.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

PluginPopup {
    id: popup
    pluginId: "todobar"
    scopeName: "todobar"
    title: "Todo"
    subtitle: "Open items · quicknotes todo file"
    accent: Theme.color2
    popupWidth: 460
    popupHeight: 300

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/todobar/scripts/todobar.sh"

    property string value: ""
    property string listText: ""

    function refresh() {
        reader.running = false; reader.running = true;
        lister.running = false; lister.running = true;
    }
    Process {
        id: reader
        command: ["bash", popup.scriptPath]
        stdout: StdioCollector { onStreamFinished: popup.value = (this.text || "").trim() }
    }
    Process {
        id: lister
        command: ["bash", "-c", "f=\"$HOME/.local/share/equisdots/todo.txt\"; [ -f \"$f\" ] || exit 0; grep -vE '^\\s*(#|$|x )' \"$f\" 2>/dev/null | head -6"]
        stdout: StdioCollector { onStreamFinished: popup.listText = (this.text || "").trim() }
    }
    Timer { interval: 10000; running: true; repeat: true; onTriggered: popup.refresh() }

    Component.onCompleted: refresh()

    readonly property var items: listText === "" ? [] : listText.split("\n").filter(l => l.trim() !== "")

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text {
            text: popup.value !== "" ? popup.value : "0"
            font.family: "Hack Nerd Font"
            font.pixelSize: 48
            font.weight: Font.Black
            color: Theme.text
        }
        Text {
            text: "Open items in the quicknotes todo file (value producer: scripts/todobar.sh)."
            font.family: "Hack Nerd Font"
            font.pixelSize: 11
            color: Theme.subtext0
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.gapSm
            Repeater {
                model: popup.items
                delegate: Text {
                    required property string modelData
                    Layout.fillWidth: true
                    text: "· " + modelData
                    font.family: "Hack Nerd Font"
                    font.pixelSize: 12
                    color: Theme.text
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
