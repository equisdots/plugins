// Git Bar popup — the Git Bar plugin's bar-module popup (equisdots plugin
// standard). Rooted on the core PluginPopup base: it self-positions from the
// plugin's own settings ("popupAnchor") and is opened by the bar module via
// `qs_manager.sh toggle gitbar`. Reads the rich `--detail` JSON from the same
// producer the island uses (repo of the FOCUSED window).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

PluginPopup {
    id: root
    pluginId: "gitbar"
    scopeName: "gitbar"
    title: "Git"
    subtitle: "Repository of the focused window"
    accent: Theme.color6
    popupWidth: 540
    popupHeight: 440

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/gitbar/scripts/gitbar.sh"

    property var info: ({})
    function refresh() { reader.running = false; reader.running = true; }
    Process {
        id: reader
        command: ["bash", root.scriptPath, "--detail"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.info = JSON.parse(this.text || "{}"); }
                catch (e) { root.info = ({}); }
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: root.refresh() }
    Component.onCompleted: refresh()

    readonly property bool hasRepo: (root.info && root.info.repo !== undefined && root.info.repo !== "")

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text {
            Layout.fillWidth: true
            text: root.hasRepo ? (root.info.branch || "detached") : "no project"
            font.family: "Hack Nerd Font"; font.pixelSize: 40; font.weight: Font.Black
            color: Theme.text
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            text: root.hasRepo ? root.info.repo : "No project opened. Focus a window inside a repository, or pin one in this plugin's settings."
            font.family: "Hack Nerd Font"; font.pixelSize: 10
            color: Theme.subtext0
            wrapMode: Text.WordWrap
        }

        // stat chips
        RowLayout {
            spacing: Theme.gapSm
            visible: root.hasRepo
            Repeater {
                model: [
                    { t: "● " + (root.info.dirty || 0) + " changed", c: (root.info.dirty || 0) > 0 ? Theme.yellow : Theme.green },
                    { t: "↑ " + (root.info.ahead || 0),          c: Theme.blue },
                    { t: "↓ " + (root.info.behind || 0),         c: Theme.blue }
                ]
                delegate: Rectangle {
                    required property var modelData
                    radius: Theme.radiusFull
                    color: Qt.alpha(modelData.c, 0.15)
                    border.width: 1; border.color: Qt.alpha(modelData.c, 0.6)
                    implicitWidth: ct.implicitWidth + Theme.gapLg
                    implicitHeight: ct.implicitHeight + Theme.gapXs
                    Text {
                        id: ct; anchors.centerIn: parent
                        text: modelData.t
                        font.family: "Hack Nerd Font"; font.pixelSize: 11
                        color: modelData.c
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }

        // changed files
        Text {
            Layout.fillWidth: true
            visible: root.hasRepo
            text: "Changed files"
            font.family: "Hack Nerd Font"; font.weight: Font.Medium; font.pixelSize: 11
            color: Theme.text
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            visible: root.hasRepo
            Repeater {
                model: (root.info.files || [])
                delegate: Text {
                    required property string modelData
                    Layout.fillWidth: true
                    text: modelData
                    font.family: "Hack Nerd Font"; font.pixelSize: 11
                    color: Theme.subtext0
                    elide: Text.ElideRight
                }
            }
            Text {
                visible: (root.info.files || []).length === 0
                text: "Working tree clean."
                font.family: "Hack Nerd Font"; font.pixelSize: 11
                color: Theme.green
            }
        }

        Item { Layout.fillHeight: true }

        Text {
            Layout.fillWidth: true
            visible: root.hasRepo && root.info.last !== ""
            text: "last: " + (root.info.last || "")
            font.family: "Hack Nerd Font"; font.pixelSize: 10
            color: Qt.alpha(Theme.subtext0, 0.9)
            elide: Text.ElideRight
        }
    }
}
