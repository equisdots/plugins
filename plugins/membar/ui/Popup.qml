// Memory popup — the Memory plugin's bar-module popup (equisdots plugin
// standard). Rooted on the core PluginPopup base: it self-positions from the
// plugin's own settings ("popupAnchor") and is opened by the bar module via
// `qs_manager.sh toggle membar`.
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

PluginPopup {
    pluginId: "membar"
    scopeName: "membar"
    title: "Memory"
    subtitle: "RAM usage · shared SysData poller"
    accent: Theme.color2
    popupWidth: 460
    popupHeight: 320

    Component.onCompleted: SysData.subscribe()
    Component.onDestruction: SysData.unsubscribe()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text {
            text: SysData.ramPercent + "%"
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
                width: parent.width * Math.min(1, SysData.ramPercent / 100)
                height: parent.height
                radius: 5
                color: Theme.color2
                Behavior on width { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.OutCubic } }
            }
        }
        Text {
            text: "Live RAM percentage reported by the shared core SysData singleton."
            font.family: "Hack Nerd Font"
            font.pixelSize: 11
            color: Theme.subtext0
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Item { Layout.fillHeight: true }
    }
}
