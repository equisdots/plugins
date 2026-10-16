import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.bar.edit

// Git Bar settings (Plugins → Git Bar).
Item {
    id: page
    property var bar: null
    property var host: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.gapXs
            Text { text: "Git Bar"; font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: 24; color: Theme.text }
            Text {
                Layout.fillWidth: true
                text: "Shows the git status of a repository. Pin one below, or leave it empty to follow the focused window (best-effort)."
                font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0; wrapMode: Text.WordWrap
            }
        }

        FieldCard {
            Layout.fillWidth: true
            bar: page.bar
            label: "Pinned repo"
            placeholder: "auto (focused window)"
            value: page.host ? (page.host.settings.get("repo", "") || "") : ""
            onEdited: (text) => { if (page.host) page.host.settings.set("repo", text.trim()); }
        }
        Text {
            Layout.fillWidth: true
            text: "Empty = auto: the repo of the focused window (descends to the terminal's shell). Set a path to always show one repo."
            font.family: "Hack Nerd Font"; font.pixelSize: 10; color: Theme.subtext0; wrapMode: Text.WordWrap
        }

        PluginPositionRow {
            host: page.host
            Layout.fillWidth: true
        }

        Item { Layout.fillHeight: true }
    }
}
