// JsonView — the JSON plugin's panel (equisdots plugin standard).
//
// Loaded by the shell's panel host from ui/plugins/jsonview/ (manifest
// provides.panels.json); the qs.* imports resolve against the shell tree.
// Pure QML/JS (JSON.parse / JSON.stringify); the Copy button hands the text to
// the plugin's scripts/jsonview-copy.sh (wl-copy). No network access.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.core
import qs.ui.bar

Item {
    id: window
    focus: true

    Scaler { id: sc; currentWidth: Screen.width }
    function s(v) { return sc.s(v) }

    readonly property var cfg: {
        Config.rev;
        let c = Config.rawSettings["jsonview"];
        return (c && typeof c === "object") ? c : {};
    }
    readonly property int indent: {
        let v = Number(cfg.indent);
        return (v >= 0 && v <= 8) ? Math.round(v) : 2;
    }

    readonly property string copyPath: Quickshell.env("HOME") + "/.config/hypr/plugins/jsonview/scripts/jsonview-copy.sh"

    property bool ok: true
    property string status: "[OK: 0 keys]"

    // Top-level member count: object -> keys, array -> length, scalar -> 1.
    function keyCount(v) {
        if (Array.isArray(v)) return v.length;
        if (v !== null && typeof v === "object") return Object.keys(v).length;
        return 1;
    }

    function formatJson(spaces) {
        let text = editor.text;
        if (text.trim() === "") {
            window.ok = false;
            window.status = "[ERROR: empty input]";
            return;
        }
        try {
            let obj = JSON.parse(text);
            let out = JSON.stringify(obj, null, spaces);
            if (out === undefined) throw new Error("value is not serialisable");
            editor.text = out;
            window.ok = true;
            window.status = "[OK: " + window.keyCount(obj) + " keys]";
        } catch (e) {
            window.ok = false;
            window.status = "[ERROR: " + ((e && e.message) ? e.message : String(e)) + "]";
        }
    }

    function copy() {
        if (editor.text.length === 0) {
            window.ok = false;
            window.status = "[ERROR: nothing to copy]";
            return;
        }
        Quickshell.execDetached(["bash", window.copyPath, editor.text]);
        window.ok = true;
        window.status = "[OK: copied to clipboard]";
    }

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

            // --- header ---
            RowLayout {
                Layout.fillWidth: true
                spacing: s(10)

                Text {
                    text: "{}"
                    font.family: "Hack Nerd Font"; font.pixelSize: s(18); font.weight: Font.Black
                    color: Theme.mauve
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: "JSON"
                        font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: s(18)
                        color: Theme.text
                    }
                    Text {
                        text: "Format, minify and copy"
                        font.family: "Hack Nerd Font"; font.pixelSize: s(11)
                        color: Theme.subtext0
                    }
                }
            }

            // --- toolbar ---
            RowLayout {
                Layout.fillWidth: true
                spacing: s(8)

                Rectangle {
                    implicitWidth: fmtLabel.implicitWidth + s(24)
                    implicitHeight: s(30)
                    radius: Theme.radiusSm
                    color: fmtMa.containsMouse ? Theme.stateLayer(Theme.mauve, Theme.stateHover) : Theme.surfaceContainer
                    border.width: 1
                    border.color: Theme.outlineVariant
                    Behavior on color { ColorAnimation { duration: Theme.durShort } }
                    Text {
                        id: fmtLabel
                        anchors.centerIn: parent
                        text: "Format"
                        font.family: "Hack Nerd Font"; font.pixelSize: s(12); font.weight: Font.Bold
                        color: Theme.mauve
                    }
                    MouseArea {
                        id: fmtMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.formatJson(window.indent)
                    }
                }

                Rectangle {
                    implicitWidth: minLabel.implicitWidth + s(24)
                    implicitHeight: s(30)
                    radius: Theme.radiusSm
                    color: minMa.containsMouse ? Theme.stateLayer(Theme.blue, Theme.stateHover) : Theme.surfaceContainer
                    border.width: 1
                    border.color: Theme.outlineVariant
                    Behavior on color { ColorAnimation { duration: Theme.durShort } }
                    Text {
                        id: minLabel
                        anchors.centerIn: parent
                        text: "Minify"
                        font.family: "Hack Nerd Font"; font.pixelSize: s(12); font.weight: Font.Bold
                        color: Theme.blue
                    }
                    MouseArea {
                        id: minMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.formatJson(0)
                    }
                }

                Rectangle {
                    implicitWidth: copyLabel.implicitWidth + s(24)
                    implicitHeight: s(30)
                    radius: Theme.radiusSm
                    color: copyMa.containsMouse ? Theme.stateLayer(Theme.green, Theme.stateHover) : Theme.surfaceContainer
                    border.width: 1
                    border.color: Theme.outlineVariant
                    Behavior on color { ColorAnimation { duration: Theme.durShort } }
                    Text {
                        id: copyLabel
                        anchors.centerIn: parent
                        text: "Copy"
                        font.family: "Hack Nerd Font"; font.pixelSize: s(12); font.weight: Font.Bold
                        color: Theme.green
                    }
                    MouseArea {
                        id: copyMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.copy()
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: clearLabel.implicitWidth + s(24)
                    implicitHeight: s(30)
                    radius: Theme.radiusSm
                    color: clearMa.containsMouse ? Theme.stateLayer(Theme.overlay0, Theme.stateHover) : Theme.surfaceContainer
                    border.width: 1
                    border.color: Theme.outlineVariant
                    Behavior on color { ColorAnimation { duration: Theme.durShort } }
                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Clear"
                        font.family: "Hack Nerd Font"; font.pixelSize: s(12); font.weight: Font.Bold
                        color: Theme.overlay0
                    }
                    MouseArea {
                        id: clearMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { editor.text = ""; window.ok = true; window.status = "[OK: 0 keys]"; }
                    }
                }
            }

            // --- editor ---
            ScrollView {
                id: sv
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { implicitWidth: s(4); radius: s(2); color: Theme.surface2; opacity: 0.5 }
                }

                TextArea {
                    id: editor
                    width: sv.availableWidth
                    padding: s(10)
                    color: Theme.text
                    selectionColor: Theme.stateLayer(Theme.mauve, 0.35)
                    selectedTextColor: Theme.text
                    font.family: "Hack Nerd Font"
                    font.pixelSize: s(12)
                    placeholderText: "Paste JSON here..."
                    placeholderTextColor: Theme.overlay0
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    background: Rectangle {
                        radius: Theme.radiusMd
                        color: Theme.surfaceContainerLow
                        border.width: 1
                        border.color: editor.activeFocus ? Theme.mauve : Theme.outlineVariant
                    }
                }
            }

            // --- status line ---
            Text {
                Layout.fillWidth: true
                text: window.status
                font.family: "Hack Nerd Font"; font.pixelSize: s(11)
                color: window.ok ? Theme.green : Theme.red
                elide: Text.ElideRight
            }
        }
    }
}
