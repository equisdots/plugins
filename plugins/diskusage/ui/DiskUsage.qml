// DiskUsage — the Disks plugin's panel (equisdots plugin standard).
//
// Loaded by the shell's panel host from ui/plugins/diskusage/ (manifest
// provides.panels.df); the qs.* imports resolve against the shell tree.
// The filesystem list comes from scripts/diskusage.sh (`df -P -h` filtered);
// the refresh interval lives in settings.json -> "diskusage". Bar colour is
// decided by the use% threshold (green / yellow / red).
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
        let c = Config.rawSettings["diskusage"];
        return (c && typeof c === "object") ? c : {};
    }
    readonly property int refreshMs: {
        let v = Number(cfg.refreshMs);
        return (v >= 2000 && v <= 3600000) ? v : 15000;
    }

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/diskusage/scripts/diskusage.sh"

    ListModel { id: fsModel }
    property int fsCount: 0
    property bool scanning: false

    Process {
        id: reader
        running: false
        command: ["bash", window.scriptPath]
        stdout: StdioCollector {
            onStreamFinished: {
                fsModel.clear();
                let lines = String(this.text || "").split("\n");
                let n = 0;
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (line === "") continue;
                    let parts = line.split("|");
                    if (parts.length < 5) continue;
                    fsModel.append({
                        mount: parts[0],
                        used: parts[1],
                        size: parts[2],
                        pct: Math.max(0, Math.min(100, parseInt(parts[3]) || 0)),
                        fs: parts[4]
                    });
                    n++;
                }
                window.fsCount = n;
                window.scanning = false;
            }
        }
    }

    function refresh() {
        window.scanning = true;
        reader.running = false;
        reader.running = true;
    }

    function colorFor(pct) {
        if (pct < 70) return Theme.green;
        if (pct < 90) return Theme.yellow;
        return Theme.red;
    }

    Timer {
        interval: window.refreshMs
        running: true
        repeat: true
        onTriggered: window.refresh()
    }

    Component.onCompleted: window.refresh()

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
                    text: "\uF0A0"
                    font.family: "Hack Nerd Font"; font.pixelSize: s(18)
                    color: Theme.mauve
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: "Disks"
                        font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: s(18)
                        color: Theme.text
                    }
                    Text {
                        text: window.fsCount === 1 ? "1 filesystem" : window.fsCount + " filesystems"
                        font.family: "Hack Nerd Font"; font.pixelSize: s(11)
                        color: Theme.subtext0
                    }
                }

                Rectangle {
                    Layout.preferredWidth: s(30)
                    Layout.preferredHeight: s(30)
                    radius: Theme.radiusSm
                    color: refreshMa.containsMouse
                        ? Theme.stateLayer(Theme.mauve, Theme.stateHover)
                        : Theme.surfaceContainer
                    Behavior on color { ColorAnimation { duration: Theme.durShort } }

                    Text {
                        anchors.centerIn: parent
                        text: "\uF021"
                        font.family: "Hack Nerd Font"; font.pixelSize: s(13)
                        color: Theme.mauve
                        RotationAnimator on rotation {
                            running: window.scanning
                            loops: Animation.Infinite
                            from: 0; to: 360; duration: 900
                        }
                    }
                    MouseArea {
                        id: refreshMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.refresh()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.outlineVariant
            }

            // --- filesystem list ---
            ListView {
                id: fsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: s(6)
                model: fsModel
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { implicitWidth: s(4); radius: s(2); color: Theme.surface2; opacity: 0.5 }
                }

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: s(64)
                    radius: Theme.radiusMd
                    color: fsHover.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow
                    Behavior on color { ColorAnimation { duration: Theme.durShort } }

                    HoverHandler { id: fsHover }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: s(10)
                        spacing: s(6)

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: s(8)

                            Text {
                                text: "\uF0A0"
                                font.family: "Hack Nerd Font"; font.pixelSize: s(12)
                                color: window.colorFor(modelData.pct)
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.mount
                                font.family: "Hack Nerd Font"; font.pixelSize: s(13); font.weight: Font.Bold
                                color: Theme.text
                                elide: Text.ElideMiddle
                            }
                            Text {
                                text: modelData.used + " / " + modelData.size
                                font.family: "Hack Nerd Font"; font.pixelSize: s(11)
                                color: Theme.subtext0
                            }
                            Text {
                                Layout.preferredWidth: s(40)
                                horizontalAlignment: Text.AlignRight
                                text: modelData.pct + "%"
                                font.family: "Hack Nerd Font"; font.pixelSize: s(12); font.weight: Font.Bold
                                color: window.colorFor(modelData.pct)
                            }
                        }

                        // usage bar
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: s(6)
                            radius: Theme.radiusFull
                            color: Theme.surfaceContainerHighest
                            clip: true

                            Rectangle {
                                width: parent.width * (modelData.pct / 100)
                                height: parent.height
                                radius: Theme.radiusFull
                                color: window.colorFor(modelData.pct)
                                Behavior on width { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: Theme.durMedium } }
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: fsModel.count === 0
                horizontalAlignment: Text.AlignHCenter
                text: "No filesystems reported."
                font.family: "Hack Nerd Font"; font.pixelSize: s(11)
                color: Theme.overlay0
            }
        }
    }
}
