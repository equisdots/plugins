// Bookmarks — the Bookmarks plugin's panel (equisdots plugin standard).
//
// Loaded by the shell's panel host from ui/plugins/bookmarks/ (manifest
// provides.panels.bookmarks); the qs.* imports resolve against the shell tree.
// Links live in the plugin's OWN settings file
// ~/.config/hypr/plugins/bookmarks/settings.json under scope "bookmarks",
// key "links" (array of { label, url }), seeded from defaults.json. Reading and
// appending go through scripts/bookmarks.sh (jq + atomic mv); opening a link
// uses xdg-open.
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

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/bookmarks/scripts/bookmarks.sh"

    ListModel { id: bookmarkModel }

    function closeSelf() {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
    }

    // ── data ───────────────────────────────────────────────────────────────
    function refresh() {
        lister.running = false;
        lister.running = true;
    }

    function parse(txt) {
        bookmarkModel.clear();
        let arr = [];
        try { arr = JSON.parse((txt || "").trim() || "[]"); } catch (e) { arr = []; }
        if (!Array.isArray(arr)) arr = [];
        for (let i = 0; i < arr.length; i++) {
            const it = arr[i] || {};
            if (!it.url) continue;
            bookmarkModel.append({ label: String(it.label || it.url), url: String(it.url) });
        }
    }

    function addBookmark() {
        const url = (urlField.text || "").replace(/^\s+|\s+$/g, "");
        if (url === "") return;
        const label = (labelField.text || "").replace(/^\s+|\s+$/g, "") || url;
        adder.command = ["bash", window.scriptPath, "add", label, url];
        adder.running = false;
        adder.running = true;
    }

    function openUrl(url) {
        if (!url) return;
        Quickshell.execDetached(["xdg-open", url]);
    }

    Process {
        id: lister
        command: ["bash", window.scriptPath, "list"]
        running: true
        stdout: StdioCollector { onStreamFinished: window.parse(this.text) }
    }

    Process {
        id: adder
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                labelField.text = "";
                urlField.text = "";
                window.refresh();
            }
        }
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
                Text { text: "\uf02e"; font.family: "Hack Nerd Font"; font.pixelSize: s(18); color: Theme.mauve }
                Text { Layout.fillWidth: true; text: "Bookmarks"; font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: s(18); color: Theme.text }
                Text { text: bookmarkModel.count + " links"; font.family: "Hack Nerd Font"; font.pixelSize: s(12); color: Theme.subtext0; verticalAlignment: Text.AlignVCenter }
            }

            // ── add row ────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.gapSm

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: s(180)
                    Layout.preferredHeight: s(40)
                    radius: Theme.radiusMd
                    color: Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: labelField.activeFocus ? Theme.mauve : Theme.outlineVariant
                    Behavior on border.color { ColorAnimation { duration: Theme.durShort } }
                    TextField {
                        id: labelField
                        anchors.fill: parent
                        anchors.leftMargin: s(10)
                        anchors.rightMargin: s(10)
                        background: Item {}
                        color: Theme.text
                        font.family: "Hack Nerd Font"
                        font.pixelSize: s(13)
                        placeholderText: "Label"
                        placeholderTextColor: Theme.subtext0
                        verticalAlignment: TextInput.AlignVCenter
                        onAccepted: urlField.forceActiveFocus()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: s(220)
                    Layout.preferredHeight: s(40)
                    radius: Theme.radiusMd
                    color: Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: urlField.activeFocus ? Theme.mauve : Theme.outlineVariant
                    Behavior on border.color { ColorAnimation { duration: Theme.durShort } }
                    TextField {
                        id: urlField
                        anchors.fill: parent
                        anchors.leftMargin: s(10)
                        anchors.rightMargin: s(10)
                        background: Item {}
                        color: Theme.text
                        font.family: "Hack Nerd Font"
                        font.pixelSize: s(13)
                        placeholderText: "https://..."
                        placeholderTextColor: Theme.subtext0
                        verticalAlignment: TextInput.AlignVCenter
                        onAccepted: window.addBookmark()
                        Keys.onEscapePressed: (event) => { window.closeSelf(); event.accepted = true; }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: s(40)
                    Layout.preferredHeight: s(40)
                    radius: Theme.radiusMd
                    color: addMa.containsMouse ? Theme.stateLayer(Theme.mauve, 0.2) : "transparent"
                    border.width: 1
                    border.color: Theme.outlineVariant
                    Behavior on color { ColorAnimation { duration: Theme.durShort } }
                    Text { anchors.centerIn: parent; text: "\uf067"; font.family: "Hack Nerd Font"; font.pixelSize: s(15); color: addMa.containsMouse ? Theme.mauve : Theme.subtext0 }
                    MouseArea { id: addMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: window.addBookmark() }
                }
            }

            // ── list ───────────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: bookmarkList
                    anchors.fill: parent
                    visible: bookmarkModel.count > 0
                    model: bookmarkModel
                    spacing: s(6)
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Rectangle {
                        id: row
                        required property string label
                        required property string url
                        width: bookmarkList.width
                        height: window.s(48)
                        radius: Theme.radiusMd
                        color: rowMa.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                        border.width: 1
                        border.color: Theme.outlineVariant
                        Behavior on color { ColorAnimation { duration: Theme.durShort } }
                        clip: true

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: s(8)
                            anchors.leftMargin: s(12)
                            spacing: Theme.gapSm

                            Text { text: "\uf02e"; font.family: "Hack Nerd Font"; font.pixelSize: s(14); color: Theme.mauve }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: row.label
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: s(14)
                                    font.weight: Font.Bold
                                    color: Theme.text
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: row.url
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: s(11)
                                    color: Theme.subtext0
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }

                            Text {
                                visible: rowMa.containsMouse
                                text: "\uf35d"
                                font.family: "Hack Nerd Font"
                                font.pixelSize: s(13)
                                color: Theme.mauve
                            }
                        }

                        MouseArea {
                            id: rowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.openUrl(row.url)
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: bookmarkModel.count === 0
                    text: "No links yet - add one above"
                    font.family: "Hack Nerd Font"
                    font.pixelSize: s(13)
                    color: Theme.subtext0
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Click a link to open it with xdg-open"
                font.family: "Hack Nerd Font"
                font.pixelSize: s(10)
                color: Theme.subtext0
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
