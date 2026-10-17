// SnippetBox — the Snippets (snippetbox) plugin's panel (equisdots plugin
// standard).
//
// Loaded by the shell's panel host from ui/plugins/snippetbox/ (manifest
// provides.panels.snippets). Snippets live in the plugin's own settings file
// (~/.config/hypr/plugins/snippetbox/settings.json, scope "snippetbox",
// key "items", seeded by defaults.json); scripts/snippetbox.sh reads, appends
// and deletes entries and writes the file atomically (jq + mv).
import QtQuick
import QtQuick.Window
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

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/snippetbox/scripts/snippetbox.sh"

    property var items: []
    property string status: ""
    property bool adding: false

    function parseItems(text) {
        try {
            let arr = JSON.parse((text || "").trim() || "[]");
            if (Array.isArray(arr)) window.items = arr;
        } catch (e) {}
    }

    // ── list (scripts/snippetbox.sh list) ────────────────────────────────────
    Process {
        id: listProc
        command: ["bash", window.scriptPath, "list"]
        running: true
        stdout: StdioCollector { onStreamFinished: window.parseItems(this.text) }
    }

    function refresh() {
        listProc.running = false;
        listProc.running = true;
    }

    // ── add (scripts/snippetbox.sh add, JSON on stdin) ───────────────────────
    // The JSON is written once the process has started; stdin is then closed so
    // the script's `cat` sees EOF and finishes.
    Process {
        id: addProc
        command: ["bash", window.scriptPath, "add"]
        stdinEnabled: true
        property string pending: ""
        onStarted: {
            if (addProc.pending !== "") {
                addProc.write(addProc.pending);
                addProc.pending = "";
                addProc.stdinEnabled = false;
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                window.parseItems(this.text);
                labelField.text = "";
                textArea.text = "";
                window.adding = false;
                window.status = "Added";
                statusTimer.restart();
            }
        }
    }

    function add() {
        let label = labelField.text.trim();
        let text = textArea.text;
        if (label === "" && text.trim() === "") return;
        addProc.pending = JSON.stringify({ label: label, text: text });
        addProc.running = false;
        addProc.stdinEnabled = true;
        addProc.running = true;
    }

    // ── remove (scripts/snippetbox.sh remove INDEX) ──────────────────────────
    Process {
        id: removeProc
        stdout: StdioCollector {
            onStreamFinished: {
                window.parseItems(this.text);
                window.status = "Deleted";
                statusTimer.restart();
            }
        }
    }

    function remove(i) {
        removeProc.running = false;
        removeProc.command = ["bash", window.scriptPath, "remove", String(i)];
        removeProc.running = true;
    }

    // ── clipboard copy (wl-copy stdin, no shell quoting) ─────────────────────
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

    function copyItem(item) {
        copyProc.pending = item.text;
        copyProc.running = false;
        copyProc.stdinEnabled = true;
        copyProc.running = true;
        window.status = "Copied " + (item.label !== "" ? item.label : "snippet");
        statusTimer.restart();
    }

    Timer { id: statusTimer; interval: 1600; onTriggered: window.status = "" }

    function closeSelf() {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
    }
    Keys.onEscapePressed: (event) => {
        if (window.adding) { window.adding = false; event.accepted = true; return; }
        window.closeSelf();
        event.accepted = true;
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

            // ── header ────────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: s(10)

                Text {
                    text: "Snippets"
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
                Button {
                    id: addBtn
                    text: window.adding ? "Close" : "Add"
                    implicitWidth: s(84)
                    implicitHeight: s(32)
                    padding: 0
                    onClicked: window.adding = !window.adding
                    font.family: "Hack Nerd Font"; font.pixelSize: s(13); font.weight: Font.Bold
                    background: Rectangle {
                        radius: Theme.radiusMd
                        color: addBtn.down ? Theme.stateLayer(Theme.mauve, Theme.statePress)
                            : (addBtn.hovered ? Theme.stateLayer(Theme.mauve, Theme.stateHover) : Theme.surfaceContainerHigh)
                        border.width: 1; border.color: Theme.outlineVariant
                    }
                    contentItem: Text {
                        text: addBtn.text
                        font: addBtn.font
                        color: Theme.text
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // ── add form ──────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                visible: window.adding
                implicitHeight: form.implicitHeight + s(24)
                radius: Theme.radiusLg
                color: Theme.surfaceContainerLow
                border.width: 1
                border.color: Theme.outlineVariant

                ColumnLayout {
                    id: form
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: s(12)
                    spacing: s(8)

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: s(38)
                        radius: Theme.radiusMd
                        color: Theme.surfaceContainer
                        border.width: 1
                        border.color: labelField.activeFocus ? Theme.mauve : Theme.outlineVariant
                        TextField {
                            id: labelField
                            anchors.fill: parent
                            anchors.leftMargin: s(12); anchors.rightMargin: s(12)
                            background: Item {}
                            color: Theme.text
                            font.family: "Hack Nerd Font"; font.pixelSize: s(14)
                            placeholderText: "Label"
                            placeholderTextColor: Theme.subtext0
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: s(96)
                        radius: Theme.radiusMd
                        color: Theme.surfaceContainer
                        border.width: 1
                        border.color: textArea.activeFocus ? Theme.mauve : Theme.outlineVariant
                        TextArea {
                            id: textArea
                            anchors.fill: parent
                            anchors.margins: s(8)
                            background: Item {}
                            color: Theme.text
                            font.family: "Hack Nerd Font"; font.pixelSize: s(14)
                            placeholderText: "Text"
                            placeholderTextColor: Theme.subtext0
                            wrapMode: TextArea.Wrap
                            selectByMouse: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: s(8)
                        Item { Layout.fillWidth: true }
                        Button {
                            id: cancelBtn
                            text: "Cancel"
                            implicitWidth: s(84); implicitHeight: s(32); padding: 0
                            onClicked: window.adding = false
                            font.family: "Hack Nerd Font"; font.pixelSize: s(13)
                            background: Rectangle {
                                radius: Theme.radiusMd
                                color: cancelBtn.hovered ? Theme.stateLayer(Theme.text, Theme.stateHover) : Theme.surfaceContainer
                                border.width: 1; border.color: Theme.outlineVariant
                            }
                            contentItem: Text {
                                text: cancelBtn.text; font: cancelBtn.font; color: Theme.subtext0
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }
                        }
                        Button {
                            id: saveBtn
                            text: "Save"
                            implicitWidth: s(84); implicitHeight: s(32); padding: 0
                            onClicked: window.add()
                            font.family: "Hack Nerd Font"; font.pixelSize: s(13); font.weight: Font.Bold
                            background: Rectangle {
                                radius: Theme.radiusMd
                                color: saveBtn.down ? Theme.stateLayer(Theme.green, Theme.statePress)
                                    : (saveBtn.hovered ? Theme.stateLayer(Theme.green, Theme.stateHover) : Theme.surfaceContainerHigh)
                                border.width: 1; border.color: Theme.outlineVariant
                            }
                            contentItem: Text {
                                text: saveBtn.text; font: saveBtn.font; color: Theme.text
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Saved"
                    font.family: "Hack Nerd Font"; font.weight: Font.Bold; font.pixelSize: s(13)
                    color: Theme.text
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: window.items.length + " snippets"
                    font.family: "Hack Nerd Font"; font.pixelSize: s(11)
                    color: Theme.subtext0
                }
            }

            // ── list ──────────────────────────────────────────────────────────
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: window.items
                spacing: s(8)
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { active: true; policy: ScrollBar.AsNeeded }

                delegate: Item {
                    id: row
                    width: list.width
                    height: s(66)

                    readonly property var item: modelData

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusMd
                        color: hov.containsMouse ? Theme.stateLayer(Theme.mauve, Theme.stateHover) : Theme.surfaceContainer
                        border.width: 1
                        border.color: Theme.outlineVariant
                    }

                    ColumnLayout {
                        anchors.left: parent.left
                        anchors.right: trashBtn.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: s(12)
                        anchors.rightMargin: s(8)
                        spacing: s(2)

                        Text {
                            Layout.fillWidth: true
                            text: row.item && row.item.label !== "" ? row.item.label : "(untitled)"
                            font.family: "Hack Nerd Font"; font.weight: Font.Bold; font.pixelSize: s(14)
                            color: Theme.text
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: row.item ? row.item.text : ""
                            font.family: "Hack Nerd Font"; font.pixelSize: s(11)
                            color: Theme.subtext0
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        id: trashBtn
                        z: 2
                        anchors.right: parent.right
                        anchors.rightMargin: s(10)
                        anchors.verticalCenter: parent.verticalCenter
                        width: s(30); height: s(30)
                        radius: Theme.radiusSm
                        color: trashMa.containsMouse ? Theme.stateLayer(Theme.red, Theme.stateHover) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰆴"
                            font.family: "Hack Nerd Font"; font.pixelSize: s(15)
                            color: trashMa.containsMouse ? Theme.red : Theme.subtext0
                        }
                        MouseArea {
                            id: trashMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.remove(index)
                        }
                    }

                    MouseArea {
                        id: hov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (row.item) window.copyItem(row.item)
                    }
                }
            }

            Text {
                visible: window.items.length === 0
                Layout.fillWidth: true
                text: "No snippets yet - use Add to create one"
                font.family: "Hack Nerd Font"; font.pixelSize: s(12)
                color: Theme.subtext0
            }
        }
    }
}
