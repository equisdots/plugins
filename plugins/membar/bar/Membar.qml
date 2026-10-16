// Memory — RAM usage percentage (shared SysData poller) (equisdots plugin).
//
// Bar module declared as provides.bar.modules.membar; the core bar resolves it
// through PluginsCatalog at ui/bar depth. Self-contained: reads its own value
// producer under scripts/ and shows a glyph + the value.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.ui.bar

ModulePill {
    id: mod
    moduleId: "membar"

    accentRole: "color2"

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/membar/"

    onClicked: Quickshell.execDetached(["bash", "-c",
        "~/.config/hypr/scripts/qs_manager.sh toggle membar"])

    Component.onCompleted: SysData.subscribe()
    Component.onDestruction: SysData.unsubscribe()

    Row {
        visible: mod.horizontal
        spacing: bar.s(8)
        Text { anchors.verticalCenter: parent.verticalCenter; text: "󰍛"; font.family: bar.fontFamily; font.pixelSize: bar.s(13); color: mod.contentColor }
        Text { anchors.verticalCenter: parent.verticalCenter; text: SysData.ramPercent + "%"; font.family: bar.fontFamily; font.pixelSize: bar.s(12); font.weight: Font.Black; color: mod.contentColor }
    }
    Column {
        visible: mod.compact
        spacing: 1
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰍛"; font.family: bar.fontFamily; font.pixelSize: bar.s(12); color: mod.contentColor }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: SysData.ramPercent + "%"; font.family: bar.fontFamily; font.pixelSize: bar.s(9); color: mod.contentColor }
    }
}
