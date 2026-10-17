// DiskUsagePage — the Disks plugin's own settings page (equisdots plugin
// standard). Deployed with the plugin UI and loaded by the editor as the
// dynamic p_diskusage page.
//
// Contract: receives the editor root as `bar`. Reads settings.json ->
// "diskusage" (seeded from the plugin's defaults.json).
import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: page
    property var bar: null

    readonly property var cfg: {
        Config.rev;
        let c = Config.rawSettings["diskusage"];
        return (c && typeof c === "object") ? c : {};
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text {
            text: "Disks"
            font.family: "Hack Nerd Font"; font.bold: true; font.pixelSize: 20
            color: Theme.text
        }
        Text {
            Layout.fillWidth: true
            text: "Filesystem usage: mountpoint, used/total and a threshold-coloured bar."
            font.family: "Hack Nerd Font"; font.pixelSize: 11
            color: Theme.subtext0
            wrapMode: Text.WordWrap
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
                spacing: Theme.gapSm

                Text { text: "Refresh interval"; font.family: "Hack Nerd Font"; font.pixelSize: 12; color: Theme.text }
                Text {
                    text: (Number(page.cfg.refreshMs) || 15000) + " ms"
                    font.family: "Hack Nerd Font"; font.pixelSize: 11
                    color: Theme.subtext0
                }

                RowLayout {
                    Layout.topMargin: Theme.gapSm
                    spacing: Theme.gapSm
                    Rectangle { width: 10; height: 10; radius: 5; color: Theme.green }
                    Text { text: "below 70%"; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0 }
                    Rectangle { width: 10; height: 10; radius: 5; color: Theme.yellow }
                    Text { text: "70-90%"; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0 }
                    Rectangle { width: 10; height: 10; radius: 5; color: Theme.red }
                    Text { text: "90%+"; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0 }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
