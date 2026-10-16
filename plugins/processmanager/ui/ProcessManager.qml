// ProcessManager — the Processes plugin's panel (equisdots plugin standard).
//
// Loaded by the shell's panel host from ui/plugins/processmanager/ (manifest
// provides.panels.procman); the qs.* imports resolve against the shell tree.
// The table comes from scripts/processmanager.sh, the kill button from
// scripts/kill.sh (both under ~/.config/hypr/plugins/processmanager/scripts/);
// the refresh interval lives in settings.json -> "processmanager".
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
        let c = Config.rawSettings["processmanager"];
        return (c && typeof c === "object") ? c : {};
    }
    readonly property int refreshMs: {
        let v = Number(cfg.refreshMs);
        return (v >= 500 && v <= 60000) ? v : 2000;
    }

    readonly property string listPath: Quickshell.env("HOME") + "/.config/hypr/plugins/processmanager/scripts/processmanager.sh"
    readonly property string killPath: Quickshell.env("HOME") + "/.config/hypr/plugins/processmanager/scripts/kill.sh"

    ListModel { id: procModel }
    property real totalCpu: 0
    property real totalMem: 0
    property int procCount: 0
    property bool busy: false

    Process {
        id: reader
        running: false
        command: ["bash", window.listPath]
        stdout: StdioCollector {
            onStreamFinished: {
                procModel.clear();
                let lines = String(this.text || "").split("\n");
                let cpu = 0, mem = 0, n = 0;
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (line === "") continue;
                    let parts = line.split(/\s+/);
                    if (parts.length < 4) continue;
                    let pid = parseInt(parts[0]);
                    if (isNaN(pid)) continue; // skips the ps header / non-rows
                    let pcpu = parseFloat(parts[1]) || 0;
                    let pmem = parseFloat(parts[2]) || 0;
                    procModel.append({
                        pid: pid,
                        cpu: pcpu,
                        mem: pmem,
                        name: parts.slice(3).join(" ")
                    });
                    cpu += pcpu; mem += pmem; n++;
                }
                window.totalCpu = cpu;
                window.totalMem = mem;
                window.procCount = n;
                window.busy = false;
            }
        }
    }

    function refresh() {
        window.busy = true;
        reader.running = false;
        reader.running = true;
    }

    function killProc(pid) {
        Quickshell.execDetached(["bash", window.killPath, String(pid)]);
        // Give the signal a moment, then re-read the table.
        killDelay.restart();
    }

    Timer {
        interval: window.refreshMs
        running: true
        repeat: true
        onTriggered: window.refresh()
    }

    Timer {
        id: killDelay
        interval: 400
        onTriggered: window.refresh()
    }

    Component.onCompleted: window.refresh()

    function fmt(v) { return (Math.round(v * 10) / 10).toFixed(1) }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusXl
        color: Theme.glassFill
        border.width: 1
        border.color: Theme.outlineVariant

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: s(14)
            spacing: s(8)

            // --- header ---
            RowLayout {
                Layout.fillWidth: true
                spacing: s(10)

                Text {
                    text: "\uF4A1"
                    font.family: "Hack Nerd Font"; font.pixelSize: s(18)
                    color: Theme.mauve
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: "Processes"
                        font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: s(18)
                        color: Theme.text
                    }
                    Text {
                        text: window.procCount + " processes"
                        font.family: "Hack Nerd Font"; font.pixelSize: s(11)
                        color: Theme.subtext0
                    }
                }

                Text {
                    text: "CPU " + window.fmt(window.totalCpu) + "%"
                    font.family: "Hack Nerd Font"; font.pixelSize: s(12); font.weight: Font.Bold
                    color: Theme.blue
                }
                Text {
                    text: "RAM " + window.fmt(window.totalMem) + "%"
                    font.family: "Hack Nerd Font"; font.pixelSize: s(12); font.weight: Font.Bold
                    color: Theme.green
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
                            running: window.busy
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

            // --- column headers ---
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: s(6)
                Layout.rightMargin: s(6)
                spacing: s(8)

                Text { Layout.preferredWidth: s(64); text: "PID"; font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: Theme.overlay0 }
                Text { Layout.fillWidth: true; text: "NAME"; font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: Theme.overlay0 }
                Text { Layout.preferredWidth: s(56); horizontalAlignment: Text.AlignRight; text: "CPU"; font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: Theme.overlay0 }
                Text { Layout.preferredWidth: s(56); horizontalAlignment: Text.AlignRight; text: "MEM"; font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: Theme.overlay0 }
                Item { Layout.preferredWidth: s(28) }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.outlineVariant
            }

            // --- process rows ---
            ListView {
                id: procList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: s(2)
                model: procModel
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
                    height: s(34)
                    radius: Theme.radiusSm
                    color: rowHover.hovered ? Theme.surfaceContainerHigh : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.durShort } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: s(6)
                        anchors.rightMargin: s(6)
                        spacing: s(8)

                        Text {
                            Layout.preferredWidth: s(64)
                            text: modelData.pid
                            font.family: "Hack Nerd Font"; font.pixelSize: s(11)
                            color: Theme.subtext0
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            font.family: "Hack Nerd Font"; font.pixelSize: s(12)
                            color: Theme.text
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.preferredWidth: s(56)
                            horizontalAlignment: Text.AlignRight
                            text: window.fmt(modelData.cpu)
                            font.family: "Hack Nerd Font"; font.pixelSize: s(11)
                            color: modelData.cpu >= 25 ? Theme.red : (modelData.cpu >= 5 ? Theme.yellow : Theme.subtext0)
                        }
                        Text {
                            Layout.preferredWidth: s(56)
                            horizontalAlignment: Text.AlignRight
                            text: window.fmt(modelData.mem)
                            font.family: "Hack Nerd Font"; font.pixelSize: s(11)
                            color: Theme.subtext0
                        }

                        Rectangle {
                            Layout.preferredWidth: s(28)
                            Layout.preferredHeight: s(24)
                            radius: Theme.radiusSm
                            color: killMa.containsMouse
                                ? Theme.stateLayer(Theme.red, 0.22)
                                : Theme.surfaceContainer
                            Behavior on color { ColorAnimation { duration: Theme.durShort } }

                            Text {
                                anchors.centerIn: parent
                                text: "\uF00D"
                                font.family: "Hack Nerd Font"; font.pixelSize: s(12)
                                color: Theme.red
                            }
                            MouseArea {
                                id: killMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: window.killProc(modelData.pid)
                            }
                        }
                    }

                    HoverHandler { id: rowHover }
                }
            }
        }
    }
}
