import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core

// ═══════════════════════════════════════════════════════════════════════════
// mos Dock — a customizable macOS-style bottom dock.
//
// Host adapter: one click-through overlay per screen, with the input mask
// limited to the floating dock panel. App shortcuts launch directly; no core
// files are touched.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    visible: false
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
        { label: "FINDER", glyph: "󰉋", exec: "nautilus" },
        { label: "SAFARI", glyph: "󰖟", exec: "brave" },
        { label: "MAIL", glyph: "󰇮", exec: "thunderbird" },
        { label: "MUSIC", glyph: "󰝚", exec: "spotify" },
        { label: "TERMINAL", glyph: "󰆍", exec: "kitty" },
        { label: "SETTINGS", glyph: "󰒓", exec: "~/.config/hypr/scripts/qs_manager.sh toggle settings" }
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
    readonly property int dockHeight: iconSize + (showLabels ? 28 : 16)

    readonly property color panelColor: Qt.rgba(0.075, 0.075, 0.09, panelOpacity)
    readonly property color borderColor: Qt.rgba(1, 1, 1, 0.16)
    readonly property color textColor: "#f5f5f7"
    readonly property color dimColor: Qt.rgba(1, 1, 1, 0.6)

    function launch(app) {
        let cmd = String((app && (app.exec || app.command)) || "").trim();
        if (cmd === "") return;
        Quickshell.execDetached(["bash", "-lc", cmd]);
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
                implicitWidth: modelData ? modelData.width : 1920
                implicitHeight: modelData ? modelData.height : 1080
                anchors.top: true; anchors.bottom: true; anchors.left: true; anchors.right: true
                focusable: false
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "equisdots-mos-dock"
                mask: Region { item: dockPanel }

                Rectangle {
                    id: dockPanel
                    width: dockRow.implicitWidth + 16
                    height: root.dockHeight
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 10
                    color: root.panelColor
                    border.width: 1
                    border.color: root.borderColor
                    radius: 18

                    Row {
                        id: dockRow
                        anchors.centerIn: parent
                        spacing: root.spacing

                        Repeater {
                            model: root.apps
                            delegate: Item {
                                required property var modelData
                                width: root.iconSize + 14
                                height: root.dockHeight
                                property bool hovered: appMouse.containsMouse

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Item {
                                        width: root.iconSize
                                        height: root.iconSize
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        scale: root.magnify && hovered ? root.magnifyScale : 1.0
                                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.glyph || "󰀻"
                                            font.family: "Hack Nerd Font"
                                            font.pixelSize: Math.round(root.iconSize * 0.56)
                                            color: hovered ? "#ffffff" : root.textColor
                                        }
                                    }
                                    Text {
                                        visible: root.showLabels
                                        width: root.iconSize + 8
                                        text: modelData.label || ""
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        font.family: "Noto Sans"
                                        font.pixelSize: 8
                                        color: root.dimColor
                                    }
                                }

                                MouseArea {
                                    id: appMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.launch(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
