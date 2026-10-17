// Pomodoro popup — the Pomodoro plugin's bar-module popup (equisdots plugin
// standard). Rooted on the core PluginPopup base: it self-positions from the
// plugin's own settings ("popupAnchor") and is opened by the bar module via
// `qs_manager.sh toggle pomodoro`.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

PluginPopup {
    id: popup
    pluginId: "pomodoro"
    scopeName: "pomodoro"
    title: "Pomodoro"
    subtitle: "Focus timer · state file driven"
    accent: Theme.color1
    popupWidth: 460
    popupHeight: 300

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/pomodoro/scripts/pomodoro.sh"

    property string value: ""
    function refresh() { reader.running = false; reader.running = true; }
    Process {
        id: reader
        command: ["bash", popup.scriptPath]
        stdout: StdioCollector { onStreamFinished: popup.value = (this.text || "").trim() }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: popup.refresh() }

    Component.onCompleted: refresh()

    // Remaining seconds parsed from "MM:SS"; assumes a 25:00 focus session for
    // the progress bar (the state file only records the end timestamp).
    readonly property int remainSec: {
        const m = /^(\d+):(\d+)$/.exec(value);
        if (!m) return 0;
        return parseInt(m[1]) * 60 + parseInt(m[2]);
    }
    readonly property real progress: {
        if (value === "done") return 1;
        const m = /^(\d+):(\d+)$/.exec(value);
        if (!m) return 0;
        const left = parseInt(m[1]) * 60 + parseInt(m[2]);
        return Math.max(0, Math.min(1, 1 - left / 1500));
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text {
            text: popup.value !== "" ? popup.value : "idle"
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
                width: parent.width * popup.progress
                height: parent.height
                radius: 5
                color: Theme.color1
                Behavior on width { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.OutCubic } }
            }
        }
        Text {
            text: "Remaining focus time from the state file (value producer: scripts/pomodoro.sh)."
            font.family: "Hack Nerd Font"
            font.pixelSize: 11
            color: Theme.subtext0
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Item { Layout.fillHeight: true }
    }
}
