import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.ui.bar.edit
import qs.ui.bar
import qs.core

// ═══════════════════════════════════════════════════════════════════════════
// HelloBarPage — the Hello Bar plugin's own settings page (POC fixture).
//
// A complete-bar plugin configures itself from its own page in the Plugins
// group, exactly like any other plugin: this page IS the bar's menu. The
// plugin's master switch (Plugins manager) owns mounting/unmounting the bar.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    anchors.fill: parent
    property var bar: null
    property var host: null

    property bool dShowDate: true

    readonly property var cfg: {
        if (root.host && root.host.settings) return root.host.settings.section;
        return ({});
    }

    function syncFromConfig() {
        root.dShowDate = root.cfg.showDate !== false;
    }
    Component.onCompleted: root.syncFromConfig()
    onHostChanged: if (root.host) root.syncFromConfig()

    function set(key, v) {
        if (root.host && root.host.settings) root.host.settings.set(key, v);
    }

    readonly property var flickable: body.item ? body.item.flickable : null

    Loader { id: body; anchors.fill: parent; active: root.bar !== null; sourceComponent: pageBody }

    Component {
        id: pageBody
        Item {
            anchors.fill: parent
            property alias flickable: flick
            Flickable {
                id: flick
                anchors.fill: parent; clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentHeight: col.height + bar.s(16)
                ScrollBar.vertical: ScrollBar { width: bar.s(4); policy: ScrollBar.AsNeeded }

                Column {
                    id: col
                    x: bar.s(8); y: bar.s(8)
                    width: flick.width - bar.s(16)
                    spacing: bar.s(9)

                    Text {
                        text: "Hello Bar"
                        font.family: "Hack Nerd Font"; font.weight: Font.Black
                        font.pixelSize: bar.s(24); color: bar.colors.text
                    }
                    EditLabel {
                        bar: root.bar; width: parent.width
                        text: "POC fixture: a complete bar provided by the plugin (mounted while the plugin is enabled). Its master switch lives in the Plugins manager; disable the core bar in the Bar group when this one should own the screen edge."
                        font.pixelSize: bar.s(11); color: bar.colors.subtext0; wrapMode: Text.WordWrap
                    }

                    SectionTitle { bar: root.bar; text: "Clock" }
                    RowLayout {
                        width: parent.width; spacing: bar.s(12)
                        Text { text: "Show date"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(12); color: bar.colors.text; Layout.fillWidth: true }
                        ToggleSwitch { bar: root.bar; checked: root.dShowDate; onToggled: { root.dShowDate = checked; root.set("showDate", checked); } }
                    }
                }
            }
        }
    }
}
