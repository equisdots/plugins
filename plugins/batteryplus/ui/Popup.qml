// Battery Plus popup — the Battery Plus plugin's bar-module popup (equisdots
// plugin standard). Rooted on the core PluginPopup base: it self-positions from
// the plugin's own settings ("popupAnchor") and is opened by the bar module via
// `qs_manager.sh toggle batteryplus`.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

PluginPopup {
    id: root
    pluginId: "batteryplus"
    scopeName: "batteryplus"
    title: "Battery Plus"
    subtitle: "Battery charge and status"
    accent: Theme.color2
    popupWidth: 460
    popupHeight: 300

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/batteryplus/scripts/batteryplus.sh"

    // Same value producer as bar/Batteryplus.qml.
    property string value: ""

    readonly property int pct: {
        var m = (value || "").match(/(\d+)/);
        return m ? parseInt(m[1], 10) : -1;
    }

    function refresh() { reader.running = false; reader.running = true; }

    Process {
        id: reader
        command: ["bash", root.scriptPath]
        stdout: StdioCollector { onStreamFinished: root.value = (this.text || "").trim() }
    }
    Timer { interval: 20000; running: true; repeat: true; onTriggered: root.refresh() }

    Component.onCompleted: refresh()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text {
            text: root.value
            font.family: "Hack Nerd Font"
            font.pixelSize: 48
            font.weight: Font.Black
            color: Theme.text
        }
        Rectangle {
            visible: root.pct >= 0
            Layout.fillWidth: true
            height: s(10)
            radius: 5
            color: Theme.surfaceContainerHighest
            Rectangle {
                width: parent.width * Math.min(1, Math.max(0, root.pct) / 100)
                height: parent.height
                radius: 5
                color: Theme.color2
                Behavior on width { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.OutCubic } }
            }
        }
        Text {
            text: "Battery charge and status read straight from /sys/class/power_supply."
            font.family: "Hack Nerd Font"
            font.pixelSize: 11
            color: Theme.subtext0
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Item { Layout.fillHeight: true }
    }
}
