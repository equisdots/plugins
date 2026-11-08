import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.core

// W11 taskbar host: one transparent full-screen layer surface per screen. The
// taskbar, start menu and popup input region are independent of the core shell.
Item {
    id: root
    visible: false
    width: 0
    height: 0

    property var host: null

    readonly property var _fb: ({
        base: "#1e1e2e", mantle: "#181825", surface0: "#313244",
        surface1: "#45475a", text: "#cdd6f4", subtext0: "#a6adc8",
        overlay0: "#6c7086", blue: "#89b4fa", mauve: "#cba6f7",
        red: "#f38ba8", green: "#a6e3a1", yellow: "#f9e2af"
    })
    readonly property var c: (host && host.colors) ? host.colors : _fb
    readonly property var cfg: {
        if (host && host.settings) {
            host.settings.revision;
            return host.settings.all();
        }
        return ({});
    }

    function num(v, d) { return (typeof v === "number" && isFinite(v)) ? v : d; }
    function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }
    function col(name, fallback) { return c[name] !== undefined ? c[name] : fallback; }
    function alpha(color, a) {
        let q = Qt.color(color);
        return Qt.rgba(q.r, q.g, q.b, a);
    }

    property string layoutMode: "full"
    property string themeMode: "windows11"
    property bool iconPalette: false
    property int barHeight: 48
    property real opacitySetting: 0.92
    property bool showSearch: true
    property bool showClock: true
    property bool showWeather: true
    property bool showBattery: true
    property bool showUser: true
    property var appsConfig: []
    property var menuAppsConfig: []

    readonly property bool compact: layoutMode === "compact"
    readonly property bool paletteMode: themeMode === "palette"
    readonly property bool tintIcons: iconPalette
    readonly property int barH: Math.round(clamp(Number(barHeight) || 48, 38, 68))
    readonly property int compactMargin: compact ? 10 : 0
    readonly property real panelOpacity: clamp(Number(opacitySetting) || 0.92, 0.35, 1.0)

    function applyCfg() {
        let d = (host && host.settings) ? host.settings.all() : {};
        layoutMode = String(d.layoutMode || "full");
        themeMode = String(d.themeMode || "windows11");
        iconPalette = d.iconPalette === true;
        barHeight = clamp(num(d.barHeight, 48), 38, 68);
        opacitySetting = clamp(num(d.opacity, 0.92), 0.35, 1.0);
        showSearch = d.showSearch !== false;
        showClock = d.showClock !== false;
        showWeather = d.showWeather !== false;
        showBattery = d.showBattery !== false;
        showUser = d.showUser !== false;
        appsConfig = Array.isArray(d.apps) ? d.apps : [];
        menuAppsConfig = Array.isArray(d.menuApps) ? d.menuApps : [];
    }

    readonly property color panelColor: paletteMode
        ? alpha(col("base", "#1e1e2e"), panelOpacity)
        : alpha("#202020", panelOpacity)
    readonly property color popupColor: paletteMode
        ? alpha(col("mantle", "#181825"), 0.98)
        : alpha("#202020", 0.98)
    readonly property color accent: paletteMode
        ? col("mauve", "#cba6f7")
        : "#0078d4"
    readonly property color fg: paletteMode ? col("text", "#cdd6f4") : "#ffffff"
    readonly property color dim: paletteMode
        ? alpha(col("subtext0", "#a6adc8"), 0.78)
        : alpha("#ffffff", 0.62)
    readonly property color faint: paletteMode
        ? alpha(col("overlay0", "#6c7086"), 0.62)
        : alpha("#ffffff", 0.28)
    readonly property color line: paletteMode
        ? alpha(col("surface1", "#45475a"), 0.72)
        : alpha("#ffffff", 0.12)
    readonly property color hover: paletteMode
        ? alpha(col("text", "#cdd6f4"), 0.09)
        : alpha("#ffffff", 0.09)
    readonly property color glyphColor: tintIcons ? accent : fg

    readonly property string uiFont: "Noto Sans"
    readonly property string iconFont: "Hack Nerd Font"

    readonly property var defaultApps: ([
        { label: "Terminal", glyph: "󰆍", exec: "kitty" },
        { label: "Files", glyph: "󰉋", exec: "nautilus" },
        { label: "Browser", glyph: "󰖟", exec: "brave" },
        { label: "Code", glyph: "󰅩", exec: "code" }
    ])
    readonly property var apps: {
        let a = root.appsConfig;
        if (!Array.isArray(a) || a.length === 0) return root.defaultApps;
        return a.map(function (x) {
            return {
                label: String((x && x.label) || ""),
                glyph: String((x && x.glyph) || "󰀻"),
                exec: String((x && x.exec) || "")
            };
        }).filter(function (x) {
            // The right-side gear is the W11 settings button; do not render a
            // second gear pin in the launcher row.
            return String(x.label).toLowerCase() !== "settings" && x.glyph !== "󰒓";
        });
    }

    // ── shared state ─────────────────────────────────────────────────────────
    property bool menuOpen: false
    property string menuScreenName: ""
    property string query: ""
    property var appCatalog: []
    property bool popupOpen: false
    property string popupKind: ""
    property string popupScreenName: ""
    property string batteryState: "AC"
    property int batteryHealth: -1
    property int batteryCycles: -1
    property int batteryWatts: 0
    property string clockSeconds: ""
    property var calendarCells: []
    property string calendarTitle: ""

    readonly property var searchResults: {
        let q = root.query.trim().toLowerCase();
        let all = root.appCatalog || [];
        let out = [];
        for (let i = 0; i < all.length; i++) {
            let a = all[i] || {};
            let name = String(a.name || "").toLowerCase();
            let id = String(a.id || "").toLowerCase();
            if (q === "" || name.indexOf(q) >= 0 || id.indexOf(q) >= 0)
                out.push(a);
            if (out.length >= (q === "" ? 7 : 14)) break;
        }
        return out;
    }
    readonly property var menuApps: {
        let a = root.menuAppsConfig;
        if (!Array.isArray(a) || a.length === 0) return [];
        return a.map(function (x) {
            return {
                id: String((x && x.id) || ""),
                name: String((x && x.name) || (x && x.label) || ""),
                icon: String((x && x.icon) || ""),
                exec: String((x && x.exec) || "")
            };
        }).filter(function (x) { return x.exec !== ""; });
    }
    readonly property var pinnedApps: {
        if (root.menuApps.length > 0) return root.menuApps.slice(0, 18);
        let all = (root.appCatalog && root.appCatalog.length > 0) ? root.appCatalog : root.apps;
        return all.slice(0, 18);
    }

    function openMenu(screenName) {
        root.menuScreenName = String(screenName || "");
        root.popupOpen = false;
        root.popupKind = "";
        root.popupScreenName = "";
        root.query = "";
        root.menuOpen = true;
    }
    function toggleMenu(screenName) {
        if (root.menuOpen && root.menuScreenName === String(screenName))
            root.closeMenu();
        else
            root.openMenu(screenName);
    }
    function openUtility(screenName, kind) {
        root.menuOpen = false;
        root.menuScreenName = "";
        root.query = "";
        root.popupKind = String(kind || "settings");
        root.popupScreenName = String(screenName || "");
        root.popupOpen = true;
        if (root.popupKind === "clock") root.updateCalendar();
        if (root.popupKind === "battery") root.refreshBatteryInfo();
    }
    function closeMenu() {
        root.menuOpen = false;
        root.menuScreenName = "";
        root.query = "";
        root.popupOpen = false;
        root.popupKind = "";
        root.popupScreenName = "";
    }
    function setCfg(key, value) {
        if (key === "layoutMode") root.layoutMode = String(value);
        else if (key === "themeMode") root.themeMode = String(value);
        else if (key === "iconPalette") root.iconPalette = value === true;
        else if (key === "barHeight") root.barHeight = clamp(Number(value) || 48, 38, 68);
        else if (key === "opacity") root.opacitySetting = clamp(Number(value) || 0.92, 0.35, 1.0);
        else if (key === "showSearch") root.showSearch = value === true;
        else if (key === "showClock") root.showClock = value === true;
        else if (key === "showWeather") root.showWeather = value === true;
        else if (key === "showBattery") root.showBattery = value === true;
        else if (key === "showUser") root.showUser = value === true;
        if (root.host && root.host.settings) root.host.settings.set(key, value);
    }
    function updateCalendar() {
        let now = new Date();
        let y = now.getFullYear();
        let m = now.getMonth();
        let first = new Date(y, m, 1).getDay();
        let days = new Date(y, m + 1, 0).getDate();
        let cells = [];
        for (let i = 0; i < first; i++) cells.push({ day: "", today: false });
        for (let d = 1; d <= days; d++) cells.push({ day: d, today: d === now.getDate() });
        while (cells.length % 7 !== 0) cells.push({ day: "", today: false });
        root.calendarCells = cells;
        root.calendarTitle = Qt.formatDate(now, "MMMM yyyy").toUpperCase();
    }
    function refreshBatteryInfo() {
        batteryInfoProc.running = false;
        batteryInfoProc.running = true;
    }

    function run(cmd) {
        if (!cmd || String(cmd).trim() === "") return;
        Quickshell.execDetached(["bash", "-lc", String(cmd)]);
    }
    function launchApp(app) {
        root.closeMenu();
        root.run(String((app && app.exec) || ""));
    }
    function runPower(action) {
        root.closeMenu();
        if (action === "lock") root.run("loginctl lock-session");
        else if (action === "logout") root.run("hyprctl dispatch 'hl.dsp.exit()'");
        else if (action === "restart") root.run("systemctl reboot --no-block");
        else if (action === "shutdown") root.run("systemctl poweroff --no-block");
        else if (action === "settings") root.openSettingsPage();
    }
    function openSettingsPage() {
        root.closeMenu();
        root.run("~/.config/hypr/scripts/qs_manager.sh close >/dev/null 2>&1; ~/.config/hypr/scripts/qs_manager.sh open plugins w11");
    }

    function appIcon(app) {
        let ic = String((app && app.icon) || "").trim();
        if (ic === "") return "";
        return ic.charAt(0) === "/" ? "file://" + ic : "image://icon/" + ic;
    }

    // ── clock ────────────────────────────────────────────────────────────────
    property string clockText: ""
    property string dateText: ""
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            root.clockText = Qt.formatDateTime(d, "HH:mm");
            root.clockSeconds = Qt.formatDateTime(d, "HH:mm:ss");
            root.dateText = Qt.formatDateTime(d, "ddd dd MMM").toUpperCase();
            if (root.calendarCells.length === 0) root.updateCalendar();
        }
    }

    // ── app catalog ───────────────────────────────────────────────────────────
    readonly property string appsScript: String(Qt.resolvedUrl("../scripts/apps.sh")).replace("file://", "")
    Process {
        id: appsProc
        command: ["bash", root.appsScript]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.appCatalog = (JSON.parse(this.text).apps) || []; }
                catch (e) { root.appCatalog = []; }
            }
        }
    }

    // ── user / weather / battery ──────────────────────────────────────────────
    property string userName: Quickshell.env("USER") || "user"
    property string hostName: "computer"
    Process {
        id: userProc
        command: ["bash", "-c", "printf '%s\\t%s' \"$USER\" \"$(hostname -s)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = String(this.text || "").trim().split("\t");
                if (p.length >= 2) {
                    if (p[0]) root.userName = p[0];
                    if (p[1]) root.hostName = p[1];
                }
            }
        }
    }

    readonly property string timexCache: {
        let v = Quickshell.env("QS_CACHE_TIMEX");
        return (v && v !== "") ? v : Quickshell.env("HOME") + "/.cache/quickshell/timex";
    }
    property var weatherData: null
    readonly property string temperature: {
        let t = root.weatherData && root.weatherData.current_temp;
        if (t === undefined || t === null || String(t).trim() === "") return "--°";
        let n = Math.round(Number(t));
        return isNaN(n) ? "--°" : n + "°";
    }
    readonly property string weatherCondition: {
        let f = root.weatherData && root.weatherData.forecast;
        return (f && f.length > 0 && f[0] && f[0].desc) ? String(f[0].desc) : "WEATHER";
    }
    readonly property string weatherIcon: {
        return (root.weatherData && root.weatherData.current_icon) ? String(root.weatherData.current_icon) : "󰖐";
    }
    property var weatherHourly: []
    Process {
        id: weatherProc
        command: ["bash", "-c", "cat '" + root.timexCache + "/weather.json' 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.weatherData = JSON.parse(this.text || "null"); }
                catch (e) { root.weatherData = null; }
                let out = [];
                let f = root.weatherData && root.weatherData.forecast;
                if (f && f.length > 0 && f[0] && f[0].hourly) {
                    for (let i = 0; i < Math.min(4, f[0].hourly.length); i++) out.push(f[0].hourly[i]);
                }
                root.weatherHourly = out;
            }
        }
    }
    Timer { interval: 150000; running: true; repeat: true; onTriggered: weatherProc.running = true }

    property int batteryPct: -1
    Process {
        id: batteryProc
        command: ["bash", "-c", "p=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1); [ -n \"$p\" ] && printf '%s' \"$p\" || printf '%s' '-1'"]
        stdout: StdioCollector { onStreamFinished: root.batteryPct = parseInt(this.text) || -1 }
    }
    Timer { interval: 20000; running: true; repeat: true; onTriggered: batteryProc.running = true }
    readonly property string batteryScript: String(Qt.resolvedUrl("../scripts/battery-info.sh")).replace("file://", "")
    Process {
        id: batteryInfoProc
        command: ["bash", root.batteryScript]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = String(this.text || "").trim().split("\t");
                if (p.length >= 6) {
                    root.batteryState = p[0] || "Unknown";
                    root.batteryHealth = parseInt(p[3]) || -1;
                    root.batteryCycles = parseInt(p[4]) || -1;
                    root.batteryWatts = parseFloat(p[2]) || 0;
                }
            }
        }
    }
    Timer { interval: 30000; running: root.popupKind === "battery"; repeat: true; onTriggered: root.refreshBatteryInfo() }

    Component.onCompleted: {
        root.applyCfg();
        appsProc.running = true;
        userProc.running = true;
        weatherProc.running = true;
        batteryProc.running = true;
        root.updateCalendar();
    }
    onHostChanged: root.applyCfg()
    Connections {
        target: root.host ? root.host.settings : null
        function onChanged() { root.applyCfg(); }
        function onKeyChanged() { root.applyCfg(); }
    }

    // ── reusable bar pieces ───────────────────────────────────────────────────
    component XButton: Item {
        id: xb
        width: 40; height: 36
        property bool active: false
        signal clicked()
        Rectangle {
            anchors.fill: parent
            radius: 7
            color: xb.active || xMouse.containsMouse ? root.hover : "transparent"
        }
        Item {
            anchors.centerIn: parent
            width: 18; height: 18
            Rectangle { x: 0; y: 0; width: 8; height: 8; radius: 1; color: root.accent }
            Rectangle { x: 10; y: 0; width: 8; height: 8; radius: 1; color: root.accent }
            Rectangle { x: 0; y: 10; width: 8; height: 8; radius: 1; color: root.accent }
            Rectangle { x: 10; y: 10; width: 8; height: 8; radius: 1; color: root.accent }
        }
        MouseArea {
            id: xMouse; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: xb.clicked()
        }
    }

    component PinButton: Item {
        id: pb
        property var app: ({})
        signal clicked()
        width: 38; height: 36
        Rectangle {
            anchors.fill: parent; radius: 7
            color: pbMouse.containsMouse ? root.hover : "transparent"
        }
        Text {
            anchors.centerIn: parent
            text: String((pb.app && pb.app.glyph) || "󰀻")
            font.family: root.iconFont
            font.pixelSize: 18
            color: root.glyphColor
        }
        MouseArea {
            id: pbMouse; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pb.clicked()
        }
    }

    component SearchButton: Item {
        width: 36; height: 36
        signal clicked()
        Rectangle {
            anchors.fill: parent; radius: 7
            color: sbMouse.containsMouse ? root.hover : "transparent"
        }
        Text {
            anchors.centerIn: parent; text: "󰍉"
            font.family: root.iconFont; font.pixelSize: 17; color: root.fg
        }
        MouseArea {
            id: sbMouse; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component StatusText: Item {
        id: st
        property string label: ""
        property string value: ""
        property string glyph: ""
        property bool clickable: false
        signal clicked()
        width: Math.max(50, stCol.implicitWidth + 10); height: 34
        Row {
            id: stCol
            anchors.centerIn: parent
            spacing: 4
            Text {
                visible: st.glyph !== ""
                text: st.glyph
                font.family: root.iconFont; font.pixelSize: 14; color: root.fg
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: st.value !== "" ? st.value : st.label
                font.family: root.uiFont; font.pixelSize: 12; color: root.fg
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        MouseArea {
            anchors.fill: parent
            enabled: st.clickable
            hoverEnabled: st.clickable
            cursorShape: Qt.PointingHandCursor
            onClicked: st.clicked()
        }
    }

    component ClockBlock: Item {
        id: cb
        signal clicked()
        width: clockCol.implicitWidth + 12; height: 36
        Column {
            id: clockCol
            anchors.centerIn: parent
            spacing: 0
            Text {
                text: root.clockText
                font.family: root.uiFont; font.pixelSize: 13; font.weight: Font.DemiBold
                color: root.fg; horizontalAlignment: Text.AlignRight
            }
            Text {
                visible: root.showClock
                text: root.dateText
                font.family: root.uiFont; font.pixelSize: 9; color: root.dim
                horizontalAlignment: Text.AlignRight
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: cb.clicked()
        }
    }

    component GearButton: Item {
        width: 36; height: 36
        signal clicked()
        signal pressAndHold()
        Rectangle {
            anchors.fill: parent; radius: 7
            color: gearMouse.containsMouse ? root.hover : "transparent"
        }
        Text {
            anchors.centerIn: parent; text: "󰒓"
            font.family: root.iconFont; font.pixelSize: 17; color: root.fg
        }
        MouseArea {
            id: gearMouse; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
            onPressAndHold: parent.pressAndHold()
        }
    }

    component UserButton: Item {
        width: 38; height: 36
        signal clicked()
        Rectangle {
            anchors.centerIn: parent
            width: 27; height: 27; radius: 14
            color: root.accent
        }
        Text {
            anchors.centerIn: parent
            text: root.userName.length > 0 ? root.userName.charAt(0).toUpperCase() : "?"
            font.family: root.uiFont; font.pixelSize: 12; font.weight: Font.Bold
            color: root.paletteMode ? root.panelColor : "#ffffff"
        }
        MouseArea {
            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component PowerButton: Item {
        id: pw
        property string glyph: ""
        property string label: ""
        signal clicked()
        width: 64; height: 54
        Rectangle {
            anchors.fill: parent; radius: 7
            color: pwMouse.containsMouse ? root.hover : "transparent"
        }
        Column {
            anchors.centerIn: parent
            spacing: 2
            Text {
                text: pw.glyph; font.family: root.iconFont; font.pixelSize: 16
                color: root.fg; anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: pw.label; font.family: root.uiFont; font.pixelSize: 8
                color: root.dim; anchors.horizontalCenter: parent.horizontalCenter
            }
        }
        MouseArea {
            id: pwMouse; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pw.clicked()
        }
    }

    component QuickChoice: Item {
        id: qc
        Layout.fillWidth: true
        property string label: ""
        property var options: []
        property string value: ""
        signal chosen(string value)
        width: parent ? parent.width : 0
        height: 32
        Text {
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
            text: qc.label
            font.family: root.uiFont; font.pixelSize: 10; color: root.dim
        }
        Row {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            Repeater {
                model: qc.options
                delegate: Rectangle {
                    required property var modelData
                    width: 80; height: 26; radius: 5
                    color: modelData.value === qc.value ? root.accent : root.hover
                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.family: root.uiFont; font.pixelSize: 9
                        color: modelData.value === qc.value ? (root.paletteMode ? root.panelColor : "#ffffff") : root.fg
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: qc.chosen(modelData.value)
                    }
                }
            }
        }
    }

    component QuickToggle: Item {
        id: qt
        Layout.fillWidth: true
        property string label: ""
        property bool checked: false
        signal toggled(bool value)
        width: parent ? parent.width : 0
        height: 32
        Text {
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
            text: qt.label
            font.family: root.uiFont; font.pixelSize: 10; color: root.dim
        }
        Rectangle {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            width: 30; height: 16; radius: 8
            color: qt.checked ? root.accent : root.hover
            Rectangle {
                width: 12; height: 12; radius: 6
                x: qt.checked ? parent.width - width - 2 : 2
                anchors.verticalCenter: parent.verticalCenter
                color: qt.checked ? (root.paletteMode ? root.panelColor : "#ffffff") : root.fg
                Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }
        }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: qt.toggled(!qt.checked)
        }
    }

    // ── surfaces ──────────────────────────────────────────────────────────────
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: win
                required property var modelData
                screen: modelData
                readonly property string screenKey: (modelData && (modelData.name || modelData.model)) ? String(modelData.name || modelData.model) : ""
                readonly property bool menuCurrent: root.menuOpen && root.menuScreenName === win.screenKey
                readonly property bool popupCurrent: root.popupOpen && root.popupScreenName === win.screenKey
                readonly property bool current: win.menuCurrent || win.popupCurrent

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true
                implicitWidth: modelData ? modelData.width : 1920
                implicitHeight: modelData ? modelData.height : 1080
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                focusable: win.current
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "equisdots-w11"
                mask: Region { item: win.current ? fullMask : taskbar }

                Item {
                    id: fullMask
                    anchors.fill: parent
                    visible: win.current
                    z: 0
                    MouseArea {
                        anchors.fill: parent
                        enabled: win.current
                        onClicked: root.closeMenu()
                    }
                }

                Rectangle {
                    id: taskbar
                    z: 2
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: root.compact ? root.barH + 20 : root.barH
                    color: root.compact ? "transparent" : root.panelColor

                    Rectangle {
                        id: compactBg
                        visible: root.compact
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10
                        width: Math.min(parent.width - 24, 640)
                        height: root.barH
                        radius: 12
                        color: root.panelColor
                        border.width: 1
                        border.color: root.line
                    }

                    Row {
                        id: compactRow
                        visible: root.compact
                        anchors.centerIn: compactBg
                        spacing: 4

                        XButton {
                            active: win.current
                            onClicked: root.toggleMenu(win.screenKey)
                        }
                        SearchButton {
                            visible: root.showSearch
                            onClicked: root.openMenu(win.screenKey)
                        }
                        Repeater {
                            model: root.apps
                            delegate: PinButton {
                                required property var modelData
                                app: modelData
                                onClicked: root.launchApp(modelData)
                            }
                        }
                        StatusText {
                            visible: root.showWeather
                            value: root.temperature
                            glyph: root.weatherIcon
                            clickable: true
                            onClicked: root.openUtility(win.screenKey, "weather")
                        }
                        StatusText {
                            visible: root.showBattery && root.batteryPct >= 0
                            value: root.batteryPct >= 0 ? root.batteryPct + "%" : ""
                            glyph: root.batteryPct >= 0 && root.batteryPct <= 20 ? "󰁺" : "󰁹"
                            clickable: true
                            onClicked: root.openUtility(win.screenKey, "battery")
                        }
                        ClockBlock {
                            visible: root.showClock
                            onClicked: root.openUtility(win.screenKey, "clock")
                        }
                        GearButton {
                            onClicked: root.openSettingsPage()
                            onPressAndHold: root.openUtility(win.screenKey, "settings")
                        }
                        UserButton {
                            visible: root.showUser
                            onClicked: root.toggleMenu(win.screenKey)
                        }
                    }

                    Row {
                        id: leftRow
                        visible: !root.compact
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        XButton {
                            active: win.current
                            onClicked: root.toggleMenu(win.screenKey)
                        }
                        SearchButton {
                            visible: root.showSearch
                            onClicked: root.openMenu(win.screenKey)
                        }
                    }

                    Row {
                        id: centerRow
                        visible: !root.compact
                        anchors.centerIn: parent
                        spacing: 4
                        Repeater {
                            model: root.apps
                            delegate: PinButton {
                                required property var modelData
                                app: modelData
                                onClicked: root.launchApp(modelData)
                            }
                        }
                    }

                    Row {
                        id: rightRow
                        visible: !root.compact
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        StatusText {
                            visible: root.showWeather
                            value: root.temperature
                            glyph: root.weatherIcon
                            clickable: true
                            onClicked: root.openUtility(win.screenKey, "weather")
                        }
                        StatusText {
                            visible: root.showBattery && root.batteryPct >= 0
                            value: root.batteryPct >= 0 ? root.batteryPct + "%" : ""
                            glyph: root.batteryPct >= 0 && root.batteryPct <= 20 ? "󰁺" : "󰁹"
                            clickable: true
                            onClicked: root.openUtility(win.screenKey, "battery")
                        }
                        ClockBlock {
                            visible: root.showClock
                            onClicked: root.openUtility(win.screenKey, "clock")
                        }
                        GearButton {
                            onClicked: root.openSettingsPage()
                            onPressAndHold: root.openUtility(win.screenKey, "settings")
                        }
                        UserButton {
                            visible: root.showUser
                            onClicked: root.toggleMenu(win.screenKey)
                        }
                    }
                }

                Rectangle {
                    id: startMenu
                    z: 3
                    visible: win.menuCurrent || opacity > 0.01
                    opacity: win.menuCurrent ? 1 : 0
                    scale: win.menuCurrent ? 1 : 0.96
                    transformOrigin: Item.Bottom
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    width: Math.min(root.compact ? 520 : 460, parent.width - 24)
                    height: Math.min(600, parent.height - taskbar.height - 28)
                    x: root.compact
                        ? Math.round((parent.width - width) / 2)
                        : Math.max(8, Math.min(taskbar.x + 8, parent.width - width - 8))
                    y: taskbar.y - height - 8
                    radius: 12
                    color: root.popupColor
                    border.width: 1
                    border.color: root.line

                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: {} }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Rectangle {
                                width: 38; height: 38; radius: 19
                                color: root.accent
                                Text {
                                    anchors.centerIn: parent
                                    text: root.userName.length > 0 ? root.userName.charAt(0).toUpperCase() : "?"
                                    font.family: root.uiFont; font.pixelSize: 16; font.weight: Font.Bold
                                    color: root.paletteMode ? root.panelColor : "#ffffff"
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    text: root.userName
                                    font.family: root.uiFont; font.pixelSize: 13; font.weight: Font.DemiBold
                                    color: root.fg; elide: Text.ElideRight
                                }
                                Text {
                                    text: root.hostName
                                    font.family: root.uiFont; font.pixelSize: 10
                                    color: root.dim; elide: Text.ElideRight
                                }
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "W11"
                                font.family: root.uiFont; font.pixelSize: 11; font.weight: Font.Bold
                                color: root.dim
                            }
                        }

                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            placeholderText: "Search apps…"
                            placeholderTextColor: root.dim
                            color: root.fg
                            font.family: root.uiFont
                            font.pixelSize: 13
                            leftPadding: 12; rightPadding: 12
                            selectByMouse: true
                            focus: win.current
                            background: Rectangle {
                                color: root.paletteMode ? root.hover : Qt.rgba(0, 0, 0, 0.24)
                                radius: 7
                                border.width: 1
                                border.color: searchField.activeFocus ? root.accent : root.line
                            }
                            onTextChanged: root.query = text
                            Keys.onEscapePressed: root.closeMenu()
                            Keys.onReturnPressed: {
                                if (root.searchResults.length > 0)
                                    root.launchApp(root.searchResults[0]);
                            }
                            onActiveFocusChanged: if (activeFocus) root.query = text
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1; color: root.line
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: root.query.trim() === ""
                            text: "PINNED"
                            font.family: root.uiFont; font.pixelSize: 10; font.weight: Font.DemiBold
                            color: root.dim; leftPadding: 4
                        }

                        GridView {
                            id: pinnedGrid
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.query.trim() === "" ? 218 : 0
                            visible: root.query.trim() === ""
                            clip: true
                            cellWidth: width / 6
                            cellHeight: 70
                            model: root.pinnedApps
                            boundsBehavior: Flickable.StopAtBounds
                            delegate: Item {
                                required property var modelData
                                width: pinnedGrid.cellWidth
                                height: pinnedGrid.cellHeight
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    radius: 7
                                    color: gridMouse.containsMouse ? root.hover : "transparent"
                                }
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    width: parent.width - 8
                                    Item {
                                        width: 38; height: 38
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        Image {
                                            anchors.centerIn: parent
                                            width: 34; height: 34
                                            source: root.appIcon(modelData)
                                            sourceSize: Qt.size(34, 34)
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                            visible: source !== ""
                                        }
                                        Text {
                                            anchors.centerIn: parent
                                            visible: root.appIcon(modelData) === ""
                                            text: String(modelData.glyph || (modelData.name ? modelData.name.charAt(0) : "?"))
                                            font.family: root.iconFont; font.pixelSize: 28
                                            color: root.tintIcons ? root.accent : root.fg
                                        }
                                    }
                                    Text {
                                        width: parent.width
                                        text: String(modelData.name || modelData.label || modelData.id || "")
                                        font.family: root.uiFont; font.pixelSize: 9
                                        color: root.fg
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }
                                }
                                MouseArea {
                                    id: gridMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.launchApp(modelData)
                                }
                            }
                        }

                        ListView {
                            id: results
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: root.query.trim() !== ""
                            clip: true
                            model: root.searchResults
                            spacing: 2
                            boundsBehavior: Flickable.StopAtBounds
                            delegate: Rectangle {
                                required property var modelData
                                width: results.width
                                height: 42
                                radius: 6
                                color: appMouse.containsMouse ? root.hover : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 10
                                    Image {
                                        Layout.preferredWidth: 25
                                        Layout.preferredHeight: 25
                                        source: root.appIcon(modelData)
                                        sourceSize: Qt.size(25, 25)
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        visible: source !== ""
                                    }
                                    Text {
                                        visible: root.appIcon(modelData) === ""
                                        text: String(modelData.name || "").length > 0 ? String(modelData.name).charAt(0).toUpperCase() : "?"
                                        font.family: root.uiFont; font.pixelSize: 13; color: root.accent
                                        Layout.preferredWidth: 25; horizontalAlignment: Text.AlignHCenter
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Text {
                                            text: String(modelData.name || modelData.id || "")
                                            font.family: root.uiFont; font.pixelSize: 12
                                            color: root.fg; elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: String(modelData.id || "")
                                            font.family: root.uiFont; font.pixelSize: 9
                                            color: root.dim; elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                }
                                MouseArea {
                                    id: appMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.launchApp(modelData)
                                }
                            }
                            Text {
                                visible: results.count === 0
                                anchors.centerIn: parent
                                text: root.appCatalog.length === 0 ? "Loading apps…" : "No applications found"
                                font.family: root.uiFont; font.pixelSize: 11; color: root.dim
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1; color: root.line
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            PowerButton { glyph: "󰌾"; label: "Lock"; onClicked: root.runPower("lock") }
                            PowerButton { glyph: "󰍃"; label: "Log out"; onClicked: root.runPower("logout") }
                            PowerButton { glyph: "󰜉"; label: "Restart"; onClicked: root.runPower("restart") }
                            PowerButton { glyph: "󰐥"; label: "Shut down"; onClicked: root.runPower("shutdown") }
                            Item { Layout.fillWidth: true }
                            PowerButton { glyph: "󰒓"; label: "Settings"; onClicked: root.runPower("settings") }
                        }
                    }

                    onVisibleChanged: {
                        if (visible) Qt.callLater(function () { searchField.forceActiveFocus(); });
                    }
                }

                Rectangle {
                    id: utilityPopup
                    z: 3
                    visible: win.popupCurrent || opacity > 0.01
                    opacity: win.popupCurrent ? 1 : 0
                    scale: win.popupCurrent ? 1 : 0.96
                    transformOrigin: Item.Bottom
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    width: root.popupKind === "battery" ? 300
                        : root.popupKind === "clock" ? 340
                        : root.popupKind === "weather" ? 320 : 360
                    height: root.popupKind === "battery" ? 250
                        : root.popupKind === "clock" ? 410
                        : root.popupKind === "weather" ? 300 : 360
                    x: root.compact
                        ? Math.round((parent.width - width) / 2)
                        : Math.max(12, parent.width - width - 16)
                    y: taskbar.y - height - 8
                    radius: 12
                    color: root.popupColor
                    border.width: 1
                    border.color: root.line
                    focus: win.popupCurrent
                    Keys.onEscapePressed: root.closeMenu()

                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: {} }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: root.popupKind === "battery" ? "BATTERY"
                                    : root.popupKind === "clock" ? "CLOCK"
                                    : root.popupKind === "weather" ? "WEATHER"
                                    : "QUICK SETTINGS"
                                font.family: root.uiFont; font.pixelSize: 12; font.weight: Font.DemiBold
                                color: root.fg
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "✕"
                                font.family: root.iconFont; font.pixelSize: 14; color: root.dim
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.closeMenu() }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: root.line }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: root.popupKind === "battery"
                            spacing: 8
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: root.batteryPct >= 0 ? root.batteryPct + "%" : "--"
                                    font.family: root.uiFont; font.pixelSize: 34; font.weight: Font.Bold
                                    color: root.fg
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: root.batteryPct >= 0 ? root.batteryState.toUpperCase() : "NO BATTERY"
                                    font.family: root.uiFont; font.pixelSize: 10
                                    color: root.dim
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 8; radius: 4
                                color: root.hover
                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, root.batteryPct / 100))
                                    height: parent.height; radius: parent.radius
                                    color: root.batteryPct <= 20 ? root.accent : root.fg
                                }
                            }
                            Item { Layout.preferredHeight: 4 }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "HEALTH"; font.family: root.uiFont; font.pixelSize: 10; color: root.dim; Layout.fillWidth: true }
                                Text { text: root.batteryHealth > 0 ? root.batteryHealth + "%" : "--"; font.family: root.uiFont; font.pixelSize: 11; color: root.fg }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "CYCLES"; font.family: root.uiFont; font.pixelSize: 10; color: root.dim; Layout.fillWidth: true }
                                Text { text: root.batteryCycles > 0 ? String(root.batteryCycles) : "--"; font.family: root.uiFont; font.pixelSize: 11; color: root.fg }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "POWER"; font.family: root.uiFont; font.pixelSize: 10; color: root.dim; Layout.fillWidth: true }
                                Text { text: root.batteryWatts > 0 ? root.batteryWatts + " W" : "--"; font.family: root.uiFont; font.pixelSize: 11; color: root.fg }
                            }
                            Item { Layout.fillHeight: true }
                            Text {
                                text: "Click the battery indicator to refresh"
                                font.family: root.uiFont; font.pixelSize: 9; color: root.dim
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: root.popupKind === "clock"
                            spacing: 4
                            Text {
                                text: root.clockSeconds
                                font.family: root.uiFont; font.pixelSize: 34; font.weight: Font.Bold
                                color: root.fg
                            }
                            Text {
                                text: root.dateText
                                font.family: root.uiFont; font.pixelSize: 11; color: root.dim
                            }
                            Rectangle { Layout.fillWidth: true; height: 1; color: root.line }
                            Text {
                                text: root.calendarTitle
                                font.family: root.uiFont; font.pixelSize: 11; font.weight: Font.DemiBold
                                color: root.fg
                            }
                            Row {
                                Layout.fillWidth: true
                                height: 20
                                Repeater {
                                    model: ["M", "T", "W", "T", "F", "S", "S"]
                                    delegate: Text {
                                        width: parent.width / 7
                                        horizontalAlignment: Text.AlignHCenter
                                        text: modelData
                                        font.family: root.uiFont; font.pixelSize: 9; color: root.dim
                                    }
                                }
                            }
                            Grid {
                                id: calendarGrid
                                Layout.fillWidth: true
                                columns: 7
                                Repeater {
                                    model: root.calendarCells
                                    delegate: Rectangle {
                                        required property var modelData
                                        width: calendarGrid.width / 7
                                        height: 26
                                        radius: 5
                                        color: modelData.today ? root.accent : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.day === "" ? "" : String(modelData.day)
                                            font.family: root.uiFont; font.pixelSize: 10
                                            color: modelData.today ? (root.paletteMode ? root.panelColor : "#ffffff") : root.fg
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: root.popupKind === "weather"
                            spacing: 8
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                Text {
                                    text: root.weatherIcon
                                    font.family: root.iconFont; font.pixelSize: 34
                                    color: root.accent
                                }
                                ColumnLayout {
                                    spacing: 0
                                    Text {
                                        text: root.temperature
                                        font.family: root.uiFont; font.pixelSize: 34; font.weight: Font.Bold
                                        color: root.fg
                                    }
                                    Text {
                                        text: root.weatherCondition.toUpperCase()
                                        font.family: root.uiFont; font.pixelSize: 10; color: root.dim
                                    }
                                }
                                Item { Layout.fillWidth: true }
                            }
                            Rectangle { Layout.fillWidth: true; height: 1; color: root.line }
                            Text {
                                Layout.fillWidth: true
                                text: "FORECAST"
                                font.family: root.uiFont; font.pixelSize: 10; font.weight: Font.DemiBold
                                color: root.dim
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Repeater {
                                    model: root.weatherHourly
                                    delegate: ColumnLayout {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.time ? String(modelData.time).slice(0, 5) : "--:--"
                                            font.family: root.uiFont; font.pixelSize: 9; color: root.dim
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.temp !== undefined ? Math.round(Number(modelData.temp)) + "°" : "--°"
                                            font.family: root.uiFont; font.pixelSize: 12; font.weight: Font.DemiBold
                                            color: root.fg; horizontalAlignment: Text.AlignHCenter
                                        }
                                    }
                                }
                            }
                            Text {
                                visible: root.weatherHourly.length === 0
                                Layout.fillWidth: true
                                text: "Weather data is not available yet."
                                font.family: root.uiFont; font.pixelSize: 10; color: root.dim
                            }
                            Item { Layout.fillHeight: true }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: root.popupKind === "settings"
                            spacing: 8
                            QuickChoice {
                                label: "Taskbar"
                                options: [
                                    { value: "full", label: "Full width" },
                                    { value: "compact", label: "Compact" }
                                ]
                                value: root.layoutMode
                                onChosen: (v) => root.setCfg("layoutMode", v)
                            }
                            QuickChoice {
                                label: "Style"
                                options: [
                                    { value: "windows11", label: "Windows 11" },
                                    { value: "palette", label: "Palette" }
                                ]
                                value: root.themeMode
                                onChosen: (v) => root.setCfg("themeMode", v)
                            }
                            QuickToggle {
                                label: "Tint launcher glyphs"
                                checked: root.iconPalette
                                onToggled: (v) => root.setCfg("iconPalette", v)
                            }
                            Item { Layout.fillHeight: true }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 32; radius: 6
                                color: root.accent
                                Text {
                                    anchors.centerIn: parent
                                    text: "OPEN W11 SETTINGS"
                                    font.family: root.uiFont; font.pixelSize: 10; font.weight: Font.DemiBold
                                    color: root.paletteMode ? root.panelColor : "#ffffff"
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.runPower("settings")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
