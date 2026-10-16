// VPN popup — the VPN plugin's bar-module popup (equisdots plugin standard).
// Rooted on the core PluginPopup base: it self-positions from the plugin's own
// settings ("popupAnchor") and is opened by the bar module via
// `qs_manager.sh toggle vpnbar`.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

PluginPopup {
    id: root
    pluginId: "vpnbar"
    scopeName: "vpnbar"
    title: "VPN"
    subtitle: "Active VPN / WireGuard interface"
    accent: Theme.color2
    popupWidth: 460
    popupHeight: 260

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/vpnbar/scripts/vpnbar.sh"

    // Same value producer as bar/Vpnbar.qml (interface name, or "off").
    property string value: ""

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
            text: root.value
            font.family: "Hack Nerd Font"
            font.pixelSize: 52
            font.weight: Font.Black
            color: Theme.text
        }
        Text {
            text: "Active VPN / WireGuard interface name reported by wg or ip, or 'off' when down."
            font.family: "Hack Nerd Font"
            font.pixelSize: 11
            color: Theme.subtext0
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Item { Layout.fillHeight: true }
    }
}
