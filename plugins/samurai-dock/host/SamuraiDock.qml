import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.core

// ═══════════════════════════════════════════════════════════════════════════
// Samurai Dock — an independent bottom dock in the Samurai design language.
//
// It is a plugin host adapter, not a complete bar: it floats above the bottom
// edge and only grabs input inside its dock panel. App shortcuts launch
// directly; the workspace, clock, SYS and power zones open flat Samurai panels.
// Nothing here touches the core shell or the samurai-bar plugin.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    visible: false
    width: 0
    height: 0

    property var host: null

    readonly property var _fb: ({
        base: "#0a0a0a", text: "#e6e6e6", subtext0: "#8a8a8a",
        surface0: "#161616", red: "#ff5f5f", green: "#7fd96b",
        yellow: "#e6c84f", mauve: "#b59cf0"
    })
    readonly property var c: (host && host.colors) ? host.colors : _fb
    readonly property var cfg: (host && host.settings) ? host.settings.all() : ({})

    function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }

    readonly property string mono: "Hack Nerd Font"
    readonly property int dockH: clamp(Number(cfg.height) || 54, 44, 84)
    readonly property int skPad: 14

    readonly property color skBg: root.c.base
    readonly property color skText: root.c.text
    readonly property color skDim: Qt.rgba(root.c.text.r, root.c.text.g, root.c.text.b, 0.48)
    readonly property color skFaint: Qt.rgba(root.c.text.r, root.c.text.g, root.c.text.b, 0.28)
    readonly property color skHair: Qt.rgba(root.c.text.r, root.c.text.g, root.c.text.b, 0.18)
    readonly property color skAccent: root.c.red !== undefined ? root.c.red : "#D71921"
    readonly property color skWarn: root.c.yellow !== undefined ? root.c.yellow : "#D4A843"

    readonly property var defaultApps: ([
        { label: "TERM", glyph: "󰆍", exec: "kitty" },
        { label: "FILES", glyph: "󰉋", exec: "nautilus" },
        { label: "WEB", glyph: "󰖟", exec: "brave" },
        { label: "CODE", glyph: "󰅩", exec: "code" },
        { label: "MUSIC", glyph: "󰝚", exec: "spotify" }
    ])
    readonly property var apps: {
        let a = root.cfg.apps;
        return (Array.isArray(a) && a.length > 0) ? a : root.defaultApps;
    }
    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/plugins/samurai-dock/scripts"

    property string clock: ""
    property string date: ""
    property int batPct: -1

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            root.clock = Qt.formatDateTime(d, "HH:mm");
            root.date = Qt.formatDateTime(d, "ddd dd MMM").toUpperCase();
        }
    }

    Process {
        id: batProc
        running: true
        command: ["bash", root.scriptsDir + "/battery.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let t = (this.text || "").trim();
                if (t === "AC") { root.batPct = -1; return; }
                root.batPct = parseInt(t.split(" ")[0]) || -1;
            }
        }
    }
    Timer { interval: 20000; running: true; repeat: true; onTriggered: { batProc.running = false; batProc.running = true; } }

    // ── popup state ─────────────────────────────────────────────────────────
    property bool calendarOpen: false
    property bool statsOpen: false
    property bool powerOpen: false
    property var popupScreen: null
    readonly property bool popupVisible: calendarOpen || statsOpen || powerOpen
    property string pendingPower: ""

    function closePopups() {
        root.calendarOpen = false;
        root.statsOpen = false;
        root.powerOpen = false;
        root.pendingPower = "";
    }

    function openExclusive(screen, which) {
        let same = (which === "calendar" && root.calendarOpen)
            || (which === "stats" && root.statsOpen)
            || (which === "power" && root.powerOpen);
        if (same && root.popupScreen === screen) { root.closePopups(); return; }
        root.calendarOpen = which === "calendar";
        root.statsOpen = which === "stats";
        root.powerOpen = which === "power";
        root.popupScreen = screen;
        root.pendingPower = "";
        if (which === "stats") root.refreshStats();
    }

    // ── utility formatting ──────────────────────────────────────────────────
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

    // ── history + extended telemetry ────────────────────────────────────────
    property var cpuHistory: []
    property var ramHistory: []
    property var tempHistory: []
    property var topProcs: []
    property int statDisk: 0
    property real statDiskFree: 0
    property real statLoad1: 0
    property real statLoad5: 0
    property real statLoad15: 0
    property int statUptime: 0
    property int statProcs: 0
    property int statSwap: 0

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
    Timer { interval: 2000; running: true; repeat: true; onTriggered: root.pushHistory() }

    Process {
        id: statsProc
        command: ["bash", root.scriptsDir + "/stats.sh"]
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
        command: ["bash", root.scriptsDir + "/top.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = [];
                let lines = (this.text || "").trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    let p = lines[i].split("\t");
                    if (p.length >= 3) out.push({ name: p[0], cpu: Number(p[1]) || 0, mem: Number(p[2]) || 0 });
                }
                root.topProcs = out;
            }
        }
    }
    Timer { interval: 3000; running: root.statsOpen; repeat: true; onTriggered: root.refreshStats() }
    function refreshStats() {
        if (!root.statsOpen) return;
        statsProc.running = false; statsProc.running = true;
        topProc.running = false; topProc.running = true;
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
        let y = base.getFullYear(); let m = base.getMonth();
        let first = (new Date(y, m, 1).getDay() + 6) % 7;
        let days = new Date(y, m + 1, 0).getDate();
        let prev = new Date(y, m, 0).getDate();
        let out = [];
        for (let i = 0; i < 42; i++) {
            let day, inMonth = true;
            if (i < first) { day = prev - first + i + 1; inMonth = false; }
            else if (i >= first + days) { day = i - (first + days) + 1; inMonth = false; }
            else day = i - first + 1;
            out.push({ day: day, inMonth: inMonth,
                today: inMonth && root.calOffset === 0 && y === now.getFullYear()
                    && m === now.getMonth() && day === now.getDate() });
        }
        root.calDays = out;
        root.calMonthLabel = Qt.formatDate(base, "MMMM yyyy").toUpperCase();
    }
    Component.onCompleted: { updateCalendar(); SysData.subscribe(); }
    Component.onDestruction: SysData.unsubscribe()
    onCalOffsetChanged: updateCalendar()

    // ── components ──────────────────────────────────────────────────────────
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
            ctx.beginPath(); ctx.moveTo(0, height - 1); ctx.lineTo(width, height - 1); ctx.stroke();
            if (!values || values.length < 2) return;
            ctx.strokeStyle = stroke.toString();
            ctx.beginPath();
            for (let i = 0; i < values.length; i++) {
                let x = (i / (values.length - 1)) * width;
                let y = height - 1 - (Math.max(0, Math.min(100, values[i])) / 100) * (height - 2);
                if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
            }
            ctx.stroke();
        }
    }

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
            anchors.left: parent.left; anchors.top: parent.top; anchors.topMargin: 6
            text: statRow.label
            font.family: root.mono; font.pixelSize: 9; font.letterSpacing: 1.5; color: root.skDim
        }
        Text {
            anchors.right: parent.right; anchors.top: parent.top; anchors.topMargin: 3
            width: parent.width * 0.58; text: statRow.value
            horizontalAlignment: Text.AlignRight; elide: Text.ElideRight
            font.family: root.mono; font.pixelSize: 11; font.weight: Font.Medium; color: statRow.tone
        }
        Sparkline {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.bottomMargin: 4; height: 13
            values: statRow.history; stroke: statRow.tone
            visible: statRow.history && statRow.history.length > 1
        }
        Rectangle {
            visible: statRow.ratio >= 0 && (!statRow.history || statRow.history.length < 2)
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.bottomMargin: 7; height: 2; color: root.skFaint
            Rectangle { width: parent.width * Math.max(0, Math.min(1, statRow.ratio)); height: parent.height; color: statRow.tone }
        }
        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: root.skHair }
    }

    component TopRow: Item {
        id: topRow
        property string label: ""
        property string value: ""
        width: parent ? parent.width : 0
        height: 26
        Text {
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.68; text: topRow.label; elide: Text.ElideRight
            font.family: root.mono; font.pixelSize: 9; color: root.skDim
        }
        Text {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            text: topRow.value; font.family: root.mono; font.pixelSize: 9; color: root.skText
        }
        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: root.skHair }
    }

    component PowerRow: Item {
        id: powerRow
        property string label: ""
        property string action: ""
        property bool armed: false
        width: parent ? parent.width : 0
        height: 38
        Text {
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.62; text: powerRow.label
            font.family: root.mono; font.pixelSize: 9; font.letterSpacing: 1.4
            color: powerRow.armed ? root.skAccent : root.skText
        }
        Text {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            text: powerRow.armed ? "CONFIRM" : "›"
            font.family: root.mono; font.pixelSize: 10
            color: powerRow.armed ? root.skAccent : root.skDim
        }
        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: root.skHair }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: root.runPower(powerRow.action)
        }
    }

    function launch(app) {
        let cmd = String((app && (app.exec || app.command)) || "").trim();
        if (cmd !== "") Quickshell.execDetached(["bash", "-lc", cmd]);
    }

    function runPower(action) {
        if (action === "lock") {
            Quickshell.execDetached(["bash", "-lc", "loginctl lock-session"]);
            root.closePopups(); return;
        }
        if (root.pendingPower !== action) { root.pendingPower = action; return; }
        root.pendingPower = "";
        let cmd = action === "suspend" ? "systemctl suspend"
            : action === "logout" ? "hyprctl dispatch 'hl.dsp.exit()'"
            : action === "reboot" ? "systemctl reboot"
            : action === "poweroff" ? "systemctl poweroff" : "";
        if (cmd !== "") Quickshell.execDetached(["bash", "-lc", cmd]);
        root.closePopups();
    }

    // ── bottom dock surface ─────────────────────────────────────────────────
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: dockWindow
                required property var modelData
                screen: modelData
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                implicitWidth: modelData ? modelData.width : 1920
                implicitHeight: modelData ? modelData.height : 1080
                anchors.top: true; anchors.bottom: true; anchors.left: true; anchors.right: true
                focusable: false
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "equisdots-samurai-dock"
                mask: Region { item: dockPanel }

                property var wsList: []
                property int wsActive: -1
                Process {
                    id: wsProc
                    running: true
                    command: ["bash", root.scriptsDir + "/workspaces.sh",
                              String(modelData && modelData.name ? modelData.name : "")]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            try {
                                let o = JSON.parse(this.text);
                                dockWindow.wsList = o.ws || [];
                                dockWindow.wsActive = o.active;
                            } catch (e) {
                                dockWindow.wsList = []; dockWindow.wsActive = -1;
                            }
                        }
                    }
                }
                Timer { interval: 1500; running: true; repeat: true; onTriggered: { wsProc.running = false; wsProc.running = true; } }

                Rectangle {
                    id: dockPanel
                    width: dockRow.implicitWidth + 16
                    height: root.dockH
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 10
                    color: root.skBg
                    border.width: 1
                    border.color: root.skHair
                    radius: 0

                    Row {
                        id: dockRow
                        anchors.centerIn: parent
                        spacing: 0

                        Repeater {
                            model: root.cfg.showWorkspaces === false ? [] : dockWindow.wsList
                            delegate: Item {
                                required property var modelData
                                readonly property bool on: modelData === dockWindow.wsActive
                                width: 25; height: root.dockH
                                Text {
                                    anchors.centerIn: parent; text: (modelData < 10 ? "0" : "") + modelData
                                    font.family: root.mono; font.pixelSize: 9
                                    font.weight: on ? Font.Bold : Font.Normal
                                    color: on ? root.skText : root.skDim
                                }
                                Rectangle { anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                                    width: parent.width * 0.5; height: 2; visible: on; color: root.skText }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["bash", "-lc",
                                        "hyprctl dispatch 'hl.dsp.focus({ workspace = \"" + modelData + "\" })'"])
                                }
                            }
                        }

                        Rectangle { width: 1; height: root.dockH - 18; color: root.skHair }

                        Repeater {
                            model: root.apps
                            delegate: Item {
                                required property var modelData
                                width: 42; height: root.dockH
                                property bool hovered: appMouse.containsMouse
                                Text { anchors.centerIn: parent; anchors.verticalCenterOffset: -4
                                    text: modelData.glyph || "󰀻"
                                    font.family: root.mono; font.pixelSize: 17
                                    color: hovered ? root.skText : root.skDim }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 7; text: modelData.label || ""
                                    font.family: root.mono; font.pixelSize: 7; font.letterSpacing: 0.8
                                    color: hovered ? root.skText : root.skFaint }
                                MouseArea {
                                    id: appMouse; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.launch(modelData)
                                }
                            }
                        }

                        Rectangle { width: 1; height: root.dockH - 18; color: root.skHair }

                        Item {
                            visible: root.cfg.showClock !== false
                            width: 70; height: root.dockH
                            Text { anchors.centerIn: parent; anchors.verticalCenterOffset: -4
                                text: root.clock; font.family: root.mono; font.pixelSize: 11
                                font.weight: Font.Bold; color: root.skText }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom
                                anchors.bottomMargin: 7; text: root.date; font.family: root.mono
                                font.pixelSize: 7; font.letterSpacing: 0.8; color: root.skDim }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: root.openExclusive(dockWindow.screen, "calendar") }
                        }

                        Item {
                            visible: root.cfg.showStats !== false
                            width: 74; height: root.dockH
                            Text { anchors.centerIn: parent; anchors.verticalCenterOffset: -5
                                text: "SYS"; font.family: root.mono; font.pixelSize: 9
                                font.letterSpacing: 1.4; color: root.skDim }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom
                                anchors.bottomMargin: 7; text: SysData.cpu + "% / " + SysData.ramPercent + "%"
                                font.family: root.mono; font.pixelSize: 8; color: root.skText }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: root.openExclusive(dockWindow.screen, "stats") }
                        }

                        Item {
                            visible: root.cfg.showPower !== false
                            width: 34; height: root.dockH
                            Text { anchors.centerIn: parent; text: "󰐥"
                                font.family: root.mono; font.pixelSize: 15; color: root.skDim }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: root.openExclusive(dockWindow.screen, "power") }
                        }
                    }
                }
            }
        }
    }

    // ── panels ──────────────────────────────────────────────────────────────
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
                anchors.top: true; anchors.bottom: true; anchors.left: true; anchors.right: true
                focusable: true
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "equisdots-samurai-dock-popup"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

                MouseArea {
                    anchors.fill: parent; acceptedButtons: Qt.AllButtons; focus: true
                    onClicked: root.closePopups()
                    Keys.onEscapePressed: root.closePopups()
                }

                // calendar
                Rectangle {
                    id: calendarCard
                    visible: root.calendarOpen
                    width: 336
                    height: calendarCol.implicitHeight + root.skPad * 2
                    x: Math.round((modelData.width - width) / 2)
                    y: modelData.height - root.dockH - 20 - height
                    color: root.skBg; border.width: 1; border.color: root.skHair; radius: 0
                    opacity: root.calendarOpen ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: {} }

                    Column {
                        id: calendarCol
                        anchors.fill: parent; anchors.margins: root.skPad; spacing: 5
                        RowLayout {
                            width: parent.width; height: 22
                            Text { text: "CALENDAR"; font.family: root.mono; font.pixelSize: 9; font.letterSpacing: 2.0; color: root.skDim }
                            Item { Layout.fillWidth: true }
                            Item { width: 22; height: 22
                                Text { anchors.centerIn: parent; text: "‹"; font.family: root.mono; font.pixelSize: 18; color: navL.containsMouse ? root.skText : root.skDim }
                                MouseArea { id: navL; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.calOffset-- }
                            }
                            Item { width: 22; height: 22
                                Text { anchors.centerIn: parent; text: "›"; font.family: root.mono; font.pixelSize: 18; color: navR.containsMouse ? root.skText : root.skDim }
                                MouseArea { id: navR; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.calOffset++ }
                            }
                        }
                        Text { text: root.calMonthLabel; font.family: root.mono; font.pixelSize: 15; font.weight: Font.Bold; color: root.skText }
                        Rectangle { width: parent.width; height: 1; color: root.skHair }
                        Row {
                            width: parent.width; height: 20
                            Repeater { model: root.calWeekdays
                                Text { width: parent.width / 7; height: parent.height; text: modelData
                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                    font.family: root.mono; font.pixelSize: 8; font.letterSpacing: 1.0; color: root.skDim }
                            }
                        }
                        Grid {
                            id: calGrid; columns: 7; width: parent.width
                            height: Math.ceil(root.calDays.length / 7) * 34
                            Repeater { model: root.calDays
                                Rectangle {
                                    width: calGrid.width / 7; height: 34
                                    color: modelData.today ? root.skText : "transparent"
                                    Text { anchors.centerIn: parent; text: modelData.day
                                        font.family: root.mono; font.pixelSize: 11
                                        font.weight: modelData.today ? Font.Bold : Font.Normal
                                        color: modelData.today ? root.skBg : (modelData.inMonth ? root.skText : root.skFaint) }
                                }
                            }
                        }
                        Rectangle { width: parent.width; height: 1; color: root.skHair }
                        RowLayout {
                            width: parent.width; height: 18
                            Text { text: "TODAY"; font.family: root.mono; font.pixelSize: 8; font.letterSpacing: 1.5; color: root.skDim }
                            Item { Layout.fillWidth: true }
                            Text { text: root.calTodayLabel; font.family: root.mono; font.pixelSize: 9; color: root.skText }
                        }
                    }
                }

                // resources
                Rectangle {
                    id: statsCard
                    visible: root.statsOpen
                    width: 392
                    height: statsCol.implicitHeight + root.skPad * 2
                    x: Math.max(12, modelData.width - width - 20)
                    y: modelData.height - root.dockH - 20 - height
                    color: root.skBg; border.width: 1; border.color: root.skHair; radius: 0
                    opacity: root.statsOpen ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: {} }

                    Column {
                        id: statsCol
                        anchors.fill: parent; anchors.margins: root.skPad; spacing: 0
                        RowLayout {
                            width: parent.width; height: 24
                            Text { text: "SYSTEM / RESOURCES"; font.family: root.mono; font.pixelSize: 9; font.letterSpacing: 1.8; color: root.skDim }
                            Item { Layout.fillWidth: true }
                            Rectangle { width: 4; height: 4; color: root.skAccent; radius: 0 }
                            Text { text: "LIVE"; font.family: root.mono; font.pixelSize: 8; font.letterSpacing: 1.2; color: root.skAccent }
                        }
                        Text { text: "SAMURAI DOCK // TELEMETRY"; font.family: root.mono; font.pixelSize: 8; font.letterSpacing: 0.8; color: root.skFaint }
                        Rectangle { width: parent.width; height: 1; color: root.skHair }
                        Text { height: 22; width: parent.width; text: "COMPUTE"; verticalAlignment: Text.AlignBottom; font.family: root.mono; font.pixelSize: 8; font.letterSpacing: 1.8; color: root.skDim }
                        StatRow { label: "CPU UTILISATION"; value: SysData.cpu + "%"; ratio: SysData.cpu / 100; history: root.cpuHistory; tone: root.toneFor(SysData.cpu, 85, 95) }
                        StatRow { label: "MEMORY"; value: SysData.ramPercent + "% / " + SysData.ramGb.toFixed(1) + "G"; ratio: SysData.ramPercent / 100; history: root.ramHistory; tone: root.toneFor(SysData.ramPercent, 80, 92) }
                        StatRow { label: "THERMAL"; value: SysData.temp > 0 ? SysData.temp + "°C" : "--"; ratio: SysData.temp > 0 ? Math.min(1, SysData.temp / 100) : -1; history: root.tempHistory; tone: root.toneFor(SysData.temp, 80, 90) }
                        Text { height: 22; width: parent.width; text: "I/O + NETWORK"; verticalAlignment: Text.AlignBottom; font.family: root.mono; font.pixelSize: 8; font.letterSpacing: 1.8; color: root.skDim }
                        StatRow { label: "DOWNLINK"; value: root.fmtRate(SysData.netRx) }
                        StatRow { label: "UPLINK"; value: root.fmtRate(SysData.netTx) }
                        StatRow { label: "STORAGE"; value: root.statDisk + "% / " + root.statDiskFree.toFixed(1) + "G FREE"; ratio: root.statDisk / 100; tone: root.toneFor(root.statDisk, 85, 95) }
                        Text { height: 22; width: parent.width; text: "SYSTEM"; verticalAlignment: Text.AlignBottom; font.family: root.mono; font.pixelSize: 8; font.letterSpacing: 1.8; color: root.skDim }
                        StatRow { label: "LOAD 1 / 5 / 15"; value: root.statLoad1.toFixed(2) + " " + root.statLoad5.toFixed(2) + " " + root.statLoad15.toFixed(2) }
                        StatRow { label: "UPTIME"; value: root.fmtUptime(root.statUptime) }
                        StatRow { label: "PROCESSES"; value: String(root.statProcs) }
                        StatRow { label: "SWAP"; value: root.statSwap + "%"; ratio: root.statSwap / 100; tone: root.toneFor(root.statSwap, 75, 90) }
                        Text { height: 22; width: parent.width; text: "TOP PROCESSES"; verticalAlignment: Text.AlignBottom; font.family: root.mono; font.pixelSize: 8; font.letterSpacing: 1.8; color: root.skDim }
                        Repeater { model: root.topProcs
                            TopRow { label: modelData.name; value: modelData.cpu.toFixed(1) + "%" }
                        }
                        Text { height: 22; width: parent.width; text: "POWER"; verticalAlignment: Text.AlignBottom; font.family: root.mono; font.pixelSize: 8; font.letterSpacing: 1.8; color: root.skDim }
                        StatRow { label: "BATTERY"; value: root.batPct < 0 ? "AC" : root.batPct + "%"; ratio: root.batPct < 0 ? -1 : root.batPct / 100; tone: root.batPct >= 0 && root.batPct <= 15 ? root.skAccent : root.skText }
                    }
                }

                // power
                Rectangle {
                    id: powerCard
                    visible: root.powerOpen
                    width: 300
                    height: powerCol.implicitHeight + root.skPad * 2
                    x: Math.max(12, modelData.width - width - 20)
                    y: modelData.height - root.dockH - 20 - height
                    color: root.skBg; border.width: 1; border.color: root.skHair; radius: 0
                    opacity: root.powerOpen ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: {} }
                    Column {
                        id: powerCol
                        anchors.fill: parent; anchors.margins: root.skPad; spacing: 0
                        Text { height: 24; width: parent.width; text: "SESSION / POWER"; verticalAlignment: Text.AlignBottom; font.family: root.mono; font.pixelSize: 9; font.letterSpacing: 1.8; color: root.skDim }
                        Text { text: "SECOND CLICK CONFIRMS"; font.family: root.mono; font.pixelSize: 8; color: root.skFaint; height: 18 }
                        PowerRow { label: "LOCK"; action: "lock"; armed: root.pendingPower === action }
                        PowerRow { label: "SUSPEND"; action: "suspend"; armed: root.pendingPower === action }
                        PowerRow { label: "LOG OUT"; action: "logout"; armed: root.pendingPower === action }
                        PowerRow { label: "REBOOT"; action: "reboot"; armed: root.pendingPower === action }
                        PowerRow { label: "SHUT DOWN"; action: "poweroff"; armed: root.pendingPower === action }
                    }
                }
            }
        }
    }
}
