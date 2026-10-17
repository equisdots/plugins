import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

// Snippets settings (Plugins -> Snippets). Informational: the list, add form
// and delete action live in the panel. Items are stored in the plugin's own
// settings file (~/.config/hypr/plugins/snippetbox/settings.json, scope
// "snippetbox", key "items").
Item {
    id: page
    property var bar: null

    property int count: -1

    Process {
        id: reader
        command: ["bash", "-c",
            "jq -r '.snippetbox.items | length' " +
            "'" + Quickshell.env("HOME") + "/.config/hypr/plugins/snippetbox/settings.json' 2>/dev/null || echo -1"]
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

        Text { text: "Snippets"; font.family: "Hack Nerd Font"; font.bold: true; font.pixelSize: 20; color: Theme.text }
        Text {
            text: "Saved text snippets: click one to copy it with wl-copy, Add to append, the trash icon to delete."
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
                Text { text: "Stored snippets"; font.family: "Hack Nerd Font"; font.pixelSize: 12; color: Theme.text }
                Text {
                    text: page.count >= 0 ? (page.count + " items") : "store unavailable"
                    font.family: "Hack Nerd Font"; font.pixelSize: 12; color: Theme.subtext0
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Store: settings.json -> snippetbox.items (array of { label, text }), written atomically by scripts/snippetbox.sh. Requires jq and wl-copy."
            font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0
            wrapMode: Text.WordWrap
        }

        Item { Layout.fillHeight: true }
    }
}
