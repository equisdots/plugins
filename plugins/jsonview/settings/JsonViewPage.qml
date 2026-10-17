// JsonViewPage — the JSON plugin's own settings page (equisdots plugin
// standard). Deployed with the plugin UI and loaded by the editor as the
// dynamic p_jsonview page.
//
// Contract: receives the editor root as `bar`. Reads settings.json ->
// "jsonview" (seeded from the plugin's defaults.json).
import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: page
    property var bar: null

    readonly property var cfg: {
        Config.rev;
        let c = Config.rawSettings["jsonview"];
        return (c && typeof c === "object") ? c : {};
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text {
            text: "JSON"
            font.family: "Hack Nerd Font"; font.bold: true; font.pixelSize: 20
            color: Theme.text
        }
        Text {
            Layout.fillWidth: true
            text: "Paste, pretty-print, minify and copy JSON (pure QML/JS)."
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

                Text { text: "Indent (Format)"; font.family: "Hack Nerd Font"; font.pixelSize: 12; color: Theme.text }
                Text {
                    text: (Number(page.cfg.indent) >= 0 ? Number(page.cfg.indent) : 2) + " spaces"
                    font.family: "Hack Nerd Font"; font.pixelSize: 11
                    color: Theme.subtext0
                }

                Text { text: "Clipboard"; font.family: "Hack Nerd Font"; font.pixelSize: 12; color: Theme.text; Layout.topMargin: Theme.gapSm }
                Text {
                    text: "Copy uses wl-copy (xclip/xsel fallback) through scripts/jsonview-copy.sh"
                    font.family: "Hack Nerd Font"; font.pixelSize: 11
                    color: Theme.subtext0
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
