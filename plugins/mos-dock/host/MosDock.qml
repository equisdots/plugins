import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.core

// ═══════════════════════════════════════════════════════════════════════════
// mos Dock — macOS Golden Gate / Liquid Glass inspired bottom dock.
//
// The visual language follows the current Apple dock: a floating rounded glass
// capsule with a bright rim and soft shadow, full-bleed squircle app icons,
// hover magnification (the hovered icon and its neighbours), hover labels,
// running-app dots, a launch bounce, a separator and Downloads/Trash at the
// right. It is deliberately neutral: colour comes from the app icons, not the
// equisdots palette.
//
// Data stays local to the plugin: apps are configured in the plugin settings;
// icon names resolve through Quickshell.iconPath with a glyph fallback. The
// running state is a low-frequency hyprctl class poll (the dock is a plugin,
// not part of the core shell).
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    visible: true
    width: 0
    height: 0

    property var host: null

    readonly property var cfg: {
        let s = host && host.settings;
        if (!s) return ({});
        s.revision;
        return s.all();
    }

    function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }

    readonly property var defaultApps: ([
        { label: "Finder",   icon: "org.gnome.Nautilus", glyph: "󰉋", exec: "nautilus", match: ["nautilus", "org.gnome.Nautilus"] },
        { label: "Safari",   icon: "brave-browser",      glyph: "󰖟", exec: "brave",    match: ["brave", "brave-browser"] },
        { label: "Mail",     icon: "thunderbird",        glyph: "󰇮", exec: "thunderbird", match: ["thunderbird"] },
        { label: "Music",    icon: "spotify",            glyph: "󰝚", exec: "spotify",  match: ["spotify"] },
        { label: "Terminal", icon: "kitty",              glyph: "󰆍", exec: "kitty",    match: ["kitty"] },
        { label: "Settings", icon: "preferences-system", glyph: "󰒓", exec: "~/.config/hypr/scripts/qs_manager.sh toggle settings", match: [] }
    ])

    readonly property var apps: {
        let a = cfg.apps;
        return (Array.isArray(a) && a.length > 0) ? a : defaultApps;
    }

    readonly property int iconSize: clamp(Number(cfg.iconSize) || 48, 28, 96)
    readonly property int spacing: clamp(Number(cfg.spacing) || 8, 0, 30)
    readonly property bool showLabels: cfg.showLabels === true
    readonly property bool magnify: cfg.magnify !== false
    readonly property real magnifyScale: clamp(Number(cfg.magnifyScale) || 1.22, 1.0, 1.8)
    readonly property real panelOpacity: clamp(Number(cfg.opacity) || 0.72, 0.15, 1.0)
    readonly property bool glass: cfg.glass !== false
    readonly property bool showIndicators: cfg.showIndicators !== false
    readonly property bool bounce: cfg.bounce !== false
    readonly property bool showDownloads: cfg.showDownloads !== false
    readonly property bool showTrash: cfg.showTrash !== false

    readonly property int sidePad: Math.max(8, Math.round(iconSize * 0.22))
    readonly property int bottomMargin: Math.max(6, Math.round(iconSize * 0.16))
    readonly property int dockHeight: iconSize + (showLabels ? 38 : 20)
    readonly property int panelRadius: Math.max(14, Math.round(dockHeight * 0.32))
    readonly property int iconRadius: Math.max(8, Math.round(iconSize * 0.225))
    readonly property int separatorWidth: Math.max(7, Math.round(iconSize * 0.18))
    readonly property int iconBottomMargin: showLabels ? Math.round(iconSize * 0.32) + 6
                                                        : Math.max(7, Math.round(iconSize * 0.16))

    readonly property var fixedItems: {
        let out = [];
        if (root.showDownloads) {
            out.push({
                label: "Downloads", icon: "folder-download", glyph: "󰉍",
                exec: "xdg-open \"$HOME/Downloads\"", match: [], kind: "downloads"
            });
        }
        if (root.showTrash) {
            out.push({
                label: "Trash", icon: "user-trash", glyph: "󰩹",
                exec: "xdg-open trash:///", match: [], kind: "trash"
            });
        }
        return out;
    }

    readonly property var dockItems: {
        let out = (root.apps || []).slice();
        if (root.fixedItems.length > 0) {
            out.push({ kind: "separator" });
            out = out.concat(root.fixedItems);
        }
        return out;
    }

    property var runningClasses: []
    property var iconPaths: ({})

    readonly property var iconNames: {
        let out = [];
        let list = root.apps || [];
        for (let i = 0; i < list.length; i++) {
            let n = String((list[i] && list[i].icon) || "");
            if (n !== "") out.push(n);
        }
        for (let i = 0; i < root.fixedItems.length; i++) {
            let n = String(root.fixedItems[i].icon || "");
            if (n !== "") out.push(n);
        }
        return out;
    }

    function iconSource(app) {
        let name = String((app && app.icon) || "");
        if (name === "") return "";
        if (name.charAt(0) === "/") return "file://" + name;
        let mapped = root.iconPaths ? root.iconPaths[name] : "";
        if (mapped) return "file://" + mapped;
        let path = Quickshell.iconPath(name, true);
        if (!path) return "";
        return path.indexOf("://") !== -1 ? path : "file://" + path;
    }

    function appRunning(app) {
        if (!root.showIndicators || !app) return false;
        let list = app.match;
        if (!Array.isArray(list)) list = list ? [String(list)] : [];
        if (list.length === 0) {
            let exe = String(app.exec || "").split("/").pop().split(" ")[0];
            if (exe !== "") list = [exe];
        }
        for (let i = 0; i < list.length; i++) {
            let needle = String(list[i]).toLowerCase();
            if (needle === "") continue;
            for (let j = 0; j < root.runningClasses.length; j++) {
                let cls = String(root.runningClasses[j]).toLowerCase();
                if (cls === needle || cls.indexOf(needle) !== -1 || needle.indexOf(cls) !== -1)
                    return true;
            }
        }
        return false;
    }

    function launch(app) {
        let cmd = String((app && (app.exec || app.command)) || "").trim();
        if (cmd === "") return;
        Quickshell.execDetached(["bash", "-lc", cmd]);
    }

    // Running-app state: a quiet class poll while the plugin is mounted.
    Timer {
        interval: 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!clientsProc.running) clientsProc.running = true
    }

    Process {
        id: clientsProc
        running: false
        command: ["bash", "-c", "hyprctl clients -j 2>/dev/null | jq -r '.[].class' 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = String(this.text || "").trim();
                root.runningClasses = out === "" ? [] : out.split("\n").filter(x => x.trim() !== "");
            }
        }
    }

    Timer {
        id: iconRefresh
        interval: 200
        repeat: false
        onTriggered: if (!iconProc.running) iconProc.running = true
    }

    Component.onCompleted: iconRefresh.start()
    onIconNamesChanged: iconRefresh.restart()

    Process {
        id: iconProc
        running: false
        command: ["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/ui/plugins/mos-dock/scripts/resolve-icons.sh"]
            .concat(root.iconNames)
        stdout: StdioCollector {
            onStreamFinished: {
                let map = {};
                let text = String(this.text || "").trim();
                if (text !== "") {
                    let lines = text.split("\n");
                    for (let i = 0; i < lines.length; i++) {
                        let parts = lines[i].split("\t");
                        if (parts.length >= 2 && parts[0] !== "") map[parts[0]] = parts[1];
                    }
                }
                root.iconPaths = map;
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: dockWindow
                required property var modelData
                screen: modelData
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                focusable: false
                implicitWidth: modelData ? modelData.width : 1920
                implicitHeight: modelData ? modelData.height : 1080
                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "equisdots-mos-dock"

                property var hoveredCell: null

                // The input region includes the magnification/tooltip overflow.
                Item {
                    id: dockHit
                    x: dockPanel.x - 2
                    width: dockPanel.width + 4
                    y: dockPanel.y - Math.round(root.iconSize * (root.magnifyScale - 1)) - 24
                    height: dockPanel.height + Math.round(root.iconSize * (root.magnifyScale - 1)) + 24
                }

                mask: Region { item: dockHit }

                RectangularShadow {
                    anchors.fill: dockPanel
                    radius: root.panelRadius
                    blur: 28
                    spread: 2
                    offset: Qt.vector2d(0, 8)
                    color: Qt.rgba(0, 0, 0, 0.40)
                    z: -1
                }

                Item {
                    id: dockPanel
                    width: dockRow.implicitWidth + root.sidePad * 2
                    height: root.dockHeight
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: root.bottomMargin

                    LiquidGlass {
                        anchors.fill: parent
                        enabled: root.glass
                        screenPosOverride: {
                            let p = dockPanel.mapToItem(null, 0, 0);
                            return Qt.vector2d(p.x, p.y);
                        }
                        topLeftRadius: root.panelRadius
                        topRightRadius: root.panelRadius
                        bottomLeftRadius: root.panelRadius
                        bottomRightRadius: root.panelRadius
                        tintColor: Theme.base
                        tintAmount: 0.24
                        frost: 12
                        interiorShade: 0.16
                        thickness: 16
                        rim: 0.82
                        ior: 1.4
                        dispersion: 0.015
                        grain: 0.012
                        bezel: Math.max(12, Math.min(22, root.dockHeight * 0.3))
                    }

                    // Adaptive neutral tint over the wallpaper sample.
                    Rectangle {
                        anchors.fill: parent
                        radius: root.panelRadius
                        color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b,
                                       (root.glass ? 0.20 : 0.68) * root.panelOpacity)
                        border.width: 1
                        border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.18)
                    }

                    // Specular top edge.
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: root.panelRadius * 0.7
                        anchors.rightMargin: root.panelRadius * 0.7
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.38)
                        opacity: 0.55
                    }

                    Row {
                        id: dockRow
                        anchors.centerIn: parent
                        spacing: root.spacing

                        Repeater {
                            model: root.dockItems

                            delegate: Item {
                                id: cell
                                required property var modelData
                                readonly property bool isSeparator: modelData && modelData.kind === "separator"
                                readonly property bool isRunning: !cell.isSeparator && root.appRunning(modelData)
                                readonly property bool hovered: appMouse.containsMouse
                                readonly property string iconSrc: cell.isSeparator ? "" : root.iconSource(modelData)
                                readonly property real magnifyFactor: {
                                    if (!root.magnify || !dockWindow.hoveredCell || cell.isSeparator)
                                        return 1;
                                    let h = dockWindow.hoveredCell;
                                    if (!h || h.isSeparator) return 1;
                                    let unit = Math.max(1, root.iconSize + root.spacing);
                                    let d = Math.abs((cell.x + cell.width / 2) - (h.x + h.width / 2)) / unit;
                                    return 1 + (root.magnifyScale - 1) * Math.exp(-(d * d) / 2.2);
                                }

                                width: cell.isSeparator ? root.separatorWidth : root.iconSize + 12
                                height: root.dockHeight
                                z: cell.isSeparator ? 0
                                   : (dockWindow.hoveredCell === cell ? 10 : 2)

                                Rectangle {
                                    visible: cell.isSeparator
                                    anchors.centerIn: parent
                                    width: 1
                                    height: Math.round(root.iconSize * 0.52)
                                    radius: width / 2
                                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
                                }

                                Item {
                                    id: iconBox
                                    visible: !cell.isSeparator
                                    width: root.iconSize
                                    height: root.iconSize
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: root.iconBottomMargin
                                    transformOrigin: Item.Bottom
                                    scale: cell.magnifyFactor
                                    property real lift: 0
                                    transform: Translate { y: -iconBox.lift }
                                    Behavior on scale {
                                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                    }

                                    Rectangle {
                                        id: iconMask
                                        anchors.fill: parent
                                        radius: root.iconRadius
                                        color: "white"
                                        visible: false
                                        layer.enabled: true
                                    }

                                    Image {
                                        id: appIcon
                                        anchors.fill: parent
                                        source: cell.iconSrc
                                        sourceSize.width: root.iconSize * 2
                                        sourceSize.height: root.iconSize * 2
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                        cache: true
                                        visible: source !== "" && status === Image.Ready
                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            maskEnabled: true
                                            maskSource: iconMask
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: root.iconRadius
                                        visible: !appIcon.visible
                                        color: Theme.surface1
                                        border.width: 1
                                        border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.14)
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10) }
                                            GradientStop { position: 1.0; color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.20) }
                                        }
                                        Text {
                                            anchors.centerIn: parent
                                            text: cell.modelData ? (cell.modelData.glyph || "󰀻") : "󰀻"
                                            color: Theme.text
                                            font.family: "Hack Nerd Font"
                                            font.pixelSize: Math.round(root.iconSize * 0.52)
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: root.iconRadius
                                        color: "transparent"
                                        border.width: 1
                                        border.color: Qt.rgba(1, 1, 1, 0.10)
                                    }
                                }

                                // Running-app dot, just under the icon.
                                Rectangle {
                                    visible: cell.isRunning
                                    width: Math.max(3, Math.round(root.iconSize * 0.085))
                                    height: width
                                    radius: width / 2
                                    color: Theme.text
                                    opacity: 0.9
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 2
                                    z: 30
                                }

                                // Optional persistent label (Apple uses hover-only by default).
                                Text {
                                    visible: root.showLabels && !cell.isSeparator
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 1
                                    width: root.iconSize + 8
                                    text: cell.modelData ? (cell.modelData.label || "") : ""
                                    color: Theme.subtext0
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: Math.max(8, Math.round(root.iconSize * 0.16))
                                    font.letterSpacing: 0.4
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    z: 25
                                }

                                // Hover label, like the macOS dock tooltip.
                                Rectangle {
                                    id: tooltip
                                    visible: cell.hovered && !cell.isSeparator
                                    z: 100
                                    width: tooltipText.implicitWidth + 16
                                    height: tooltipText.implicitHeight + 8
                                    radius: 6
                                    color: Qt.rgba(0.035, 0.035, 0.045, 0.92)
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.12)
                                    x: iconBox.x + (iconBox.width - width) / 2
                                    y: iconBox.y - height - 10 - (iconBox.scale - 1) * root.iconSize

                                    Text {
                                        id: tooltipText
                                        anchors.centerIn: parent
                                        text: cell.modelData ? (cell.modelData.label || "") : ""
                                        color: "#f5f5f7"
                                        font.family: "Hack Nerd Font"
                                        font.pixelSize: Math.max(9, Math.round(root.iconSize * 0.18))
                                    }

                                    Rectangle {
                                        width: 6
                                        height: 6
                                        rotation: 45
                                        color: tooltip.color
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: -3
                                    }
                                }

                                MouseArea {
                                    id: appMouse
                                    anchors.fill: parent
                                    enabled: !cell.isSeparator
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: dockWindow.hoveredCell = cell
                                    onExited: if (dockWindow.hoveredCell === cell)
                                                  dockWindow.hoveredCell = null
                                    onClicked: {
                                        if (root.bounce) bounceAnim.restart();
                                        root.launch(cell.modelData);
                                    }
                                }

                                SequentialAnimation {
                                    id: bounceAnim
                                    NumberAnimation {
                                        target: iconBox; property: "lift"
                                        to: root.iconSize * 0.36; duration: 130
                                        easing.type: Easing.OutQuad
                                    }
                                    NumberAnimation {
                                        target: iconBox; property: "lift"
                                        to: 0; duration: 440
                                        easing.type: Easing.OutBounce
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
