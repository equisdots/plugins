import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

// ============================================================================
// PomodoroCard — desktop-widget face: pomodoro remaining time.
//
// Reads the epoch end from $XDG_RUNTIME_DIR/equisdots-pomodoro through the
// value producer, which prints "<remaining-seconds> <state>" ("focus" while
// running, "idle" otherwise). Shows a big mm:ss plus a state label and
// refreshes every second while shown.
// ============================================================================

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 200
    property real minHeight: 140
    property real maxWidth: 560
    property real maxHeight: 420
    property real minAspect: 0.9
    property real maxAspect: 2.2
    property bool isRound: false

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/pomodorowidget/scripts/pomodoro.sh"

    property int seconds: 0
    property string state: "idle"

    readonly property bool running: root.state === "focus" && root.seconds > 0
    readonly property string mmss: {
        let s = Math.max(0, root.seconds);
        let m = Math.floor(s / 60);
        let r = s % 60;
        return (m < 10 ? "0" : "") + m + ":" + (r < 10 ? "0" : "") + r;
    }
    readonly property color accentColor: root.running ? Theme.mauve : Theme.overlay0
    readonly property string stateLabel: root.running ? "Focus" : "Idle"
    readonly property bool active: root.visible && root.width > 0 && root.height > 0

    function refresh() {
        reader.running = false;
        reader.running = true;
    }

    function parse(text) {
        let t = (text || "").trim();
        if (t === "") return;
        let parts = t.split(/\s+/);
        let s = parseInt(parts[0]);
        root.seconds = (isNaN(s) || s < 0) ? 0 : s;
        root.state = (parts[1] || "idle").toLowerCase();
    }

    onActiveChanged: if (root.active) root.refresh()

    Timer {
        interval: 1000
        running: root.active
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: reader
        running: false
        command: ["bash", root.scriptPath]
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }

    Component.onCompleted: root.refresh()

    GlassCard {
        anchors.fill: parent
        fill: Theme.widgetFill
        hairline: Theme.widgetHairline
        cornerRadius: Theme.radiusLg
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapXs

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gapSm

            Text {
                text: "󰔛"
                font.family: Theme.fontFamily
                font.pixelSize: 15
                color: root.accentColor
            }

            Text {
                Layout.fillWidth: true
                text: "Pomodoro"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Bold
                color: Theme.text
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: Math.max(stateLabelText.implicitWidth + 18, 40)
                implicitHeight: 20
                radius: height / 2
                color: Theme.surface2

                Text {
                    id: stateLabelText
                    anchors.centerIn: parent
                    text: root.stateLabel
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                    color: root.accentColor
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: root.mmss
            font.family: Theme.fontFamily
            font.pixelSize: 56
            fontSizeMode: Text.Fit
            minimumPixelSize: 18
            font.weight: Font.Black
            font.letterSpacing: 1.0
            color: root.accentColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
