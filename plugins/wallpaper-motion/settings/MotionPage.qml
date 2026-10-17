import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

// Wallpaper Motion settings (Plugins → Wallpaper Motion).
Item {
    id: page
    property var bar: null
    property var host: null

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/wallpaper-motion/scripts/motion.sh"
    readonly property var presets: [15, 24, 30, 45, 60]
    readonly property int value: page.host ? Number(page.host.settings.get("fps", 30)) : 30

    function choose(n) {
        if (page.host) page.host.settings.set("fps", n);
        Quickshell.execDetached(["bash", page.scriptPath, "set", String(n)]);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapXl

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.gapXs
            Text { text: "Wallpaper Motion"; font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: 24; color: Theme.text }
            Text {
                Layout.fillWidth: true
                text: "Frame rate of the animated wallpaper (xwww scene). Changing it relaunches the running scene at the new rate; davincix itself is untouched."
                font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0; wrapMode: Text.WordWrap
            }
        }

        Rectangle {
            Layout.fillWidth: true
            radius: Theme.radiusLg
            color: Theme.surfaceContainerLow
            border.width: 1
            border.color: Theme.outlineVariant
            implicitHeight: inner.implicitHeight + Theme.gapLg * 2

            ColumnLayout {
                id: inner
                anchors.fill: parent
                anchors.margins: Theme.gapLg
                spacing: Theme.gapMd

                Text { text: "Frame rate"; font.family: "Hack Nerd Font"; font.weight: Font.Medium; font.pixelSize: 12; color: Theme.text }

                Flow {
                    Layout.fillWidth: true
                    spacing: Theme.gapSm
                    Repeater {
                        model: page.presets
                        delegate: Rectangle {
                            required property int modelData
                            readonly property bool on: modelData === page.value
                            radius: Theme.radiusFull
                            color: on ? Theme.stateLayer(Theme.color5, Theme.statePress) : Theme.surfaceContainerHigh
                            border.width: 1
                            border.color: on ? Theme.color5 : Theme.outlineVariant
                            implicitWidth: bt.implicitWidth + Theme.gapLg * 2
                            implicitHeight: 32
                            Text {
                                id: bt; anchors.centerIn: parent
                                text: modelData + " fps"
                                font.family: "Hack Nerd Font"; font.pixelSize: 12
                                font.weight: on ? Font.Bold : Font.Normal
                                color: on ? Theme.text : Theme.subtext0
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: page.choose(modelData)
                            }
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: "Applies to the current scene immediately and is used when you change to another scene."
                    font.family: "Hack Nerd Font"; font.pixelSize: 10; color: Theme.subtext0
                    wrapMode: Text.WordWrap
                }
            }
        }

        PluginPositionRow {
            host: page.host
            Layout.fillWidth: true
        }

        Item { Layout.fillHeight: true }
    }
}
