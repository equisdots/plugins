// GlyphsPicker — the Glyphs (emojipicker) plugin's panel (equisdots plugin
// standard).
//
// Loaded by the shell's panel host from ui/plugins/emojipicker/ (manifest
// provides.panels.emoji). Pure QML: the glyph catalogue lives in Glyphs.js and
// a TextField filters it by tag; clicking a cell copies the glyph to the
// clipboard with wl-copy. The only settings key it reads is the optional grid
// column count from ~/.config/hypr/plugins/emojipicker/settings.json
// (scope "emojipicker"), seeded by defaults.json.
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.core
import qs.ui.bar
import "Glyphs.js" as Glyphs

Item {
    id: window
    focus: true

    Scaler { id: sc; currentWidth: Screen.width }
    function s(v) { return sc.s(v) }

    property int columns: 10
    property string query: ""
    property string status: ""

    // Filtered model: a JS array of { g, tags } consumed directly by GridView.
    readonly property var filtered: {
        let q = window.query.trim().toLowerCase();
        if (q === "") return Glyphs.GLYPHS;
        let out = [];
        for (let i = 0; i < Glyphs.GLYPHS.length; i++) {
            let it = Glyphs.GLYPHS[i];
            if (it.g === q || it.tags.indexOf(q) !== -1) out.push(it);
        }
        return out;
    }

    // Optional seed settings: grid columns (defaults.json -> emojipicker.columns).
    Process {
        id: settingsProc
        command: ["bash", "-c",
            "cat '" + Quickshell.env("HOME") + "/.config/hypr/plugins/emojipicker/settings.json' 2>/dev/null || echo '{}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let p = JSON.parse(this.text || "{}");
                    let e = p.emojipicker || {};
                    let c = Number(e.columns);
                    if (c >= 6 && c <= 14) window.columns = c;
                } catch (e) {}
            }
        }
    }

    // Clipboard copy via wl-copy stdin (no shell quoting of the glyph). The
    // data is written once the process has started, then stdin is closed so
    // wl-copy sees EOF and finishes.
    Process {
        id: copyProc
        command: ["wl-copy"]
        stdinEnabled: true
        property string pending: ""
        onStarted: {
            if (copyProc.pending !== "") {
                copyProc.write(copyProc.pending);
                copyProc.pending = "";
                copyProc.stdinEnabled = false;
            }
        }
    }

    function copyGlyph(g) {
        copyProc.pending = g;
        copyProc.running = false;
        copyProc.stdinEnabled = true;
        copyProc.running = true;
        window.status = "Copied " + g;
        statusTimer.restart();
    }

    Timer { id: statusTimer; interval: 1600; onTriggered: window.status = "" }

    function closeSelf() {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
    }
    Keys.onEscapePressed: (event) => { window.closeSelf(); event.accepted = true; }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusXl
        color: Theme.glassFill
        border.width: 1
        border.color: Theme.outlineVariant

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: s(14)
            spacing: s(10)

            RowLayout {
                Layout.fillWidth: true
                spacing: s(10)

                Text {
                    text: "Glyphs"
                    font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: s(18)
                    color: Theme.text
                }
                Item { Layout.fillWidth: true }
                Text {
                    visible: window.status !== ""
                    text: window.status
                    font.family: "Hack Nerd Font"; font.pixelSize: s(12)
                    color: Theme.green
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: s(38)
                radius: Theme.radiusMd
                color: Theme.surfaceContainer
                border.width: 1
                border.color: searchField.activeFocus ? Theme.mauve : Theme.outlineVariant

                TextField {
                    id: searchField
                    anchors.fill: parent
                    anchors.leftMargin: s(12)
                    anchors.rightMargin: s(12)
                    background: Item {}
                    color: Theme.text
                    font.family: "Hack Nerd Font"; font.pixelSize: s(14)
                    placeholderText: "Search glyphs by keyword"
                    placeholderTextColor: Theme.subtext0
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true
                    focus: true
                    onTextEdited: window.query = text
                }
            }

            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: window.filtered
                cellWidth: Math.floor(width / window.columns)
                cellHeight: cellWidth
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar { active: true; policy: ScrollBar.AsNeeded }

                delegate: Item {
                    id: cell
                    width: grid.cellWidth
                    height: grid.cellHeight

                    readonly property var entry: modelData

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - s(6)
                        height: width
                        radius: Theme.radiusMd
                        color: hov.containsMouse ? Theme.stateLayer(Theme.mauve, Theme.stateHover) : "transparent"
                        border.width: hov.containsMouse ? 1 : 0
                        border.color: Theme.outlineVariant

                        Text {
                            anchors.centerIn: parent
                            text: cell.entry ? cell.entry.g : ""
                            font.family: "Hack Nerd Font"
                            font.pixelSize: s(22)
                            color: Theme.text
                        }
                    }

                    MouseArea {
                        id: hov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (cell.entry) window.copyGlyph(cell.entry.g)
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: window.filtered.length + " glyphs"
                font.family: "Hack Nerd Font"; font.pixelSize: s(11)
                color: Theme.subtext0
            }
        }
    }
}
