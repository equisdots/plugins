// GitSummaryPage — the Git plugin's own settings page (equisdots plugin
// standard). Deployed with the plugin UI and loaded by the editor as the
// dynamic p_gitsummary page.
//
// Contract: receives the editor root as `bar`. Reads settings.json ->
// "gitsummary" (seeded from the plugin's defaults.json).
import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: page
    property var bar: null

    readonly property var cfg: {
        Config.rev;
        let c = Config.rawSettings["gitsummary"];
        return (c && typeof c === "object") ? c : {};
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text {
            text: "Git"
            font.family: "Hack Nerd Font"; font.bold: true; font.pixelSize: 20
            color: Theme.text
        }
        Text {
            Layout.fillWidth: true
            text: "Git repositories under $HOME: branch, dirty count and open-in-terminal."
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

                Text { text: "Maximum repositories"; font.family: "Hack Nerd Font"; font.pixelSize: 12; color: Theme.text; Layout.topMargin: Theme.gapSm }
                Text {
                    text: String(Number(page.cfg.maxRepos) || 60)
                    font.family: "Hack Nerd Font"; font.pixelSize: 11
                    color: Theme.subtext0
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
