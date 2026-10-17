// PomodoroPanel — the Pomodoro plugin's panel (equisdots plugin standard).
//
// Loaded by the shell's panel host from ui/plugins/pomodoropanel/ (manifest
// provides.panels.pomodoro); the qs.* imports resolve against the shell tree.
// Work = 25 min, Break = 5 min. The running session is written to
// $XDG_RUNTIME_DIR/equisdots-pomodoro (epoch end time) through
// scripts/pomodoropanel.sh — the same file the Pomodoro bar module reads.
// Finishing a session raises a notify-send notification.
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

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/pomodoropanel/scripts/pomodoropanel.sh"
    readonly property int workSec: 25 * 60
    readonly property int breakSec: 5 * 60

    // ── state ──────────────────────────────────────────────────────────────
    property int remaining: workSec
    property int totalSec: workSec
    property bool running: false
    property bool breakMode: false

    function closeSelf() {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
    }

    // ── session control ────────────────────────────────────────────────────
    function writeState(verb, secs) {
        ctl.command = secs !== undefined
            ? ["bash", window.scriptPath, verb, String(secs)]
            : ["bash", window.scriptPath, verb];
        ctl.running = false;
        ctl.running = true;
    }

    function resume() {
        if (window.remaining <= 0) window.remaining = window.breakMode ? window.breakSec : window.workSec;
        window.running = true;
        window.writeState("start", window.remaining);
    }

    function pause() {
        window.running = false;
        window.writeState("pause");
    }

    function toggleRun() { if (window.running) window.pause(); else window.resume(); }

    function reset() {
        window.running = false;
        window.breakMode = false;
        window.totalSec = window.workSec;
        window.remaining = window.workSec;
        window.writeState("reset");
    }

    function tick() {
        if (!window.running) return;
        window.remaining -= 1;
        if (window.remaining <= 0) window.finish();
    }

    function finish() {
        window.running = false;
        if (window.breakMode) {
            Quickshell.execDetached(["notify-send", "Pomodoro", "Break finished - back to work"]);
            window.breakMode = false;
            window.totalSec = window.workSec;
            window.remaining = window.workSec;
            window.writeState("reset");
        } else {
            Quickshell.execDetached(["notify-send", "Pomodoro", "Work session complete - take a break"]);
            window.breakMode = true;
            window.totalSec = window.breakSec;
            window.remaining = window.breakSec;
            window.running = true;
            window.writeState("start", window.breakSec);
        }
    }

    function fmtTime(sec) {
        const v = Math.max(0, sec);
        const m = Math.floor(v / 60);
        const ss = v % 60;
        return (m < 10 ? "0" : "") + m + ":" + (ss < 10 ? "0" : "") + ss;
    }

    // ── shared state file ──────────────────────────────────────────────────
    Process {
        id: ctl
        running: false
        stdout: StdioCollector {}
    }

    Process {
        id: statusProc
        command: ["bash", window.scriptPath, "status"]
        running: true
        stdout: StdioCollector { onStreamFinished: window.applyStatus(this.text) }
    }

    function applyStatus(txt) {
        const v = (txt || "").trim();
        if (v === "" || v === "idle" || v === "done" || v === "0") {
            window.running = false;
            window.breakMode = false;
            window.totalSec = window.workSec;
            window.remaining = window.workSec;
            return;
        }
        const left = parseInt(v);
        if (isNaN(left) || left <= 0) {
            window.running = false;
            window.totalSec = window.workSec;
            window.remaining = window.workSec;
            return;
        }
        // Mode is not stored: a restored session is assumed to be a work run.
        window.breakMode = false;
        window.totalSec = window.workSec;
        window.remaining = Math.min(left, window.workSec);
        window.running = true;
    }

    Timer {
        interval: 1000
        repeat: true
        running: window.running
        onTriggered: window.tick()
    }

    Connections {
        target: window
        function onRemainingChanged() { ring.requestPaint(); }
        function onTotalSecChanged() { ring.requestPaint(); }
    }

    Keys.onEscapePressed: (event) => { window.closeSelf(); event.accepted = true; }

    // ── button ─────────────────────────────────────────────────────────────
    component PomoButton: Rectangle {
        id: btn
        property string label
        property bool filled: false
        signal action()
        Layout.preferredWidth: window.s(120)
        Layout.preferredHeight: window.s(40)
        radius: Theme.radiusMd
        color: btn.filled ? Theme.mauve : Theme.surfaceContainerHigh
        border.width: 1
        border.color: Theme.outlineVariant
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.stateLayer(Theme.text, Theme.stateHover)
            opacity: btnMa.containsMouse ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durShort } }
        }
        Text {
            anchors.centerIn: parent
            text: btn.label
            font.family: "Hack Nerd Font"
            font.pixelSize: window.s(14)
            font.weight: Font.Bold
            color: btn.filled ? Theme.base : Theme.text
        }
        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.action()
        }
    }

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
            spacing: s(12)

            // ── header ─────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.gapSm
                Text { text: "\udb81\udd1b"; font.family: "Hack Nerd Font"; font.pixelSize: s(18); color: Theme.mauve }
                Text { Layout.fillWidth: true; text: "Pomodoro"; font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: s(18); color: Theme.text }
                Rectangle {
                    Layout.preferredWidth: s(64)
                    Layout.preferredHeight: s(22)
                    radius: Theme.radiusFull
                    color: window.running ? Theme.stateLayer(Theme.green, 0.18) : Theme.stateLayer(Theme.text, 0.06)
                    border.width: 1
                    border.color: window.running ? Theme.stateLayer(Theme.green, 0.4) : Theme.outlineVariant
                    Text {
                        anchors.centerIn: parent
                        text: window.running ? "running" : "paused"
                        font.family: "Hack Nerd Font"; font.pixelSize: s(10); font.weight: Font.Bold
                        color: window.running ? Theme.green : Theme.subtext0
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // ── ring + time ────────────────────────────────────────────────
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: window.s(220)
                Layout.preferredHeight: window.s(220)

                Canvas {
                    id: ring
                    anchors.fill: parent
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        const cx = width / 2;
                        const cy = height / 2;
                        const r = width / 2 - window.s(9);
                        const lw = window.s(10);

                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, Math.PI * 2);
                        ctx.lineWidth = lw;
                        ctx.strokeStyle = Theme.hexOf(Theme.surfaceContainerHighest);
                        ctx.stroke();

                        let frac = window.totalSec > 0 ? (1 - window.remaining / window.totalSec) : 0;
                        frac = Math.max(0, Math.min(1, frac));
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * frac);
                        ctx.lineWidth = lw;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = Theme.hexOf(Theme.mauve);
                        ctx.stroke();
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: window.s(2)
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: window.fmtTime(window.remaining)
                        font.family: "Hack Nerd Font"
                        font.pixelSize: window.s(44)
                        font.weight: Font.Black
                        color: Theme.text
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: window.breakMode ? "Break" : "Work"
                        font.family: "Hack Nerd Font"
                        font.pixelSize: window.s(13)
                        color: Theme.mauve
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // ── actions ────────────────────────────────────────────────────
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.gapMd
                PomoButton { label: window.running ? "Pause" : "Start"; filled: !window.running; onAction: window.toggleRun() }
                PomoButton { label: "Reset"; onAction: window.reset() }
            }
        }
    }
}
