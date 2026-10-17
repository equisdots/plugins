import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

// Color Picker settings (Plugins -> Color Picker). Informational: the picker,
// history and clipboard actions live in the panel and scripts/colorpicker.sh.
// History is stored in the plugin's own settings file
// (~/.config/hypr/plugins/colorpicker/settings.json, scope "colorpicker").
Item {
    id: page
    property var bar: null

    property int count: -1

    Process {
        id: reader
        command: ["bash", "-c",
            "jq -r '.colorpicker.history | length' " +
            "'" + Quickshell.env("HOME") + "/.config/hypr/plugins/colorpicker/settings.json' 2>/dev/null || echo -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let n = parseInt((this.text || "").trim());
                page.count = isNaN(n) ? -1 : n;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text { text: "Color Picker"; font.family: "Hack Nerd Font"; font.bold: true; font.pixelSize: 20; color: Theme.text }
        Text {
            text: "Pick a colour from the screen with hyprpicker -a; the last 12 picks are kept as copyable swatches."
            font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0
            Layout.fillWidth: true; wrapMode: Text.WordWrap
        }

        Rectangle {
            Layout.fillWidth: true
            radius: Theme.radiusLg
            color: Theme.surfaceContainerLow
            border.width: 1; border.color: Theme.outlineVariant
            implicitHeight: inner.implicitHeight + Theme.gapLg * 2

            ColumnLayout {
                id: inner
                anchors.fill: parent; anchors.margins: Theme.gapLg; spacing: Theme.gapSm
                Text { text: "Saved colours"; font.family: "Hack Nerd Font"; font.pixelSize: 12; color: Theme.text }
                Text {
                    text: page.count >= 0 ? (page.count + " in history") : "history unavailable"
                    font.family: "Hack Nerd Font"; font.pixelSize: 12; color: Theme.subtext0
                }
                RowLayout {
                    spacing: Theme.gapSm
                    Rectangle { implicitWidth: 28; implicitHeight: 28; radius: Theme.radiusSm; color: Theme.mauve }
                    Rectangle { implicitWidth: 28; implicitHeight: 28; radius: Theme.radiusSm; color: Theme.blue }
                    Rectangle { implicitWidth: 28; implicitHeight: 28; radius: Theme.radiusSm; color: Theme.green }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Store: settings.json -> colorpicker.history (array of #rrggbb). Requires hyprpicker, jq and wl-copy."
            font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0
            wrapMode: Text.WordWrap
        }

        Item { Layout.fillHeight: true }
    }
}
