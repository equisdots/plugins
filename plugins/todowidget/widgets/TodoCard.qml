import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

// ============================================================================
// TodoCard — desktop-widget face: the open items of the equisdots todo file.
//
// The value producer prints the open lines (not "x " done, not "#" comments);
// this face shows a count header plus up to `maxRows` rows. Refreshes every
// 10 s while shown.
// ============================================================================

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 220
    property real minHeight: 160
    property real maxWidth: 640
    property real maxHeight: 480
    property real minAspect: 0.9
    property real maxAspect: 2.2
    property bool isRound: false

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/todowidget/scripts/todo.sh"

    property int maxRows: {
        Config.rev;
        let v = parseInt(Config.getSetting("todowidget.maxRows", 6));
        return (isNaN(v) || v < 1) ? 6 : v;
    }

    property var items: []
    readonly property int totalCount: root.items.length
    readonly property var shownItems: root.items.slice(0, root.maxRows)
    readonly property bool active: root.visible && root.width > 0 && root.height > 0

    function refresh() {
        reader.running = false;
        reader.running = true;
    }

    function parse(text) {
        let t = (text || "").replace(/\r/g, "");
        let out = [];
        let lines = t.split("\n");
        for (let i = 0; i < lines.length; i++) {
            let s = lines[i].trim();
            if (s !== "") out.push(s);
        }
        root.items = out;
    }

    onActiveChanged: if (root.active) root.refresh()

    Timer {
        interval: 10000
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
        spacing: Theme.gapSm

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gapSm

            Text {
                text: "󰄲"
                font.family: Theme.fontFamily
                font.pixelSize: 15
                color: Theme.blue
            }

            Text {
                Layout.fillWidth: true
                text: "Todo"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Bold
                color: Theme.text
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: Math.max(countLabel.implicitWidth + 16, 26)
                implicitHeight: 20
                radius: height / 2
                color: Theme.surface2

                Text {
                    id: countLabel
                    anchors.centerIn: parent
                    text: String(root.totalCount)
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: Theme.subtext0
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.totalCount === 0
            text: "All clear"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.subtext0
        }

        Repeater {
            model: root.shownItems

            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: Theme.gapSm

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 6
                    Layout.preferredHeight: 6
                    radius: 3
                    color: Theme.blue
                }

                Text {
                    Layout.fillWidth: true
                    text: modelData
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.text
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
