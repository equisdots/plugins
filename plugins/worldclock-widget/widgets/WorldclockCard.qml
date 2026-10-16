import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

// ============================================================================
// WorldclockCard — desktop-widget face: a second-timezone clock card.
//
// Big HH:MM in the configured timezone, the local date line and the tz label.
// The timezone comes from the global settings key `worldclock.tz` (default
// "UTC"); the value producer under scripts/ receives it as arg 1 and prints
// the time and the date. Refreshes every second while shown.
// ============================================================================

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 180
    property real minHeight: 120
    property real maxWidth: 560
    property real maxHeight: 420
    property real minAspect: 1.0
    property real maxAspect: 2.6
    property bool isRound: false

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/worldclock-widget/scripts/worldclock.sh"

    // Global settings read: `worldclock.tz` (Config.rev keeps the binding live).
    readonly property string tz: {
        Config.rev;
        let v = Config.getSetting("worldclock.tz", "UTC");
        return (v === undefined || v === null || String(v) === "") ? "UTC" : String(v);
    }

    property string timeText: "--:--"
    property string dateText: ""
    readonly property bool active: root.visible && root.width > 0 && root.height > 0

    function refresh() {
        reader.running = false;
        reader.running = true;
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
        command: ["bash", root.scriptPath, root.tz]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = (this.text || "").replace(/\r/g, "").split("\n");
                root.timeText = (lines[0] || "").trim() || "--:--";
                root.dateText = (lines[1] || "").trim();
            }
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
                text: "󰅐"
                font.family: Theme.fontFamily
                font.pixelSize: 15
                color: Theme.mauve
            }

            Text {
                Layout.fillWidth: true
                text: root.tz
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 0.8
                color: Theme.subtext0
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: root.timeText
            font.family: Theme.fontFamily
            font.pixelSize: 56
            fontSizeMode: Text.Fit
            minimumPixelSize: 18
            font.weight: Font.Black
            color: Theme.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            Layout.fillWidth: true
            text: root.dateText
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.subtext0
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
