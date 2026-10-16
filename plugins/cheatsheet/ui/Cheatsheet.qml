import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

// Keybind Cheatsheet — a searchable list of every active keybind (core + plugins),
// read from `hyprctl binds`. Opened with `qs_manager.sh toggle cheatsheet`.
Item {
    id: window
    focus: true

    Scaler { id: sc; currentWidth: Screen.width }
    function s(v) { return sc.s(v); }

    property var rows: []
    property string query: ""
    readonly property var filtered: {
        let q = window.query.trim().toLowerCase();
        if (q === "") return window.rows;
        return window.rows.filter(r => (r.keys + " " + r.label).toLowerCase().indexOf(q) !== -1);
    }

    Process {
        id: reader
        command: ["bash", Quickshell.env("HOME") + "/.config/hypr/plugins/cheatsheet/scripts/cheatsheet.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = [];
                (this.text || "").trim().split("\n").forEach(l => {
                    if (l === "") return;
                    let p = l.split("|");
                    out.push({ keys: p[0] || "", label: p[1] || "", disp: p[2] || "" });
                });
                window.rows = out;
            }
        }
    }
    Component.onCompleted: reader.running = true

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusXl
        color: Theme.glassFill
        border.width: 1
        border.color: Theme.outlineVariant

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: s(16)
            spacing: s(10)

            Text { text: "KEYBINDS"; font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: s(18); color: Theme.text }

            TextField {
                id: search
                Layout.fillWidth: true
                placeholderText: "Filter…"
                color: Theme.text
                placeholderTextColor: Theme.subtext0
                font.family: "Hack Nerd Font"; font.pixelSize: s(12)
                leftPadding: s(12); rightPadding: s(12)
                onTextChanged: window.query = text
                background: Rectangle { radius: Theme.radiusMd; color: Theme.surfaceContainer; border.width: 1; border.color: Theme.outlineVariant }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: list.implicitHeight
                Column {
                    id: list
                    width: parent.width
                    spacing: s(2)
                    Repeater {
                        model: window.filtered
                        delegate: Rectangle {
                            required property var modelData
                            width: list.width
                            implicitHeight: s(28)
                            radius: Theme.radiusSm
                            color: hov.containsMouse ? Theme.surfaceContainer : "transparent"
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: s(8); anchors.rightMargin: s(8)
                                spacing: s(10)
                                Text {
                                    text: modelData.keys
                                    Layout.preferredWidth: s(230)
                                    font.family: "Hack Nerd Font"; font.pixelSize: s(11); font.bold: true
                                    color: Theme.mauve; elide: Text.ElideRight
                                }
                                Text {
                                    text: modelData.label
                                    Layout.fillWidth: true
                                    font.family: "Hack Nerd Font"; font.pixelSize: s(11)
                                    color: Theme.text; elide: Text.ElideRight
                                }
                            }
                            MouseArea { id: hov; anchors.fill: parent; hoverEnabled: true }
                        }
                    }
                }
            }
            Text { text: window.filtered.length + " binds"; font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: Theme.subtext0 }
        }
    }
}
