import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.core

// ═══════════════════════════════════════════════════════════════════════════
// SamuraiBar — a COMPLETE bar shipped by the `samurai-bar` plugin
// (plugin.json → provides.bar.provider). Mounted generically by the shell
// (ui/PluginHosts.qml) while the plugin is enabled; its menu is
// settings/SamuraiBarPage.qml.
//
// Design language — Samurai: monochrome canvas, structure as ornament, type
// does the hierarchy. Flat surfaces separated by 1px hairlines, no gradients,
// no shadows, no blur, no corner radius on the bar (technical). Labels are
// ALL-CAPS monospace with letter-spacing; colour appears ONLY to encode a
// status (a critical CPU/temp/battery), never as decoration. Dense: every
// pixel earns its place. Motion is a single subtle ease-out.
//
// The bar ships ITS OWN widgets (workspaces, clock, cpu/mem/temp/net/battery
// segments) — nothing is reused from the core bar. Data: the shared core
// SysData singleton (ref-counted) plus two tiny value producers under scripts/.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    visible: false
    width: 0
    height: 0

    // Injected by ui/PluginHosts.qml (post-load; may briefly be null).
    property var host: null

    // Fallback palette (warm off-white text on OLED black) before host is set.
    readonly property var _fb: ({
        base: "#0a0a0a", text: "#e6e6e6", subtext0: "#8a8a8a",
        surface0: "#161616", red: "#ff5f5f", green: "#7fd96b",
        yellow: "#e6c84f", mauve: "#b59cf0"
    })
    readonly property var c: (host && host.colors) ? host.colors : _fb
    readonly property var cfg: (host && host.settings) ? host.settings.all() : ({})

    readonly property string mono: "Hack Nerd Font"
    readonly property int barH: (cfg.height !== undefined ? cfg.height : 30)

    // Samurai popup tokens. Colour is reserved for status, never decoration.
    readonly property int skPad: 14
    readonly property color skBg: root.c.base
    readonly property color skText: root.c.text
    readonly property color skDim: Qt.rgba(root.c.text.r, root.c.text.g, root.c.text.b, 0.48)
    readonly property color skFaint: Qt.rgba(root.c.text.r, root.c.text.g, root.c.text.b, 0.28)
    readonly property color skHair: Qt.rgba(root.c.text.r, root.c.text.g, root.c.text.b, 0.18)
    readonly property color skAccent: root.c.red !== undefined ? root.c.red : "#D71921"
    readonly property color skWarn: root.c.yellow !== undefined ? root.c.yellow : "#D4A843"

    // ── popup state ─────────────────────────────────────────────────────────
    property bool calendarOpen: false
    property bool statsOpen: false
    property var popupScreen: null
    readonly property bool popupVisible: calendarOpen || statsOpen

    function closePopups() { root.calendarOpen = false; root.statsOpen = false; }

    function toggleCalendar(screen) {
        if (root.calendarOpen && root.popupScreen === screen) { root.closePopups(); return; }
        root.statsOpen = false;
        root.calendarOpen = true;
        root.popupScreen = screen;
    }

    function toggleStats(screen) {
        if (root.statsOpen && root.popupScreen === screen) { root.closePopups(); return; }
        root.calendarOpen = false;
        root.statsOpen = true;
        root.popupScreen = screen;
        root.refreshStats();
    }

    function toneFor(value, warn, critical) {
        let n = Number(value) || 0;
        if (n >= critical) return root.skAccent;
        if (n >= warn) return root.skWarn;
        return root.skText;
    }

    function fmtRate(bytes) {
        let n = Number(bytes) || 0;
        if (n >= 1048576) return (n / 1048576).toFixed(1) + " MB/s";
        if (n >= 1024) return (n / 1024).toFixed(1) + " KB/s";
        return Math.round(n) + " B/s";
    }

    function fmtUptime(seconds) {
        let s = Math.max(0, Math.round(Number(seconds) || 0));
        let d = Math.floor(s / 86400); s %= 86400;
        let h = Math.floor(s / 3600); s %= 3600;
        let m = Math.floor(s / 60);
        return (d > 0 ? d + "D " : "") + (h < 10 ? "0" : "") + h + "H " + (m < 10 ? "0" : "") + m + "M";
    }

    // 1px hairline + a mono label helper used by every segment.
    readonly property color hair: Qt.rgba(root.c.text.r, root.c.text.g, root.c.text.b, 0.13)
    readonly property color dim: Qt.rgba(root.c.text.r, root.c.text.g, root.c.text.b, 0.45)

    // status colour: colour is an event, never a default
    function status(ok, warn) {
        return ok ? root.c.text : (warn ? root.c.yellow : root.c.red);
    }

    // ── clock ──────────────────────────────────────────────────────────────
    property string clock: ""
    property string date: ""
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            root.clock = Qt.formatDateTime(d, root.cfg.clockSeconds === false ? "HH:mm" : "HH:mm:ss");
            root.date = Qt.formatDateTime(d, "ddd dd MMM").toUpperCase();
        }
    }

    // ── calendar ────────────────────────────────────────────────────────────
    property int calOffset: 0
    property var calDays: []
    property string calMonthLabel: ""
    readonly property var calWeekdays: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
    readonly property string calTodayLabel: Qt.formatDate(new Date(), "dd MMM yyyy").toUpperCase()

    function updateCalendar() {
        let now = new Date();
        let base = new Date(now.getFullYear(), now.getMonth() + root.calOffset, 1);
        let y = base.getFullYear();
        let m = base.getMonth();
        let first = (new Date(y, m, 1).getDay() + 6) % 7; // Monday first
        let days = new Date(y, m + 1, 0).getDate();
        let prev = new Date(y, m, 0).getDate();
        let out = [];
        for (let i = 0; i < 42; i++) {
            let day;
            let inMonth = true;
            if (i < first) {
                day = prev - first + i + 1;
                inMonth = false;
            } else if (i >= first + days) {
                day = i - (first + days) + 1;
                inMonth = false;
            } else {
                day = i - first + 1;
            }
            out.push({
                day: day,
                inMonth: inMonth,
                today: inMonth && root.calOffset === 0 && y === now.getFullYear()
                    && m === now.getMonth() && day === now.getDate()
            });
        }
        root.calDays = out;
        root.calMonthLabel = Qt.formatDate(base, "MMMM yyyy").toUpperCase();
    }
    Component.onCompleted: { updateCalendar(); SysData.subscribe(); }
    onCalOffsetChanged: updateCalendar()

    // ── extended system telemetry ───────────────────────────────────────────
    property var cpuHistory: []
    property var ramHistory: []
    property var tempHistory: []
    property var topProcs: []

    function pushHistory() {
        function tail(a, v) {
            let out = a.slice(Math.max(0, a.length - 59));
            out.push(v);
            return out;
        }
        root.cpuHistory = tail(root.cpuHistory, Number(SysData.cpu) || 0);
        root.ramHistory = tail(root.ramHistory, Number(SysData.ramPercent) || 0);
        root.tempHistory = tail(root.tempHistory, Number(SysData.temp) || 0);
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.pushHistory()
    }

    property int statDisk: 0
    property real statDiskFree: 0
    property real statLoad1: 0
    property real statLoad5: 0
    property real statLoad15: 0
    property int statUptime: 0
    property int statProcs: 0
    property int statSwap: 0

    function refreshStats() {
        if (!root.statsOpen) return;
        statsProc.running = false;
        statsProc.running = true;
        root.refreshTop();
    }

    Process {
        id: statsProc
        command: ["bash", Quickshell.env("HOME") + "/.config/hypr/plugins/samurai-bar/scripts/stats.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let o = JSON.parse((this.text || "{}").trim());
                    root.statDisk = Number(o.disk) || 0;
                    root.statDiskFree = Number(o.diskFree) || 0;
                    root.statLoad1 = Number(o.load1) || 0;
                    root.statLoad5 = Number(o.load5) || 0;
                    root.statLoad15 = Number(o.load15) || 0;
                    root.statUptime = Number(o.uptime) || 0;
                    root.statProcs = Number(o.procs) || 0;
                    root.statSwap = Number(o.swap) || 0;
                } catch (e) {}
            }
        }
    }
    Process {
        id: topProc
        command: ["bash", Quickshell.env("HOME") + "/.config/hypr/plugins/samurai-bar/scripts/top.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = [];
                let lines = (this.text || "").trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    let parts = lines[i].split("\t");
                    if (parts.length >= 3)
                        out.push({ name: parts[0], cpu: Number(parts[1]) || 0, mem: Number(parts[2]) || 0 });
                }
                root.topProcs = out;
            }
        }
    }
    Timer {
        interval: 3000
        running: root.statsOpen
        repeat: true
        onTriggered: root.refreshTop()
    }
    function refreshTop() {
        if (!root.statsOpen) return;
        topProc.running = false;
        topProc.running = true;
    }

    // ── system (shared poller) ──────────────────────────────────────────────
    Component.onDestruction: SysData.unsubscribe()

    // ── battery ─────────────────────────────────────────────────────────────
    property int batPct: -1
    property string batState: "AC"
    Process {
        id: batProc
        command: ["bash", Quickshell.env("HOME") + "/.config/hypr/plugins/samurai-bar/scripts/battery.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let t = (this.text || "").trim();
                if (t === "AC") { root.batPct = -1; root.batState = "AC"; return; }
                let p = t.split(" ");
                root.batPct = parseInt(p[0]) || -1;
                root.batState = p[1] || "";
            }
        }
    }
    Timer { interval: 20000; running: true; repeat: true; onTriggered: { batProc.running = false; batProc.running = true; } }

    // ── a flat segment: CAPS label + value, hairline-separated ──────────────
    component Seg: Item {
        id: seg
        property string label: ""
        property string value: ""
        property color valueColor: root.c.text
        property var screen: null
        implicitWidth: segRow.implicitWidth
        implicitHeight: root.barH

        Row {
            id: segRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Rectangle { width: 1; height: root.barH - 12; color: root.hair }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: seg.label
                font.family: root.mono; font.pixelSize: 9; font.letterSpacing: 1.4
                color: root.dim
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: seg.value
                font.family: root.mono; font.pixelSize: 11; font.weight: Font.Medium
                color: seg.valueColor
                Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.cfg.showStats !== false
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: root.toggleStats(seg.screen)
        }
    }

    component Sparkline: Canvas {
        id: spark
        property var values: []
        property color stroke: root.skText
        onValuesChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            let ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = root.skFaint.toString();
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.moveTo(0, height - 1);
            ctx.lineTo(width, height - 1);
            ctx.stroke();
            if (!values || values.length < 2) return;
            let max = 100;
            ctx.strokeStyle = stroke.toString();
            ctx.beginPath();
            for (let i = 0; i < values.length; i++) {
                let x = (i / (values.length - 1)) * width;
                let y = height - 1 - (Math.max(0, Math.min(max, values[i])) / max) * (height - 2);
                if (i === 0) ctx.moveTo(x, y);
                else ctx.lineTo(x, y);
            }
            ctx.stroke();
        }
    }

    component TopRow: Item {
        id: topRow
        property string label: ""
        property string value: ""
        width: parent ? parent.width : 0
        height: 26
        Text {
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.68
            text: topRow.label
            elide: Text.ElideRight
            font.family: root.mono; font.pixelSize: 9; color: root.skDim
        }
        Text {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            text: topRow.value
            font.family: root.mono; font.pixelSize: 9; color: root.skText
        }
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            height: 1; color: root.skHair
        }
    }

    // Samurai telemetry row: mono label + value, optional 2px flat meter.
    component StatRow: Item {
        id: statRow
        property string label: ""
        property string value: ""
        property real ratio: -1
        property var history: []
        property color tone: root.skText
        width: parent ? parent.width : 0
        height: 42

        Text {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 6
            text: statRow.label
            font.family: root.mono; font.pixelSize: 9; font.letterSpacing: 1.5
            color: root.skDim
        }
        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 3
            width: parent.width * 0.58
            text: statRow.value
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            font.family: root.mono; font.pixelSize: 11; font.weight: Font.Medium
            color: statRow.tone
        }
        Sparkline {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            height: 13
            values: statRow.history
            stroke: statRow.tone
            visible: statRow.history && statRow.history.length > 1
        }
        Rectangle {
            visible: statRow.ratio >= 0 && (!statRow.history || statRow.history.length < 2)
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 7
            height: 2
            color: root.skFaint
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, statRow.ratio))
                height: parent.height
                color: statRow.tone
            }
        }
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: root.skHair
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: barWindow
                required property var modelData
                screen: modelData

                // Workspace state is per output: every monitor bar highlights its
                // own active workspace while the visible id list stays global.
                property var wsList: []
                property int wsActive: -1
                Process {
                    id: wsProc
                    running: true
                    command: ["bash", Quickshell.env("HOME") + "/.config/hypr/plugins/samurai-bar/scripts/workspaces.sh",
                              String(modelData && modelData.name ? modelData.name : "")]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            try {
                                let o = JSON.parse(this.text);
                                barWindow.wsList = o.ws || [];
                                barWindow.wsActive = o.active;
                            } catch (e) {
                                barWindow.wsList = [];
                                barWindow.wsActive = -1;
                            }
                        }
                    }
                }
                Timer {
                    interval: 1500
                    running: true
                    repeat: true
                    onTriggered: { wsProc.running = false; wsProc.running = true; }
                }

                anchors.top: true
                anchors.left: true
                anchors.right: true
                implicitHeight: root.barH
                exclusiveZone: root.barH
                color: "transparent"

                // flat band + a single bottom hairline: structure is ornament
                Rectangle {
                    anchors.fill: parent
                    color: root.c.base
                }
                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 1
                    color: root.hair
                }

                // ── left: workspaces ───────────────────────────────────────
                Row {
                    visible: root.cfg.showWorkspaces !== false
                    anchors.left: parent.left; anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Repeater {
                        model: barWindow.wsList
                        delegate: Item {
                            required property var modelData
                            readonly property bool on: modelData === barWindow.wsActive
                            width: wsNum.implicitWidth + 14
                            height: root.barH

                            Text {
                                id: wsNum
                                anchors.centerIn: parent
                                text: root.pad2(modelData)
                                font.family: root.mono; font.pixelSize: 11
                                font.weight: on ? Font.Bold : Font.Normal
                                color: on ? root.c.text : root.dim
                            }
                            Rectangle {
                                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                                width: parent.width * 0.55; height: 2
                                visible: on
                                color: root.c.text
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["bash", "-c",
                                    "hyprctl dispatch 'hl.dsp.focus({ workspace = \"" + modelData + "\" })'"])
                            }
                        }
                    }
                }

                // ── center: clock + date ───────────────────────────────────
                Row {
                    id: clockRow
                    visible: root.cfg.showClock !== false
                    anchors.centerIn: parent
                    spacing: 10
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.clock
                        font.family: root.mono; font.pixelSize: 12; font.weight: Font.Bold; font.letterSpacing: 0.5
                        color: root.c.text
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.date
                        font.family: root.mono; font.pixelSize: 9; font.letterSpacing: 1.6
                        color: root.dim
                    }
                }

                MouseArea {
                    anchors.fill: clockRow
                    enabled: root.cfg.showCalendar !== false
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleCalendar(barWindow.screen)
                }

                // ── right: system segments ─────────────────────────────────
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    height: root.barH
                    spacing: 10

                    Seg {
                        screen: barWindow.screen
                        visible: root.cfg.showCpu !== false
                        label: "CPU"; value: SysData.cpu + "%"
                        valueColor: root.status(SysData.cpu < 85, SysData.cpu < 95)
                    }
                    Seg {
                        screen: barWindow.screen
                        visible: root.cfg.showMem !== false
                        label: "MEM"; value: SysData.ramPercent + "%"
                    }
                    Seg {
                        screen: barWindow.screen
                        visible: root.cfg.showTemp !== false
                        label: "TEMP"; value: (SysData.temp > 0 ? SysData.temp + "°" : "--")
                        valueColor: root.status(SysData.temp < 80 || SysData.temp === 0, SysData.temp < 90)
                    }
                    Seg {
                        screen: barWindow.screen
                        visible: root.cfg.showNet !== false
                        label: "NET"
                        value: "↓" + (SysData.netRx / 1024).toFixed(1) + " ↑" + (SysData.netTx / 1024).toFixed(1)
                    }
                    Seg {
                        screen: barWindow.screen
                        visible: root.cfg.showBattery !== false
                        label: "BAT"
                        value: (root.batPct < 0 ? "AC" : root.batPct + "%")
                        valueColor: root.status(root.batPct < 0 || root.batPct > 15)
                    }

                    Rectangle { width: 1; height: root.barH - 12; color: root.hair }
                    Item {
                        width: 18; height: root.barH
                        Text {
                            anchors.centerIn: parent; text: "󰒓"
                            font.family: root.mono; font.pixelSize: 12
                            color: root.dim
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(["bash", "-c",
                                "~/.config/hypr/scripts/qs_manager.sh toggle bar-editor"])
                        }
                    }
                }
            }
        }
    }


    // ── Samurai overlays: calendar + resource telemetry ────────────────────
    // A full-screen overlay per screen keeps the cards flat and layer-shell
    // native; the card itself is a single hairline-framed surface.
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: popupWindow
                required property var modelData
                screen: modelData

                visible: root.popupVisible && root.popupScreen === modelData
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                implicitWidth: modelData ? modelData.width : 1920
                implicitHeight: modelData ? modelData.height : 1080
                anchors.top: true
                anchors.left: true
                anchors.right: true
                anchors.bottom: true
                focusable: true
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "equisdots-samurai-popup"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    focus: true
                    onClicked: root.closePopups()
                    Keys.onEscapePressed: root.closePopups()
                }

                // ── calendar ───────────────────────────────────────────────
                Rectangle {
                    id: calendarCard
                    visible: root.calendarOpen
                    width: 336
                    height: calendarCol.implicitHeight + root.skPad * 2
                    x: Math.round((modelData.width - width) / 2)
                    y: root.barH + 8 + (root.calendarOpen ? 0 : -6)
                    color: root.skBg
                    border.width: 1
                    border.color: root.skHair
                    radius: 0
                    opacity: root.calendarOpen ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.AllButtons
                        onClicked: {}
                    }

                    Column {
                        id: calendarCol
                        anchors.fill: parent
                        anchors.margins: root.skPad
                        spacing: 5

                        RowLayout {
                            width: parent.width
                            height: 22
                            Text {
                                text: "CALENDAR"
                                font.family: root.mono; font.pixelSize: 9
                                font.letterSpacing: 2.0; color: root.skDim
                            }
                            Item { Layout.fillWidth: true }
                            Item {
                                width: 22; height: 22
                                Text {
                                    anchors.centerIn: parent; text: "‹"
                                    font.family: root.mono; font.pixelSize: 18
                                    color: navLeft.containsMouse ? root.skText : root.skDim
                                }
                                MouseArea {
                                    id: navLeft; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.calOffset--
                                }
                            }
                            Item {
                                width: 22; height: 22
                                Text {
                                    anchors.centerIn: parent; text: "›"
                                    font.family: root.mono; font.pixelSize: 18
                                    color: navRight.containsMouse ? root.skText : root.skDim
                                }
                                MouseArea {
                                    id: navRight; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.calOffset++
                                }
                            }
                        }

                        Text {
                            text: root.calMonthLabel
                            font.family: root.mono; font.pixelSize: 15; font.weight: Font.Bold
                            font.letterSpacing: 0.5; color: root.skText
                        }

                        Rectangle { width: parent.width; height: 1; color: root.skHair }

                        Row {
                            width: parent.width
                            height: 20
                            Repeater {
                                model: root.calWeekdays
                                Text {
                                    width: parent.width / 7
                                    height: parent.height
                                    text: modelData
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.family: root.mono; font.pixelSize: 8
                                    font.letterSpacing: 1.0; color: root.skDim
                                }
                            }
                        }

                        Grid {
                            id: calGrid
                            columns: 7
                            width: parent.width
                            height: Math.ceil(root.calDays.length / 7) * 34
                            Repeater {
                                model: root.calDays
                                Rectangle {
                                    width: calGrid.width / 7
                                    height: 34
                                    color: modelData.today ? root.skText : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.day
                                        font.family: root.mono; font.pixelSize: 11
                                        font.weight: modelData.today ? Font.Bold : Font.Normal
                                        color: modelData.today ? root.skBg
                                            : (modelData.inMonth ? root.skText : root.skFaint)
                                    }
                                }
                            }
                        }

                        Rectangle { width: parent.width; height: 1; color: root.skHair }

                        RowLayout {
                            width: parent.width
                            height: 18
                            Text {
                                text: "TODAY"
                                font.family: root.mono; font.pixelSize: 8
                                font.letterSpacing: 1.5; color: root.skDim
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: root.calTodayLabel
                                font.family: root.mono; font.pixelSize: 9
                                font.letterSpacing: 0.6; color: root.skText
                            }
                        }
                    }
                }

                // ── system resource telemetry ─────────────────────────────
                Rectangle {
                    id: statsCard
                    visible: root.statsOpen
                    width: 392
                    height: statsCol.implicitHeight + root.skPad * 2
                    x: Math.max(12, modelData.width - width - 12)
                    y: root.barH + 8 + (root.statsOpen ? 0 : -6)
                    color: root.skBg
                    border.width: 1
                    border.color: root.skHair
                    radius: 0
                    opacity: root.statsOpen ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.AllButtons
                        onClicked: {}
                    }

                    Column {
                        id: statsCol
                        anchors.fill: parent
                        anchors.margins: root.skPad
                        spacing: 0

                        RowLayout {
                            width: parent.width
                            height: 24
                            Text {
                                text: "SYSTEM / RESOURCES"
                                font.family: root.mono; font.pixelSize: 9
                                font.letterSpacing: 1.8; color: root.skDim
                            }
                            Item { Layout.fillWidth: true }
                            Rectangle { width: 4; height: 4; color: root.skAccent; radius: 0 }
                            Text {
                                text: "LIVE"
                                font.family: root.mono; font.pixelSize: 8
                                font.letterSpacing: 1.2; color: root.skAccent
                            }
                        }
                        Text {
                            text: "SAMURAI // RESOURCE TELEMETRY"
                            font.family: root.mono; font.pixelSize: 8
                            font.letterSpacing: 0.8; color: root.skFaint
                        }
                        Rectangle { width: parent.width; height: 1; color: root.skHair }

                        Text {
                            height: 22; width: parent.width
                            text: "COMPUTE"
                            verticalAlignment: Text.AlignBottom
                            font.family: root.mono; font.pixelSize: 8
                            font.letterSpacing: 1.8; color: root.skDim
                        }
                        StatRow {
                            label: "CPU UTILISATION"; value: SysData.cpu + "%"
                            ratio: SysData.cpu / 100
                            history: root.cpuHistory
                            tone: root.toneFor(SysData.cpu, 85, 95)
                        }
                        StatRow {
                            label: "MEMORY"; value: SysData.ramPercent + "% / " + SysData.ramGb.toFixed(1) + "G"
                            ratio: SysData.ramPercent / 100
                            history: root.ramHistory
                            tone: root.toneFor(SysData.ramPercent, 80, 92)
                        }
                        StatRow {
                            label: "THERMAL"; value: (SysData.temp > 0 ? SysData.temp + "°C" : "--")
                            ratio: SysData.temp > 0 ? Math.min(1, SysData.temp / 100) : -1
                            history: root.tempHistory
                            tone: root.toneFor(SysData.temp, 80, 90)
                        }

                        Text {
                            height: 22; width: parent.width
                            text: "I/O + NETWORK"
                            verticalAlignment: Text.AlignBottom
                            font.family: root.mono; font.pixelSize: 8
                            font.letterSpacing: 1.8; color: root.skDim
                        }
                        StatRow { label: "DOWNLINK"; value: root.fmtRate(SysData.netRx) }
                        StatRow { label: "UPLINK"; value: root.fmtRate(SysData.netTx) }
                        StatRow {
                            label: "STORAGE"; value: root.statDisk + "% / " + root.statDiskFree.toFixed(1) + "G FREE"
                            ratio: root.statDisk / 100
                            tone: root.toneFor(root.statDisk, 85, 95)
                        }

                        Text {
                            height: 22; width: parent.width
                            text: "SYSTEM"
                            verticalAlignment: Text.AlignBottom
                            font.family: root.mono; font.pixelSize: 8
                            font.letterSpacing: 1.8; color: root.skDim
                        }
                        StatRow {
                            label: "LOAD 1 / 5 / 15"; value: root.statLoad1.toFixed(2) + " " + root.statLoad5.toFixed(2) + " " + root.statLoad15.toFixed(2)
                        }
                        StatRow { label: "UPTIME"; value: root.fmtUptime(root.statUptime) }
                        StatRow { label: "PROCESSES"; value: String(root.statProcs) }
                        StatRow {
                            label: "SWAP"; value: root.statSwap + "%"
                            ratio: root.statSwap / 100
                            tone: root.toneFor(root.statSwap, 75, 90)
                        }

                        Text {
                            height: 22; width: parent.width
                            text: "TOP PROCESSES"
                            verticalAlignment: Text.AlignBottom
                            font.family: root.mono; font.pixelSize: 8
                            font.letterSpacing: 1.8; color: root.skDim
                        }
                        Repeater {
                            model: root.topProcs
                            TopRow {
                                label: modelData.name
                                value: modelData.cpu.toFixed(1) + "%"
                            }
                        }

                        Text {
                            height: 22; width: parent.width
                            text: "POWER"
                            verticalAlignment: Text.AlignBottom
                            font.family: root.mono; font.pixelSize: 8
                            font.letterSpacing: 1.8; color: root.skDim
                        }
                        StatRow {
                            label: "BATTERY"; value: root.batPct < 0 ? "AC" : root.batPct + "%"
                            ratio: root.batPct < 0 ? -1 : root.batPct / 100
                            tone: root.batPct >= 0 && root.batPct <= 15 ? root.skAccent : root.skText
                        }
                    }
                }
            }
        }
    }

    function pad2(n) { return (n < 10 ? "0" : "") + n; }
}
