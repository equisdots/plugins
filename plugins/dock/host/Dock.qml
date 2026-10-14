import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// ═══════════════════════════════════════════════════════════════════════════
// Dock — the Dock plugin's host adapter (equisdots plugin standard).
//
// Mounted generically by ui/PluginHosts.qml. Inside the shell tree it imports
// the core kit: the live palette (Colors) and the settings singleton (Config).
// One full-surface transparent overlay per screen whose input region is
// limited to the dock panel (mask); the panel floats inside, positioned with
// explicit x/y (a child item's anchors that resolve to undefined do not
// reliably detach, so numbers are used). A Quickshell PanelWindow's own
// anchors also do not re-apply reliably, which is why the surface is full-
// screen and only the panel moves. Everything is recomputed deterministically
// in syncCfg() on every Config mutation (derived readonly bindings do not
// propagate reliably to dependents here).
//
// Settings: settings.json → "dock". Master switch: `dock.enabled`.
// Right-click: context menu (Open / Remove from dock / Dock settings).
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    visible: false
    width: 0
    height: 0

    // Injected by ui/PluginHosts.qml (post-load; may briefly be null).
    property var host: null

    // Fallback palette so bindings never dereference null before `host` is set.
    readonly property var _fb: ({
        base: "#1e1e2e", mantle: "#181825", crust: "#11111b",
        text: "#cdd6f4", subtext0: "#a6adc8", subtext1: "#bac2de",
        surface0: "#313244", surface1: "#45475a", surface2: "#585b70",
        overlay0: "#6c7086", overlay1: "#7f849c", overlay2: "#9399b2",
        blue: "#89b4fa", green: "#a6e3a1", yellow: "#f9e2af",
        red: "#f38ba8", mauve: "#cba6f7", teal: "#94e2d5", peach: "#fab387",
        pink: "#f5c2e7", maroon: "#eba0ac", sapphire: "#74c7ec", sky: "#89dceb"
    })
    readonly property var c: (host && host.colors) ? host.colors : _fb

    function num(v, d) { return (typeof v === "number" && isFinite(v)) ? v : d; }
    function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }

    // ── plain (non-derived) state, set by syncCfg ──────────────────────────
    property var cfg: ({})
    property string position: "bottom"
    property bool vertical: false
    property real iconSize: 44
    property real spacing: 10
    property real padding: 10
    property real margin: 8
    property real radius: 20
    property bool reserve: false
    property real panelOpacity: 0.85
    property bool showLabels: false
    property bool magnify: true
    property real magnifyScale: 1.35
    property bool borderOn: true
    property bool customBg: false
    property string colorSpec: "surface0"
    property string borderSpec: "surface1"
    property var apps: []

    function syncCfg() {
        let d = (host && host.settings) ? host.settings.all() : {};
        cfg = d;
        let p = String(d.position || "bottom");
        if (["top", "bottom", "left", "right"].indexOf(p) < 0) p = "bottom";
        position = p;
        vertical = (p === "left" || p === "right");
        iconSize = clamp(num(d.iconSize, 44), 16, 96);
        spacing = clamp(num(d.spacing, 10), 2, 40);
        padding = clamp(num(d.padding, 10), 4, 40);
        margin = clamp(num(d.margin, 8), 0, 80);
        radius = clamp(num(d.radius, 20), 0, 60);
        reserve = d.reserve === true;
        panelOpacity = clamp(num(d.opacity, 0.85), 0.15, 1.0);
        showLabels = d.showLabels === true;
        magnify = d.magnify !== false;
        magnifyScale = clamp(num(d.magnifyScale, 1.35), 1, 1.8);
        borderOn = d.border !== false;
        customBg = d.background === "custom";
        colorSpec = (typeof d.color === "string" && d.color !== "") ? d.color : "surface0";
        borderSpec = (typeof d.borderColor === "string" && d.borderColor !== "") ? d.borderColor : "surface1";
        apps = Array.isArray(d.apps) ? d.apps : [];
    }
    Component.onCompleted: syncCfg()
    Connections {
        target: root
        function onHostChanged() { root.syncCfg(); }
    }
    Connections {
        // SettingsScope.changed fires AFTER the commit (state-before-notify),
        // so no Qt.callLater workaround is needed.
        target: root.host ? root.host.settings : null
        function onChanged() { root.syncCfg(); }
        function onKeyChanged() { root.syncCfg(); }
    }

    // ── palette (bindings on theme; refresh when the palette changes) ──────
    function resolveColor(spec, fallbackRole) {
        if (typeof spec === "string" && spec.length > 0) {
            if (spec.charAt(0) === "#") return spec;
            if (c[spec] !== undefined) return c[spec];
        }
        return (c[fallbackRole] !== undefined) ? c[fallbackRole] : "#1e1e2e";
    }
    function withAlpha(c, a) {
        let col = Qt.color(c);
        return Qt.rgba(col.r, col.g, col.b, a);
    }
    readonly property color panelColor: withAlpha(
        customBg ? resolveColor(colorSpec, "surface0") : ((c.surface0 !== undefined) ? c.surface0 : "#1e1e2e"),
        panelOpacity)
    readonly property color borderColor: borderOn
        ? withAlpha(resolveColor(borderSpec, "surface1"), Math.min(1.0, panelOpacity + 0.2))
        : "transparent"

    // ── geometry ───────────────────────────────────────────────────────────
    readonly property real thickness: iconSize + padding * 2
    readonly property real surfaceThickness: thickness + margin * 2

    function iconSource(app) {
        if (!app) return "";
        let ic = String(app.icon || "").trim();
        if (ic === "") ic = String(app.id || "").trim();
        if (ic === "") return "";
        if (ic.charAt(0) === "/") return "file://" + ic;
        return "image://icon/" + ic;
    }
    function launch(app) {
        let cmd = String((app && app.exec) || "").trim();
        if (cmd === "") return;
        Quickshell.execDetached(["bash", "-lc", cmd]);
    }

    // ── context menu ───────────────────────────────────────────────────────
    property var menuScreen: null
    property var menuApp: null
    property bool menuOpen: false
    property real cursorX: 0
    property real cursorY: 0

    readonly property int menuW: 220
    readonly property int menuRowH: 34
    readonly property int menuPad: 6
    readonly property int menuHeaderH: 40

    function menuItems() {
        let items = [];
        if (root.menuApp) {
            items.push({ glyph: "▶", label: "Open", action: "open" });
            items.push({ glyph: "✕", label: "Remove from dock", action: "remove" });
        }
        items.push({ glyph: "󰒓", label: "Dock settings", action: "settings" });
        return items;
    }
    function menuHeight() {
        return root.menuPad * 2 + root.menuItems().length * root.menuRowH + (root.menuApp ? root.menuHeaderH : 0);
    }

    Process {
        id: cursorProc
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { let p = JSON.parse(this.text); root.cursorX = p.x; root.cursorY = p.y; }
                catch (e) { root.cursorX = 0; root.cursorY = 0; }
                root.menuOpen = true;
            }
        }
    }
    function openContextMenu(screen, app) {
        if (!screen) return;
        root.menuScreen = screen;
        root.menuApp = app || null;
        root.menuOpen = false;
        cursorProc.running = false;
        cursorProc.running = true;
    }
    function closeMenu() { root.menuOpen = false; root.menuApp = null; }

    function openSettings() {
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "open", "bar-editor", "dock"]);
    }
    function removeFromDock(app) {
        let section = (root.host && root.host.settings) ? root.host.settings.section : {};
        let list = Array.isArray(section.apps) ? section.apps : [];
        let key = String((app && (app.id || app.exec)) || "");
        let next = [];
        for (let i = 0; i < list.length; i++) {
            let k = String((list[i] && (list[i].id || list[i].exec)) || "");
            if (k !== key) next.push(list[i]);
        }
        if (root.host && root.host.settings) root.host.settings.set("apps", next);
    }
    function runMenuAction(action) {
        let app = root.menuApp;
        root.closeMenu();
        if (action === "open" && app) root.launch(app);
        else if (action === "remove" && app) root.removeFromDock(app);
        else if (action === "settings") root.openSettings();
    }

    // ── dock surfaces: one full-screen overlay + panel per screen ──────────
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: win
                required property var modelData
                screen: modelData

                visible: true
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                implicitWidth: win.screen ? win.screen.width : 1920
                implicitHeight: win.screen ? win.screen.height : 1080
                anchors.left: true
                anchors.right: true
                anchors.top: true
                anchors.bottom: true
                WlrLayershell.namespace: "equisdots-dock"

                // Input only over the panel; everything else is click-through.
                mask: Region { item: panel }

                Rectangle {
                    id: panel
                    // Explicit x/y from the screen size (numbers, not anchors).
                    x: {
                        let sw = win.screen ? win.screen.width : 1920;
                        if (root.position === "left") return root.margin;
                        if (root.position === "right") return Math.round(sw - root.margin - width);
                        return Math.round((sw - width) / 2);
                    }
                    y: {
                        let sh = win.screen ? win.screen.height : 1080;
                        if (root.position === "top") return root.margin;
                        if (root.position === "bottom") return Math.round(sh - root.margin - height);
                        return Math.round((sh - height) / 2);
                    }

                    width: root.vertical ? root.thickness : (icons.implicitWidth + root.padding * 2)
                    height: root.vertical ? (icons.implicitHeight + root.padding * 2) : root.thickness
                    radius: root.radius
                    color: root.panelColor
                    border.width: root.borderOn ? 1 : 0
                    border.color: root.borderColor

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onClicked: root.openContextMenu(win.screen, null)
                    }

                    Grid {
                        id: icons
                        anchors.centerIn: parent
                        columns: root.vertical ? 1 : Math.max(1, root.apps.length)
                        rowSpacing: root.spacing
                        columnSpacing: root.spacing

                        Repeater {
                            model: root.apps
                            delegate: Item {
                                id: cell
                                required property var modelData
                                required property int index

                                readonly property real labelW: root.showLabels
                                    ? Math.min(label.implicitWidth, root.iconSize * 2.4) : 0
                                width: Math.max(root.iconSize, labelW)
                                height: root.iconSize + (root.showLabels ? label.implicitHeight + 4 : 0)

                                Rectangle {
                                    id: chip
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    width: root.iconSize
                                    height: root.iconSize
                                    radius: Math.round(root.iconSize * 0.28)
                                    color: ma.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Image {
                                        anchors.centerIn: parent
                                        width: Math.round(root.iconSize * 0.62)
                                        height: width
                                        source: root.iconSource(cell.modelData)
                                        sourceSize: Qt.size(root.iconSize, root.iconSize)
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        asynchronous: true
                                    }
                                }

                                Text {
                                    id: label
                                    visible: root.showLabels
                                    anchors.top: chip.bottom
                                    anchors.topMargin: 2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: cell.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: String((cell.modelData && cell.modelData.label) || "")
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: Math.max(9, Math.round(root.iconSize * 0.22))
                                    color: c.text
                                    maximumLineCount: 1
                                    elide: Text.ElideRight
                                }

                                scale: (root.magnify && ma.containsMouse) ? root.magnifyScale : 1.0
                                z: ma.containsMouse ? 1 : 0
                                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

                                MouseArea {
                                    id: ma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton)
                                            root.openContextMenu(win.screen, cell.modelData);
                                        else
                                            root.launch(cell.modelData);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── reservation strips: reserve the dock's edge for windows ────────────
    // The dock is a full-screen overlay (so its edge can change without
    // re-anchoring a surface); reserving space needs an edge-anchored surface
    // with exclusiveZone, so one static strip per edge is declared and only
    // the active one is mapped. No content, empty input region (click-through).
    // NOTE: do not set exclusionMode explicitly — exclusiveZone already
    // implies Normal, and an explicit exclusionMode:Normal suppressed the
    // reservation here.
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData
                visible: root.reserve && root.position === "bottom" && root.apps.length > 0
                color: "transparent"
                exclusiveZone: root.surfaceThickness
                implicitWidth: modelData ? modelData.width : 1920
                implicitHeight: root.surfaceThickness
                anchors.left: true
                anchors.right: true
                anchors.bottom: true
                WlrLayershell.namespace: "equisdots-dock-reserve"
                mask: Region { }
            }
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData
                visible: root.reserve && root.position === "top" && root.apps.length > 0
                color: "transparent"
                exclusiveZone: root.surfaceThickness
                implicitWidth: modelData ? modelData.width : 1920
                implicitHeight: root.surfaceThickness
                anchors.left: true
                anchors.right: true
                anchors.top: true
                WlrLayershell.namespace: "equisdots-dock-reserve"
                mask: Region { }
            }
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData
                visible: root.reserve && root.position === "left" && root.apps.length > 0
                color: "transparent"
                exclusiveZone: root.surfaceThickness
                implicitWidth: root.surfaceThickness
                implicitHeight: modelData ? modelData.height : 1080
                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                WlrLayershell.namespace: "equisdots-dock-reserve"
                mask: Region { }
            }
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData
                visible: root.reserve && root.position === "right" && root.apps.length > 0
                color: "transparent"
                exclusiveZone: root.surfaceThickness
                implicitWidth: root.surfaceThickness
                implicitHeight: modelData ? modelData.height : 1080
                anchors.top: true
                anchors.bottom: true
                anchors.right: true
                WlrLayershell.namespace: "equisdots-dock-reserve"
                mask: Region { }
            }
        }
    }

    // ── menu overlays (overlay layer, full screen, per screen) ─────────────
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: menuWin
                required property var modelData
                screen: modelData

                visible: root.menuOpen && root.menuScreen === modelData
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                implicitWidth: modelData ? modelData.width : 1920
                implicitHeight: modelData ? modelData.height : 1080
                anchors.left: true
                anchors.right: true
                anchors.top: true
                anchors.bottom: true
                focusable: true
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "equisdots-dock-menu"

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    focus: true
                    onClicked: root.closeMenu()
                    Keys.onEscapePressed: root.closeMenu()
                }

                Rectangle {
                    id: menu
                    x: {
                        let sw = modelData ? modelData.width : 1920;
                        let lx = root.cursorX - (modelData ? modelData.x : 0) + 8;
                        return Math.max(8, Math.min(lx, sw - root.menuW - 8));
                    }
                    y: {
                        let sh = modelData ? modelData.height : 1080;
                        let ly = root.cursorY - (modelData ? modelData.y : 0);
                        let h = root.menuHeight();
                        let above = ly - h - 8;
                        let yy = (above >= 8) ? above : (ly + 8);
                        return Math.max(8, Math.min(yy, sh - h - 8));
                    }
                    width: root.menuW
                    height: root.menuHeight()
                    radius: Math.min(18, Math.max(8, root.radius))
                    color: root.panelColor
                    border.width: root.borderOn ? 1 : 0
                    border.color: root.borderColor

                    Column {
                        id: menuCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: root.menuPad
                        spacing: 0

                        Item {
                            x: 8
                            width: menuCol.width - 16
                            height: root.menuApp ? root.menuHeaderH : 0
                            visible: root.menuApp ? true : false
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                text: String((root.menuApp && (root.menuApp.label || root.menuApp.id)) || "")
                                font.family: "Hack Nerd Font"
                                font.weight: Font.Bold
                                font.pixelSize: 12
                                color: c.text
                                elide: Text.ElideRight
                            }
                        }

                        Repeater {
                            model: root.menuItems()
                            delegate: Rectangle {
                                required property var modelData
                                width: menuCol.width
                                height: root.menuRowH
                                radius: Math.min(10, Math.max(4, root.radius - 6))
                                color: rowMa.containsMouse ? Qt.alpha(c.mauve, 0.16) : "transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 18
                                        text: modelData.glyph
                                        font.family: "Hack Nerd Font"
                                        font.pixelSize: 13
                                        color: c.mauve
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label
                                        font.family: "Hack Nerd Font"
                                        font.pixelSize: 12
                                        color: c.text
                                    }
                                }
                                MouseArea {
                                    id: rowMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.runMenuAction(modelData.action)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
