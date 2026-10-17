// Wallpaper Motion popup — change the animated wallpaper (xwww scene) frame
// rate live. Relaunches the running scene with the same args but a new --fps,
// so palette/transition/outputs are preserved. davincix is not modified.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

PluginPopup {
    id: root
    pluginId: "wallpaper-motion"
    scopeName: "wallpaper-motion"
    title: "Wallpaper Motion"
    subtitle: "Animated scene frame rate (xwww)"
    accent: Theme.color5
    popupWidth: 460
    popupHeight: 360

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/wallpaper-motion/scripts/motion.sh"
    readonly property var presets: [15, 24, 30, 45, 60]

    property string current: ""     // live fps of the running scene ("" = static)

    function refresh() { getProc.running = false; getProc.running = true; }
    function setFps(n) {
        root.settings.set("fps", n);
        applyProc.command = ["bash", root.scriptPath, "set", String(n)];
        applyProc.running = true;
    }

    Process {
        id: getProc
        command: ["bash", root.scriptPath, "get"]
        stdout: StdioCollector { onStreamFinished: root.current = (this.text || "").trim() }
    }
    Process {
        id: applyProc
        onExited: root.refresh()
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text {
            Layout.fillWidth: true
            text: root.current !== "" ? (root.current + " fps") : "static"
            font.family: "Hack Nerd Font"; font.pixelSize: 42; font.weight: Font.Black
            color: Theme.text
        }
        Text {
            Layout.fillWidth: true
            text: root.current !== ""
                  ? "The animated wallpaper runs at this frame rate. Raise it for smoother motion."
                  : "No animated scene is running. Pick a scene in the wallpaper picker; your rate applies automatically."
            font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0
            wrapMode: Text.WordWrap
        }

        Text {
            Layout.fillWidth: true
            text: "Frame rate"
            font.family: "Hack Nerd Font"; font.weight: Font.Medium; font.pixelSize: 12
            color: Theme.text
        }
        RowLayout {
            spacing: Theme.gapSm
            Repeater {
                model: root.presets
                delegate: Rectangle {
                    required property int modelData
                    readonly property bool on: String(modelData) === root.current
                    radius: Theme.radiusFull
                    color: on ? Theme.stateLayer(Theme.color5, Theme.statePress) : Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: on ? Theme.color5 : Theme.outlineVariant
                    implicitWidth: btn.implicitWidth + Theme.gapLg * 2
                    implicitHeight: 34
                    Text {
                        id: btn; anchors.centerIn: parent
                        text: modelData + " fps"
                        font.family: "Hack Nerd Font"; font.pixelSize: 12
                        font.weight: on ? Font.Bold : Font.Normal
                        color: on ? Theme.text : Theme.subtext0
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: root.setFps(modelData)
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }

        Text {
            Layout.fillWidth: true
            text: "davincix ships 15 fps. This changes the live scene and is remembered for the next scenes."
            font.family: "Hack Nerd Font"; font.pixelSize: 10; color: Theme.subtext0
            wrapMode: Text.WordWrap
        }

        Item { Layout.fillHeight: true }
    }
}
