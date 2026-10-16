import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

// Power Menu — session actions from a popup. Opened with
// `qs_manager.sh toggle power`. Destructive actions ask for a confirm.
Item {
    id: window
    focus: true

    Scaler { id: sc; currentWidth: Screen.width }
    function s(v) { return sc.s(v); }

    property string armed: ""   // which action is awaiting confirmation

    readonly property var actions: [
        { id: "lock",     label: "Lock",     glyph: "󰌾", danger: false },
        { id: "logout",   label: "Log out",  glyph: "󰍃", danger: true },
        { id: "suspend",  label: "Suspend",  glyph: "󰒲", danger: true },
        { id: "reboot",   label: "Reboot",   glyph: "󰜉", danger: true },
        { id: "shutdown", label: "Shutdown", glyph: "󰐥", danger: true }
    ]

    Process { id: proc; property string cmd: ""; command: ["bash", Quickshell.env("HOME") + "/.config/hypr/plugins/power-menu/scripts/power.sh", cmd]; running: false }

    Timer { id: disarm; interval: 2500; onTriggered: window.armed = "" }

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

            Text { text: "SESSION"; font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: s(18); color: Theme.text }

            Repeater {
                model: window.actions
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool armed: window.armed === modelData.id
                    Layout.fillWidth: true
                    implicitHeight: s(52)
                    radius: Theme.radiusLg
                    color: armed ? Theme.stateLayer(Theme.red, 0.18)
                         : (ma.containsMouse ? Theme.stateLayer(modelData.danger ? Theme.red : Theme.mauve, 0.12) : Theme.surfaceContainerLow)
                    border.width: 1
                    border.color: armed ? Theme.red : Theme.outlineVariant

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: s(14); anchors.rightMargin: s(14)
                        spacing: s(12)
                        Text { text: modelData.glyph; font.family: "Hack Nerd Font"; font.pixelSize: s(18); color: armed ? Theme.red : (modelData.danger ? Theme.red : Theme.text) }
                        Text {
                            Layout.fillWidth: true
                            text: armed ? "Confirm " + modelData.label + "?" : modelData.label
                            font.family: "Hack Nerd Font"; font.pixelSize: s(13); font.bold: armed
                            color: armed ? Theme.red : Theme.text
                        }
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.danger && window.armed !== modelData.id) {
                                window.armed = modelData.id; disarm.restart();
                            } else {
                                window.armed = "";
                                proc.cmd = modelData.id; proc.running = false; proc.running = true;
                            }
                        }
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }
    }
}
