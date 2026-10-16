// TodoPanel — the Todo plugin's panel (equisdots plugin standard).
//
// Loaded by the shell's panel host from ui/plugins/todopanel/ (manifest
// provides.panels.todo); the qs.* imports resolve against the shell tree. All
// reads/writes go through scripts/todopanel.sh (bash), which owns the file
// ~/.local/share/equisdots/todo.txt (one task per line; a line starting with
// "x " is done). The same file feeds the Todo bar module (todobar).
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

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/todopanel/scripts/todopanel.sh"

    ListModel { id: todoModel }
    property int openCount: 0
    property int totalCount: 0

    function closeSelf() {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
    }

    // ── data ───────────────────────────────────────────────────────────────
    function refresh() {
        lister.running = false;
        lister.running = true;
    }

    function parse(txt) {
        todoModel.clear();
        let open = 0, total = 0;
        const lines = (txt || "").split("\n");
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (line === "") continue;
            const parts = line.split("\t");
            if (parts.length < 3) continue;
            const idx = parseInt(parts[0]);
            if (isNaN(idx)) continue;
            const done = parts[1] === "1";
            todoModel.append({ idx: idx, done: done, text: parts.slice(2).join("\t") });
            total++;
            if (!done) open++;
        }
        window.openCount = open;
        window.totalCount = total;
    }

    function addTask(text) {
        const t = (text || "").replace(/^\s+|\s+$/g, "");
        if (t === "") return;
        mutator.command = ["bash", window.scriptPath, "add", t];
        mutator.running = false;
        mutator.running = true;
    }

    function toggleTask(idx) {
        mutator.command = ["bash", window.scriptPath, "toggle", String(idx)];
        mutator.running = false;
        mutator.running = true;
    }

    function deleteTask(idx) {
        mutator.command = ["bash", window.scriptPath, "delete", String(idx)];
        mutator.running = false;
        mutator.running = true;
    }

    Process {
        id: lister
        command: ["bash", window.scriptPath, "list"]
        running: true
        stdout: StdioCollector { onStreamFinished: window.parse(this.text) }
    }

    Process {
        id: mutator
        running: false
        stdout: StdioCollector { onStreamFinished: window.refresh() }
    }

    Timer {
        id: focusTimer
        interval: 60
        running: true
        repeat: false
        onTriggered: addField.forceActiveFocus()
    }

    Keys.onEscapePressed: (event) => { window.closeSelf(); event.accepted = true; }

    // ── UI ─────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusXl
        color: Theme.glassFill
        border.width: 1
        border.color: Theme.outlineVariant
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: s(14)
            spacing: s(10)

            // ── header ─────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.gapSm
                Text { text: "\uf0ca"; font.family: "Hack Nerd Font"; font.pixelSize: s(18); color: Theme.mauve }
                Text { Layout.fillWidth: true; text: "Todo"; font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: s(18); color: Theme.text }
                Text {
                    text: window.openCount + " / " + window.totalCount
                    font.family: "Hack Nerd Font"; font.pixelSize: s(12); color: Theme.subtext0
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // ── add row ────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: s(42)
                radius: Theme.radiusMd
                color: Theme.surfaceContainerHigh
                border.width: 1
                border.color: addField.activeFocus ? Theme.mauve : Theme.outlineVariant
                Behavior on border.color { ColorAnimation { duration: Theme.durShort } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: s(12)
                    anchors.rightMargin: s(8)
                    spacing: Theme.gapSm

                    TextField {
                        id: addField
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        background: Item {}
                        color: Theme.text
                        font.family: "Hack Nerd Font"
                        font.pixelSize: s(14)
                        placeholderText: "New task"
                        placeholderTextColor: Theme.subtext0
                        verticalAlignment: TextInput.AlignVCenter
                        focus: true
                        onAccepted: {
                            window.addTask(addField.text);
                            addField.text = "";
                        }
                        Keys.onEscapePressed: (event) => { window.closeSelf(); event.accepted = true; }
                    }

                    Rectangle {
                        Layout.preferredWidth: s(32)
                        Layout.preferredHeight: s(32)
                        radius: Theme.radiusSm
                        color: addMa.containsMouse ? Theme.stateLayer(Theme.mauve, 0.2) : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.durShort } }
                        Text { anchors.centerIn: parent; text: "\uf067"; font.family: "Hack Nerd Font"; font.pixelSize: s(15); color: addMa.containsMouse ? Theme.mauve : Theme.subtext0 }
                        MouseArea {
                            id: addMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { window.addTask(addField.text); addField.text = ""; }
                        }
                    }
                }
            }

            // ── list ───────────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: todoList
                    anchors.fill: parent
                    visible: todoModel.count > 0
                    model: todoModel
                    spacing: s(6)
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Item {
                        id: row
                        required property int idx
                        required property bool done
                        required property string text
                        width: todoList.width
                        height: window.s(42)

                        Rectangle {
                            id: rowBg
                            anchors.fill: parent
                            radius: Theme.radiusMd
                            color: Theme.surfaceContainer
                            border.width: 1
                            border.color: Theme.outlineVariant
                            clip: true

                            // Row click toggles done (declared first so nested
                            // controls below paint/hit-test on top of it).
                            MouseArea {
                                id: rowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: window.toggleTask(row.idx)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: s(8)
                                anchors.leftMargin: s(12)
                                spacing: Theme.gapSm

                                Rectangle {
                                    Layout.preferredWidth: s(22)
                                    Layout.preferredHeight: s(22)
                                    radius: Theme.radiusSm
                                    color: row.done ? Theme.stateLayer(Theme.green, 0.18) : "transparent"
                                    border.width: 1
                                    border.color: row.done ? Theme.green : Theme.outline
                                    Text {
                                        anchors.centerIn: parent
                                        visible: row.done
                                        text: "\uf00c"
                                        font.family: "Hack Nerd Font"
                                        font.pixelSize: s(11)
                                        color: Theme.green
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: row.text
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: s(13)
                                    color: row.done ? Theme.subtext0 : Theme.text
                                    font.strikeout: row.done
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Item {
                                    Layout.preferredWidth: s(26)
                                    Layout.preferredHeight: s(26)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uf1f8"
                                        font.family: "Hack Nerd Font"
                                        font.pixelSize: s(13)
                                        color: trashMa.containsMouse ? Theme.red : Theme.subtext0
                                        Behavior on color { ColorAnimation { duration: Theme.durShort } }
                                    }
                                    MouseArea {
                                        id: trashMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: window.deleteTask(row.idx)
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: todoModel.count === 0
                    text: "No tasks yet"
                    font.family: "Hack Nerd Font"
                    font.pixelSize: s(13)
                    color: Theme.subtext0
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Click a task to toggle it done - use the trash to delete"
                font.family: "Hack Nerd Font"
                font.pixelSize: s(10)
                color: Theme.subtext0
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
