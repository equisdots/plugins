import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.core

// ═══════════════════════════════════════════════════════════════════════════
// mos Topbar — a macOS 27 menu-bar-style complete bar for Hyprland.
//
// Structure follows the macOS HIG: Apple menu, app menu, File, Edit, Format,
// View, Window, Help on the leading edge; menu bar extras on the trailing
// edge. Menus are real clickable popovers. System actions map to Hyprland,
// nmcli, bluetoothctl, wpctl, brightnessctl and loginctl where possible.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    visible: false
    width: 0
    height: 0

    property var host: null

    readonly property var _fb: ({
        base: "#0a0a0a", text: "#f5f5f7", subtext0: "#a1a1a6",
        surface0: "#1c1c1e", red: "#ff453a", green: "#30d158",
        yellow: "#ffd60a", blue: "#0a84ff"
    })
    readonly property var c: (host && host.colors) ? host.colors : _fb
    readonly property var cfg: {
        let s = host && host.settings;
        if (!s) return ({});
        s.revision; // reactive dependency for settings edits
        return s.all();
    }

    function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }

    readonly property int barH: clamp(Number(cfg.height) || 24, 20, 32)
    readonly property int itemSpacing: clamp(Number(cfg.itemSpacing) || 5, 0, 14)
    readonly property string uiFont: "Noto Sans"
    readonly property string iconFont: "Hack Nerd Font"
    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/plugins/mos-topbar/scripts"

    readonly property color textColor: "#f5f5f7"
    readonly property color dimColor: Qt.rgba(1, 1, 1, 0.62)
    readonly property color barColor: Qt.rgba(0.055, 0.055, 0.065,
        clamp(Number(cfg.barOpacity) || 0.66, 0.15, 1.0))
    readonly property color menuColor: Qt.rgba(0.09, 0.09, 0.10,
        clamp(Number(cfg.menuOpacity) || 0.95, 0.35, 1.0))
    readonly property color menuBorder: Qt.rgba(1, 1, 1, 0.16)
    readonly property color hoverColor: Qt.rgba(1, 1, 1, 0.14)
    readonly property color accent: "#0a84ff"

    // ── live state ─────────────────────────────────────────────────────────
    property string activeApp: "Finder"
    property string clockText: ""
    property string dateText: ""
    property bool wifiOn: true
    property bool btOn: false
    property int batPct: -1
    property int volume: 0
    property int brightness: 0

    Process {
        id: activeProc
        command: ["bash", root.scriptsDir + "/active.sh"]
        stdout: StdioCollector { onStreamFinished: root.activeApp = (this.text || "").trim() || "Finder" }
    }
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { activeProc.running = false; activeProc.running = true; } }

    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            root.clockText = Qt.formatDateTime(d, root.cfg.showSeconds ? "HH:mm:ss" : "HH:mm");
            root.dateText = Qt.formatDateTime(d, "ddd d MMM");
        }
    }

    Process {
        id: wifiProc
        command: ["bash", root.scriptsDir + "/wifi.sh"]
        stdout: StdioCollector { onStreamFinished: root.wifiOn = (this.text || "").trim() === "on" }
    }
    Process {
        id: btProc
        command: ["bash", root.scriptsDir + "/bluetooth.sh"]
        stdout: StdioCollector { onStreamFinished: root.btOn = (this.text || "").trim() === "on" }
    }
    Process {
        id: batteryProc
        command: ["bash", root.scriptsDir + "/battery.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let t = (this.text || "").trim();
                root.batPct = t === "AC" ? -1 : (parseInt(t.split(" ")[0]) || -1);
            }
        }
    }
    Process {
        id: controlProc
        command: ["bash", root.scriptsDir + "/control.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let o = JSON.parse((this.text || "{}").trim());
                    root.volume = Number(o.volume) || 0;
                    root.brightness = Number(o.brightness) || 0;
                } catch (e) {}
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true
        onTriggered: { wifiProc.running = false; wifiProc.running = true; btProc.running = false; btProc.running = true; } }
    Timer { interval: 20000; running: true; repeat: true
        onTriggered: { batteryProc.running = false; batteryProc.running = true; } }
    Timer { interval: 2000; running: root.menuKind === "control" || root.menuKind === "clock"; repeat: true
        onTriggered: root.refreshControl() }

    function refreshWifi() { wifiProc.running = false; wifiProc.running = true; }
    function refreshBt() { btProc.running = false; btProc.running = true; }
    function refreshControl() { controlProc.running = false; controlProc.running = true; }
    function toggleWifi() {
        root.wifiOn = !root.wifiOn;
        root.exec("nmcli radio wifi " + (root.wifiOn ? "on" : "off"));
        root.refreshWifi();
    }
    function toggleBt() {
        root.btOn = !root.btOn;
        root.exec("bluetoothctl power " + (root.btOn ? "on" : "off"));
        root.refreshBt();
    }

    // ── menu state ─────────────────────────────────────────────────────────
    property string menuKind: ""
    property var menuScreen: null
    property real menuAnchorX: 0
    property bool menuAlignRight: false
    property var menuItems: []
    readonly property bool menuOpen: menuKind !== ""

    function closeMenu() {
        root.menuKind = "";
        root.menuItems = [];
    }

    function item(label, action, shortcut, enabled) {
        return { label: label, action: action || "", shortcut: shortcut || "", enabled: enabled !== false };
    }
    function sep() { return { separator: true }; }

    function menuItemsFor(kind) {
        let app = root.activeApp;
        if (kind === "apple") {
            return [
                item("About This Mac", "about", "", false),
                sep(),
                item("System Settings…", "settings", "⌘,"),
                item("App Store…", "appstore", "", false),
                sep(),
                item("Recent Items", "recent", "", false),
                sep(),
                item("Sleep", "sleep", ""),
                item("Restart…", "restart", "", false),
                item("Shut Down…", "shutdown", "", false),
                sep(),
                item("Lock Screen", "lock", "⌃⌘Q"),
                item("Log Out…", "logout", "⇧⌘Q")
            ];
        }
        if (kind === "app") {
            return [
                item("About " + app, "about", "", false),
                item("Settings…", "settings", "⌘,"),
                sep(),
                item("Hide " + app, "hide", "⌘H", false),
                item("Hide Others", "hideOthers", "⌥⌘H", false),
                item("Show All", "showAll", "", false),
                sep(),
                item("Quit " + app, "quit", "⌘Q")
            ];
        }
        if (kind === "file") {
            return [
                item("New Window", "newWindow", "⌘N", false),
                item("Open…", "open", "⌘O", false),
                item("Open Recent", "recent", "", false),
                sep(),
                item("Close Window", "close", "⌘W"),
                item("Save", "save", "⌘S", false),
                sep(),
                item("Page Setup…", "pageSetup", "", false),
                item("Print…", "print", "⌘P", false)
            ];
        }
        if (kind === "edit") {
            return [
                item("Undo", "undo", "⌘Z", false),
                item("Redo", "redo", "⇧⌘Z", false),
                sep(),
                item("Cut", "cut", "⌘X", false),
                item("Copy", "copy", "⌘C", false),
                item("Paste", "paste", "⌘V", false),
                item("Delete", "delete", "", false),
                item("Select All", "selectAll", "⌘A", false),
                sep(),
                item("Find", "find", "⌘F", false),
                item("Spelling and Grammar", "spelling", "", false),
                item("Emoji & Symbols", "emoji", "⌃⌘Space", false)
            ];
        }
        if (kind === "format") {
            return [
                item("Font", "font", "", false),
                item("Text", "textFormat", "", false),
                item("Make Upper Case", "upper", "", false),
                item("Make Lower Case", "lower", "", false)
            ];
        }
        if (kind === "view") {
            return [
                item("Show Toolbar", "toolbar", "", false),
                item("Show Sidebar", "sidebar", "", false),
                sep(),
                item("Enter Full Screen", "fullscreen", "⌃⌘F"),
                item("Toggle Floating", "float", ""),
                item("Center Window", "center", "")
            ];
        }
        if (kind === "window") {
            return [
                item("Minimize", "minimize", "⌘M", false),
                item("Zoom", "float", ""),
                sep(),
                item("Close", "close", "⌘W"),
                item("Full Screen", "fullscreen", "⌃⌘F"),
                item("Center", "center", "")
            ];
        }
        if (kind === "help") {
            return [
                item("Search", "spotlight", "⌘Space"),
                item("mos Topbar Help", "help", "", false),
                sep(),
                item("About This Desktop", "about", "", false)
            ];
        }
        if (kind === "wifi") {
            return [
                item("Wi-Fi: " + (root.wifiOn ? "On" : "Off"), "wifi"),
                sep(),
                item("Wi-Fi Settings…", "settings")
            ];
        }
        if (kind === "bluetooth") {
            return [
                item("Bluetooth: " + (root.btOn ? "On" : "Off"), "bt"),
                sep(),
                item("Bluetooth Settings…", "settings")
            ];
        }
        if (kind === "battery") {
            return [
                item(root.batPct < 0 ? "Power Adapter" : "Battery: " + root.batPct + "%", "", "", false),
                sep(),
                item("Battery Settings…", "settings")
            ];
        }
        return [];
    }

    function openMenu(kind, centerX, screen, alignRight) {
        if (root.menuOpen && root.menuKind === kind && root.menuScreen === screen) {
            root.closeMenu();
            return;
        }
        root.menuKind = kind;
        root.menuScreen = screen;
        root.menuAnchorX = centerX;
        root.menuAlignRight = !!alignRight;
        root.menuItems = root.menuItemsFor(kind);
        if (kind === "clock") {
            root.calOffset = 0;
            root.updateCalendar();
        }
        if (kind === "control") root.refreshControl();
    }

    // ── actions ────────────────────────────────────────────────────────────
    function exec(cmd) {
        if (cmd !== "") Quickshell.execDetached(["bash", "-lc", cmd]);
    }

    function run(action) {
        root.closeMenu();
        if (action === "settings") return root.exec("~/.config/hypr/scripts/qs_manager.sh toggle settings");
        if (action === "spotlight") return root.exec("~/.config/hypr/scripts/qs_manager.sh toggle launcher");
        if (action === "close" || action === "quit") return root.exec("hyprctl dispatch 'hl.dsp.window.close()'");
        if (action === "fullscreen") return root.exec("hyprctl dispatch 'hl.dsp.window.fullscreen()'");
        if (action === "float") return root.exec("hyprctl dispatch 'hl.dsp.window.float()'");
        if (action === "center") return root.exec("hyprctl dispatch 'hl.dsp.window.center()'");
        if (action === "lock") return root.exec("loginctl lock-session");
        if (action === "sleep") return root.exec("systemctl suspend");
        if (action === "logout") return root.exec("hyprctl dispatch 'hl.dsp.exit()'");
        if (action === "wifi") return root.toggleWifi();
        if (action === "bt") return root.toggleBt();
    }

    function setVolume(v) {
        root.volume = Math.round(v);
        root.exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (root.volume / 100).toFixed(2));
    }
    function setBrightness(v) {
        root.brightness = Math.round(v);
        root.exec("brightnessctl set " + root.brightness + "%");
    }

    // ── calendar ───────────────────────────────────────────────────────────
    property int calOffset: 0
    property var calDays: []
    property string calMonthLabel: ""
    readonly property var calWeekdays: ["S", "M", "T", "W", "T", "F", "S"]
    readonly property string calTodayLabel: Qt.formatDate(new Date(), "dd MMM yyyy").toUpperCase()

    function updateCalendar() {
        let now = new Date();
        let base = new Date(now.getFullYear(), now.getMonth() + root.calOffset, 1);
        let y = base.getFullYear(); let m = base.getMonth();
        let first = new Date(y, m, 1).getDay();
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

    onCalOffsetChanged: updateCalendar()

    // ── components ─────────────────────────────────────────────────────────
    component BarMenu: Item {
        id: button
        property string label: ""
        property string icon: ""
        property bool bold: false
        signal activated(real centerX)
        width: icon !== "" ? 26 : Math.max(26, textItem.implicitWidth + 16)
        height: root.barH
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 5
            color: mouse.containsMouse ? root.hoverColor : "transparent"
        }
        Text {
            id: textItem
            anchors.centerIn: parent
            text: button.icon !== "" ? button.icon : button.label
            font.family: button.icon !== "" ? root.iconFont : root.uiFont
            font.pixelSize: button.icon !== "" ? 14 : 12
            font.weight: button.bold ? Font.DemiBold : Font.Normal
            color: root.textColor
        }
        MouseArea {
            id: mouse; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.activated(button.mapToItem(null, button.width / 2, 0).x)
        }
    }

    component StatusItem: Item {
        id: status
        property string icon: ""
        property string label: ""
        signal activated(real centerX)
        width: Math.max(20, statusText.implicitWidth + (status.icon !== "" ? 20 : 12))
        height: root.barH
        Rectangle {
            anchors.fill: parent; anchors.margins: 1; radius: 5
            color: smouse.containsMouse ? root.hoverColor : "transparent"
        }
        Row {
            anchors.centerIn: parent
            spacing: 4
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: status.icon; visible: text !== ""
                font.family: root.iconFont; font.pixelSize: 14; color: root.textColor
            }
            Text {
                id: statusText
                anchors.verticalCenter: parent.verticalCenter
                text: status.label; visible: text !== ""
                font.family: root.uiFont; font.pixelSize: 11; color: root.textColor
            }
        }
        MouseArea {
            id: smouse; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: status.activated(status.mapToItem(null, status.width / 2, 0).x)
        }
    }

    component MenuRow: Item {
        id: row
        property var item: ({})
        width: parent ? parent.width : 0
        height: item && item.separator ? 9 : 24
        Rectangle {
            visible: !(row.item && row.item.separator)
            anchors.fill: parent
            anchors.leftMargin: 3; anchors.rightMargin: 3
            radius: 5
            color: mrow.containsMouse && row.item && row.item.enabled !== false ? root.hoverColor : "transparent"
        }
        Rectangle {
            visible: !!(row.item && row.item.separator)
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 10; anchors.rightMargin: 10
            height: 1; color: Qt.rgba(1, 1, 1, 0.12)
        }
        Text {
            visible: !(row.item && row.item.separator)
            anchors.left: parent.left; anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: row.item ? String(row.item.label || "") : ""
            font.family: root.uiFont; font.pixelSize: 12
            color: row.item && row.item.enabled === false ? root.dimColor : root.textColor
        }
        Text {
            visible: !(row.item && row.item.separator) && row.item && row.item.shortcut !== ""
            anchors.right: parent.right; anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: row.item ? String(row.item.shortcut || "") : ""
            font.family: root.uiFont; font.pixelSize: 11
            color: root.dimColor
        }
        MouseArea {
            id: mrow
            anchors.fill: parent
            hoverEnabled: true
            enabled: !!(row.item && !row.item.separator && row.item.enabled !== false)
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (row.item && row.item.action) root.run(row.item.action)
        }
    }

    component ToggleTile: Rectangle {
        id: tile
        property string icon: ""
        property string label: ""
        property bool active: false
        signal toggled()
        width: 128; height: 52; radius: 10
        color: tile.active ? Qt.rgba(0.04, 0.52, 1, 0.88) : Qt.rgba(1, 1, 1, 0.09)
        border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.12)
        Column {
            anchors.left: parent.left; anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text { text: tile.icon; font.family: root.iconFont; font.pixelSize: 15; color: "#ffffff" }
            Text { text: tile.label; font.family: root.uiFont; font.pixelSize: 10; color: "#ffffff" }
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: tile.active ? "On" : "Off"
            font.family: root.uiFont; font.pixelSize: 10
            color: Qt.rgba(1, 1, 1, 0.72)
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tile.toggled() }
    }

    // ── menu bar ───────────────────────────────────────────────────────────
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: barWindow
                required property var modelData
                screen: modelData
                anchors.top: true; anchors.left: true; anchors.right: true
                implicitHeight: root.barH
                exclusiveZone: root.barH
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "equisdots-mos-topbar"

                Rectangle { anchors.fill: parent; color: root.barColor }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.itemSpacing

                    BarMenu { icon: ""; onActivated: (x) => root.openMenu("apple", x, barWindow.screen, false) }
                    BarMenu {
                        visible: root.cfg.showAppName !== false
                        label: root.activeApp; bold: true
                        onActivated: (x) => root.openMenu("app", x, barWindow.screen, false)
                    }
                    BarMenu { visible: root.cfg.showAppMenus !== false; label: "File"; onActivated: (x) => root.openMenu("file", x, barWindow.screen, false) }
                    BarMenu { visible: root.cfg.showAppMenus !== false; label: "Edit"; onActivated: (x) => root.openMenu("edit", x, barWindow.screen, false) }
                    BarMenu { visible: root.cfg.showAppMenus !== false; label: "Format"; onActivated: (x) => root.openMenu("format", x, barWindow.screen, false) }
                    BarMenu { visible: root.cfg.showAppMenus !== false; label: "View"; onActivated: (x) => root.openMenu("view", x, barWindow.screen, false) }
                    BarMenu { visible: root.cfg.showAppMenus !== false; label: "Window"; onActivated: (x) => root.openMenu("window", x, barWindow.screen, false) }
                    BarMenu { visible: root.cfg.showAppMenus !== false; label: "Help"; onActivated: (x) => root.openMenu("help", x, barWindow.screen, false) }
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.itemSpacing

                    StatusItem {
                        visible: root.cfg.showBluetooth !== false
                        icon: "󰂯"
                        onActivated: (x) => root.openMenu("bluetooth", x, barWindow.screen, true)
                    }
                    StatusItem {
                        visible: root.cfg.showWifi !== false
                        icon: root.wifiOn ? "󰖩" : "󰖪"
                        onActivated: (x) => root.openMenu("wifi", x, barWindow.screen, true)
                    }
                    StatusItem {
                        visible: root.cfg.showBattery !== false
                        icon: root.batPct < 0 ? "󰂄" : (root.batPct > 80 ? "󰁹" : root.batPct > 40 ? "󰁾" : "󰁻")
                        label: root.cfg.showBatteryPercent ? (root.batPct < 0 ? "AC" : root.batPct + "%") : ""
                        onActivated: (x) => root.openMenu("battery", x, barWindow.screen, true)
                    }
                    StatusItem {
                        visible: root.cfg.showControlCenter !== false
                        icon: "󰒓"
                        onActivated: (x) => root.openMenu("control", x, barWindow.screen, true)
                    }
                    StatusItem {
                        visible: root.cfg.showSpotlight !== false
                        icon: "󰍉"
                        onActivated: (x) => root.run("spotlight")
                    }
                    StatusItem {
                        visible: root.cfg.showClock !== false
                        label: root.dateText + "  " + root.clockText
                        onActivated: (x) => root.openMenu("clock", x, barWindow.screen, true)
                    }
                }
            }
        }
    }

    // ── popovers ───────────────────────────────────────────────────────────
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: popupWindow
                required property var modelData
                screen: modelData
                visible: root.menuOpen && root.menuScreen === modelData
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                implicitWidth: modelData ? modelData.width : 1920
                implicitHeight: modelData ? modelData.height : 1080
                anchors.top: true; anchors.bottom: true; anchors.left: true; anchors.right: true
                focusable: true
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "equisdots-mos-topbar-menu"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    focus: true
                    onClicked: root.closeMenu()
                    Keys.onEscapePressed: root.closeMenu()
                }

                // Generic menu card.
                Rectangle {
                    id: menuCard
                    visible: root.menuOpen && root.menuKind !== "control" && root.menuKind !== "clock"
                    width: 236
                    height: menuCol.implicitHeight + 10
                    x: root.menuAlignRight
                        ? Math.max(8, modelData.width - width - 10)
                        : Math.max(8, Math.min(root.menuAnchorX - width / 2, modelData.width - width - 8))
                    y: root.barH + 2
                    color: root.menuColor
                    border.width: 1; border.color: root.menuBorder
                    radius: 10
                    opacity: visible ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: {} }
                    Column {
                        id: menuCol
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 0
                        Repeater {
                            model: root.menuItems
                            MenuRow { item: modelData }
                        }
                    }
                }

                // Control Center.
                Rectangle {
                    id: controlCard
                    visible: root.menuKind === "control"
                    width: 300
                    height: controlCol.implicitHeight + 24
                    x: Math.max(8, modelData.width - width - 10)
                    y: root.barH + 2
                    color: root.menuColor
                    border.width: 1; border.color: root.menuBorder
                    radius: 14
                    opacity: visible ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: {} }
                    Column {
                        id: controlCol
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 9
                        Text {
                            text: "CONTROL CENTER"
                            font.family: root.uiFont; font.pixelSize: 9
                            font.letterSpacing: 1.2; color: root.dimColor
                        }
                        Row {
                            spacing: 8
                            ToggleTile {
                                icon: root.wifiOn ? "󰖩" : "󰖪"; label: "Wi-Fi"; active: root.wifiOn
                                onToggled: root.toggleWifi()
                            }
                            ToggleTile {
                                icon: "󰂯"; label: "Bluetooth"; active: root.btOn
                                onToggled: root.toggleBt()
                            }
                        }
                        Text { text: "DISPLAY"; font.family: root.uiFont; font.pixelSize: 9; font.letterSpacing: 1.2; color: root.dimColor }
                        Slider {
                            id: brightSlider
                            width: parent.width
                            from: 0; to: 100; stepSize: 1
                            value: root.brightness
                            onMoved: root.setBrightness(value)
                        }
                        Text { text: "SOUND"; font.family: root.uiFont; font.pixelSize: 9; font.letterSpacing: 1.2; color: root.dimColor }
                        Slider {
                            id: volSlider
                            width: parent.width
                            from: 0; to: 100; stepSize: 1
                            value: root.volume
                            onMoved: root.setVolume(value)
                        }
                    }
                }

                // Clock / calendar.
                Rectangle {
                    id: clockCard
                    visible: root.menuKind === "clock"
                    width: 286
                    height: clockCol.implicitHeight + 24
                    x: Math.max(8, modelData.width - width - 10)
                    y: root.barH + 2
                    color: root.menuColor
                    border.width: 1; border.color: root.menuBorder
                    radius: 14
                    opacity: visible ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: {} }
                    Column {
                        id: clockCol
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 5
                        Row {
                            width: parent.width
                            Text {
                                text: root.calMonthLabel
                                font.family: root.uiFont; font.pixelSize: 13; font.weight: Font.DemiBold
                                color: root.textColor
                            }
                            Item { width: parent.width - 68; height: 1 }
                            Text {
                                text: "‹"; font.family: root.uiFont; font.pixelSize: 18; color: root.dimColor
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.calOffset-- }
                            }
                            Text {
                                text: "›"; font.family: root.uiFont; font.pixelSize: 18; color: root.dimColor
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.calOffset++ }
                            }
                        }
                        Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.12) }
                        Row {
                            width: parent.width
                            Repeater {
                                model: root.calWeekdays
                                Text {
                                    width: parent.width / 7; height: 20
                                    text: modelData; horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.family: root.uiFont; font.pixelSize: 9; color: root.dimColor
                                }
                            }
                        }
                        Grid {
                            id: calGrid
                            columns: 7; width: parent.width
                            height: Math.ceil(root.calDays.length / 7) * 30
                            Repeater {
                                model: root.calDays
                                Rectangle {
                                    width: calGrid.width / 7; height: 30
                                    color: modelData.today ? root.accent : "transparent"
                                    radius: 4
                                    Text {
                                        anchors.centerIn: parent; text: modelData.day
                                        font.family: root.uiFont; font.pixelSize: 11
                                        font.weight: modelData.today ? Font.DemiBold : Font.Normal
                                        color: modelData.today ? "#ffffff" : (modelData.inMonth ? root.textColor : root.dimColor)
                                    }
                                }
                            }
                        }
                        Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.12) }
                        Text {
                            text: "TODAY  ·  " + root.calTodayLabel
                            font.family: root.uiFont; font.pixelSize: 9; color: root.dimColor
                        }
                    }
                }
            }
        }
    }
}
