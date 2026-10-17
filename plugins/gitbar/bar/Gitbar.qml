// Git Bar — git branch/status for the pinned repo or the focused window
// (equisdots plugin). Shows the git glyph + value; when nothing resolves
// (no repo under the focused window and no pinned repo) it keeps the glyph and
// reads "no project opened" instead of disappearing.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.ui.bar

ModulePill {
    id: mod
    moduleId: "gitbar"

    accentRole: "color6"

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/gitbar/scripts/gitbar.sh"

    onClicked: Quickshell.execDetached(["bash", "-c",
        "~/.config/hypr/scripts/qs_manager.sh toggle gitbar"])

    property string value: ""
    readonly property bool hasRepo: mod.value !== ""
    readonly property string label: mod.hasRepo ? mod.value : "no project opened"
    readonly property color fg: mod.hasRepo ? mod.contentColor : Qt.alpha(mod.contentColor, 0.5)

    function refresh() { reader.running = false; reader.running = true; }
    Process {
        id: reader
        command: ["bash", mod.scriptPath]
        stdout: StdioCollector { onStreamFinished: mod.value = (this.text || "").trim() }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: mod.refresh() }

    Component.onCompleted: refresh()

    Row {
        visible: mod.horizontal
        spacing: bar.s(8)
        Text { anchors.verticalCenter: parent.verticalCenter; text: "󰊢"; font.family: bar.fontFamily; font.pixelSize: bar.s(13); color: mod.fg }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: mod.label
            font.family: bar.fontFamily
            font.pixelSize: bar.s(12)
            font.weight: mod.hasRepo ? Font.Black : Font.Medium
            color: mod.fg
        }
    }
    Column {
        visible: mod.compact
        spacing: 1
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰊢"; font.family: bar.fontFamily; font.pixelSize: bar.s(12); color: mod.fg }
        Text { visible: mod.hasRepo; anchors.horizontalCenter: parent.horizontalCenter; text: mod.value; font.family: bar.fontFamily; font.pixelSize: bar.s(9); color: mod.fg }
    }
}
