// ColorPicker — the Color Picker plugin's panel (equisdots plugin standard).
//
// Loaded by the shell's panel host from ui/plugins/colorpicker/ (manifest
// provides.panels.colors). "Pick" runs scripts/colorpicker.sh (hyprpicker -a),
// which also prepends the colour to the plugin's own settings history; the
// panel renders the last 12 picks as swatches and copies a clicked hex with
// wl-copy.
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

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/colorpicker/scripts/colorpicker.sh"

    property string currentHex: "#000000"
    property var history: []
    property string status: ""

    function contrast(c) {
        let col = Qt.color(c);
        let lum = 0.299 * col.r + 0.587 * col.g + 0.114 * col.b;
        return lum > 0.6 ? "#11111b" : "#ffffff";
    }

    // ── history reader (scripts/colorpicker.sh list) ─────────────────────────
    Process {
        id: listProc
        command: ["bash", window.scriptPath, "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let out = (this.text || "").trim();
                let lines = out.length ? out.split("\n").filter(x => x.length > 0) : [];
                window.history = lines;
                if (window.currentHex === "#000000" && lines.length > 0)
                    window.currentHex = lines[0];
            }
        }
    }

    function refresh() {
        listProc.running = false;
        listProc.running = true;
    }

    // ── picker (scripts/colorpicker.sh pick) ─────────────────────────────────
    Process {
        id: pickProc
        command: ["bash", window.scriptPath, "pick"]
        stdout: StdioCollector {
            onStreamFinished: {
                let hex = (this.text || "").trim();
                if (hex.length > 0) {
                    window.currentHex = hex;
                    window.status = "Picked " + hex;
                    window.refresh();
                } else {
                    window.status = "Pick cancelled";
                }
                statusTimer.restart();
            }
        }
    }

    // ── clipboard copy (wl-copy stdin, no shell quoting) ─────────────────────
    // Data is written once wl-copy has started; stdin is then closed so it sees
    // EOF and finishes.
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

    function copyHex(hex) {
        copyProc.pending = hex;
        copyProc.running = false;
        copyProc.stdinEnabled = true;
        copyProc.running = true;
        window.status = "Copied " + hex;
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
            spacing: s(12)

            RowLayout {
                Layout.fillWidth: true
                spacing: s(10)
                Text {
                    text: "Color Picker"
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

            // ── current colour ────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: s(16)

                Rectangle {
                    Layout.preferredWidth: s(110)
                    Layout.preferredHeight: s(110)
                    radius: Theme.radiusLg
                    color: window.currentHex
                    border.width: 1
                    border.color: Theme.outlineVariant

                    Text {
                        anchors.centerIn: parent
                        text: window.currentHex.toUpperCase()
                        font.family: "Hack Nerd Font"; font.weight: Font.Bold; font.pixelSize: s(13)
                        color: window.contrast(window.currentHex)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: s(6)

                    Text {
                        text: "Last picked"
                        font.family: "Hack Nerd Font"; font.pixelSize: s(11)
                        color: Theme.subtext0
                    }
                    Text {
                        text: window.currentHex
                        font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: s(24)
                        color: Theme.text
                    }

                    Button {
                        id: pickBtn
                        text: "Pick"
                        implicitWidth: s(96)
                        implicitHeight: s(38)
                        padding: 0
                        onClicked: { pickProc.running = false; pickProc.running = true; }
                        font.family: "Hack Nerd Font"; font.pixelSize: s(14); font.weight: Font.Bold

                        background: Rectangle {
                            radius: Theme.radiusMd
                            color: pickBtn.down
                                ? Theme.stateLayer(Theme.mauve, Theme.statePress)
                                : (pickBtn.hovered ? Theme.stateLayer(Theme.mauve, Theme.stateHover) : Theme.surfaceContainerHigh)
                            border.width: 1
                            border.color: Theme.outlineVariant
                        }
                        contentItem: Text {
                            text: pickBtn.text
                            font: pickBtn.font
                            color: Theme.text
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Text {
                        text: "Runs hyprpicker -a and copies the result"
                        font.family: "Hack Nerd Font"; font.pixelSize: s(10)
                        color: Theme.subtext0
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.outlineVariant
            }

            Text {
                text: "History"
                font.family: "Hack Nerd Font"; font.weight: Font.Bold; font.pixelSize: s(13)
                color: Theme.text
            }

            Grid {
                id: histGrid
                Layout.fillWidth: true
                columns: 6
                spacing: s(8)

                Repeater {
                    model: window.history
                    delegate: Rectangle {
                        width: s(72)
                        height: s(56)
                        radius: Theme.radiusMd
                        color: modelData
                        border.width: 1
                        border.color: Theme.outlineVariant

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.copyHex(modelData)
                        }
                    }
                }
            }

            Text {
                visible: window.history.length === 0
                text: "No picks yet"
                font.family: "Hack Nerd Font"; font.pixelSize: s(12)
                color: Theme.subtext0
            }

            Item { Layout.fillHeight: true }

            Text {
                Layout.fillWidth: true
                text: window.history.length + " saved - click a swatch to copy"
                font.family: "Hack Nerd Font"; font.pixelSize: s(11)
                color: Theme.subtext0
            }
        }
    }
}
