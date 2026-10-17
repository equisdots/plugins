// Do Not Disturb popup — the Do Not Disturb plugin's bar-module popup
// (equisdots plugin standard). Rooted on the core PluginPopup base: it
// self-positions from the plugin's own settings ("popupAnchor") and is opened by
// the bar module via `qs_manager.sh toggle dndbar`.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

PluginPopup {
    id: root
    pluginId: "dndbar"
    scopeName: "dndbar"
    title: "Do Not Disturb"
    subtitle: "Notification do-not-disturb state"
    accent: Theme.color5
    popupWidth: 460
    popupHeight: 260

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/dndbar/scripts/dndbar.sh"

    // Same value producer as bar/Dndbar.qml ("DND" / "on").
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
            text: root.value
            font.family: "Hack Nerd Font"
            font.pixelSize: 52
            font.weight: Font.Black
            color: Theme.text
        }
        Text {
            text: "Notification do-not-disturb flag (DND means notifications are silenced)."
            font.family: "Hack Nerd Font"
            font.pixelSize: 11
            color: Theme.subtext0
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Item { Layout.fillHeight: true }
    }
}
