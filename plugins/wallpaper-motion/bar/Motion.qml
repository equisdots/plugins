// Wallpaper Motion — frame rate of the running xwww scene (animated wallpaper).
// Island: "N fps" (or "static" when no scene). Click opens the popup to change
// it live (without touching davincix).
import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.ui.bar

ModulePill {
    id: mod
    moduleId: "wallpaper-motion"

    accentRole: "color5"

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/wallpaper-motion/scripts/motion.sh"

    onClicked: Quickshell.execDetached(["bash", "-c",
        "~/.config/hypr/scripts/qs_manager.sh toggle wallpaper-motion"])

    property string fps: ""
    readonly property bool hasScene: mod.fps !== ""

    function refresh() { get.running = false; get.running = true; }
    Process {
        id: get
        command: ["bash", mod.scriptPath, "get"]
        stdout: StdioCollector { onStreamFinished: mod.fps = (this.text || "").trim() }
    }
    Timer { interval: 4000; running: true; repeat: true; triggeredOnStart: true; onTriggered: mod.refresh() }

    Component.onCompleted: mod.refresh()

    Row {
        visible: mod.horizontal
        spacing: bar.s(8)
        Text { anchors.verticalCenter: parent.verticalCenter; text: "󰈆"; font.family: bar.fontFamily; font.pixelSize: bar.s(13); color: mod.contentColor }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: mod.hasScene ? (mod.fps + " fps") : "static"
            font.family: bar.fontFamily
            font.pixelSize: bar.s(12)
            font.weight: mod.hasScene ? Font.Black : Font.Medium
            color: mod.hasScene ? mod.contentColor : Qt.alpha(mod.contentColor, 0.5)
        }
    }
    Column {
        visible: mod.compact
        spacing: 1
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰈆"; font.family: bar.fontFamily; font.pixelSize: bar.s(12); color: mod.contentColor }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: mod.hasScene ? mod.fps : "–"; font.family: bar.fontFamily; font.pixelSize: bar.s(9); color: mod.contentColor }
    }
}
