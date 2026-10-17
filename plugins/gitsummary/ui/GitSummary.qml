// GitSummary — the Git plugin's panel (equisdots plugin standard).
//
// Loaded by the shell's panel host from ui/plugins/gitsummary/ (manifest
// provides.panels.git); the qs.* imports resolve against the shell tree.
// The repo list comes from the plugin's own scripts/gitsummary.sh (the runtime
// subset at ~/.config/hypr/plugins/gitsummary/scripts/); refresh interval lives
// in settings.json -> "gitsummary". Clicking a row opens a terminal in the repo.
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

    // settings.json -> "gitsummary" (seeded from defaults.json).
    readonly property var cfg: {
        Config.rev;
        let c = Config.rawSettings["gitsummary"];
        return (c && typeof c === "object") ? c : {};
    }
    readonly property int refreshMs: {
        let v = Number(cfg.refreshMs);
        return (v >= 2000 && v <= 3600000) ? v : 15000;
    }

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/gitsummary/scripts/gitsummary.sh"

    ListModel { id: repoModel }
    property int repoCount: 0
    property bool scanning: false
    property string statusText: ""

    Process {
        id: scanner
        running: false
        command: ["bash", window.scriptPath]
        stdout: StdioCollector {
            onStreamFinished: {
                repoModel.clear();
                let lines = String(this.text || "").split("\n");
                let n = 0;
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (line === "") continue;
                    let parts = line.split("|");
                    if (parts.length < 3) continue;
                    let path = parts[0];
                    let segs = path.split("/");
                    repoModel.append({
                        path: path,
                        name: segs.length > 0 ? segs[segs.length - 1] : path,
                        branch: parts[1],
                        dirty: parseInt(parts[2]) || 0
                    });
                    n++;
                }
                window.repoCount = n;
                window.scanning = false;
                window.statusText = n === 1 ? "1 repository" : n + " repositories";
            }
        }
    }

    function refresh() {
        window.scanning = true;
        scanner.running = false;
        scanner.running = true;
    }

    Timer {
        interval: window.refreshMs
        running: true
        repeat: true
        onTriggered: window.refresh()
    }

    // Safe single-quote for embedding a path in `bash -c`.
    function shellQuote(t) {
        return "'" + String(t).replace(/'/g, "'\\''") + "'";
    }

    function openInTerminal(dir) {
        let cmd = "cd " + shellQuote(dir) + " 2>/dev/null || exit 1; "
                + "if command -v xdg-terminal-exec >/dev/null 2>&1; then exec xdg-terminal-exec; "
                + "elif command -v kitty >/dev/null 2>&1; then exec kitty; "
                + "elif command -v foot >/dev/null 2>&1; then exec foot; "
                + "fi";
        Quickshell.execDetached(["bash", "-c", cmd]);
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
                    text: "\uF1D3"
                    font.family: "Hack Nerd Font"
                    font.pixelSize: s(18)
                    color: Theme.mauve
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: "Git"
                        font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: s(18)
                        color: Theme.text
                    }
                    Text {
                        text: window.statusText
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

            // --- repo list ---
            ListView {
                id: repoList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: s(4)
                model: repoModel
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
                    height: s(52)
                    radius: Theme.radiusMd
                    color: rowMa.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.durShort } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: s(10)
                        anchors.rightMargin: s(10)
                        spacing: s(10)

                        Text {
                            text: "\uF07B"
                            font.family: "Hack Nerd Font"; font.pixelSize: s(15)
                            color: modelData.dirty > 0 ? Theme.yellow : Theme.green
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: s(2)

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                font.family: "Hack Nerd Font"; font.pixelSize: s(13); font.weight: Font.Bold
                                color: Theme.text
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.path
                                font.family: "Hack Nerd Font"; font.pixelSize: s(10)
                                color: Theme.subtext0
                                elide: Text.ElideMiddle
                            }
                        }

                        // branch chip
                        Rectangle {
                            Layout.preferredWidth: branchTxt.implicitWidth + s(16)
                            Layout.preferredHeight: s(20)
                            radius: Theme.radiusFull
                            color: Theme.stateLayer(Theme.blue, 0.14)
                            Text {
                                id: branchTxt
                                anchors.centerIn: parent
                                text: modelData.branch
                                font.family: "Hack Nerd Font"; font.pixelSize: s(10)
                                color: Theme.blue
                            }
                        }

                        // dirty chip
                        Rectangle {
                            Layout.preferredWidth: s(30)
                            Layout.preferredHeight: s(20)
                            radius: Theme.radiusFull
                            color: modelData.dirty > 0
                                ? Theme.stateLayer(Theme.red, 0.16)
                                : Theme.stateLayer(Theme.green, 0.14)
                            Text {
                                anchors.centerIn: parent
                                text: modelData.dirty > 0 ? String(modelData.dirty) : "\uF00C"
                                font.family: "Hack Nerd Font"; font.pixelSize: s(10)
                                color: modelData.dirty > 0 ? Theme.red : Theme.green
                            }
                        }
                    }

                    MouseArea {
                        id: rowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.openInTerminal(modelData.path)
                    }
                }
            }

            // --- empty state ---
            Text {
                Layout.fillWidth: true
                visible: repoModel.count === 0
                horizontalAlignment: Text.AlignHCenter
                text: "No git repositories found."
                font.family: "Hack Nerd Font"; font.pixelSize: s(11)
                color: Theme.overlay0
            }

            Text {
                Layout.fillWidth: true
                text: "Click a repository to open a terminal there."
                font.family: "Hack Nerd Font"; font.pixelSize: s(10)
                color: Theme.overlay0
            }
        }
    }
}
