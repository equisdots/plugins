// World Clock — Time in a second timezone (UTC by default) (equisdots plugin).
//
// Bar module declared as provides.bar.modules.worldclock; the core bar resolves it
// through PluginsCatalog at ui/bar depth. Self-contained: reads its own value
// producer under scripts/ and shows a glyph + the value.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.ui.bar

ModulePill {
    id: mod
    moduleId: "worldclock"

    accentRole: "color6"

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/worldclock/scripts/worldclock.sh"

    property string value: ""
    function refresh() { reader.running = false; reader.running = true; }
    Process {
        id: reader
        command: ["bash", mod.scriptPath]
        stdout: StdioCollector { onStreamFinished: mod.value = (this.text || "").trim() }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: mod.refresh() }

    Component.onCompleted: refresh()

    Row {
        visible: mod.horizontal
        spacing: bar.s(8)
        Text { anchors.verticalCenter: parent.verticalCenter; text: "󰅐"; font.family: bar.fontFamily; font.pixelSize: bar.s(13); color: mod.contentColor }
        Text { anchors.verticalCenter: parent.verticalCenter; text: mod.value; font.family: bar.fontFamily; font.pixelSize: bar.s(12); font.weight: Font.Black; color: mod.contentColor }
    }
    Column {
        visible: mod.compact
        spacing: 1
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰅐"; font.family: bar.fontFamily; font.pixelSize: bar.s(12); color: mod.contentColor }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: mod.value; font.family: bar.fontFamily; font.pixelSize: bar.s(9); color: mod.contentColor }
    }
}
