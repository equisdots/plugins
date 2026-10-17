import QtQuick
import Quickshell

// ═══════════════════════════════════════════════════════════════════════════
// HelloBar — POC fixture: a minimal COMPLETE bar shipped by a plugin.
//
// Declared in plugin.json as provides.bar.provider and mounted generically by
// ui/PluginHosts.qml while the plugin is enabled (master switch:
// plugins.hello-bar.enabled; its menu is settings/HelloBarPage.qml). The comp
// creates its own reserved PanelWindow(s): one 34 px band per screen on the
// top edge with a clock on the left and the optional date on the right.
// Placement and design are the plugin's business — disable the core bar in
// the Bar group when this one should own the screen edge.
//
// Settings live in the plugin's own file (scope "hello-bar"): showDate.
// Palette: the injected host handle (host.colors) with a local fallback.
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
        base: "#1e1e2e", text: "#cdd6f4", subtext0: "#a6adc8",
        surface0: "#313244", mauve: "#cba6f7"
    })
    readonly property var c: (host && host.colors) ? host.colors : _fb

    // Plugin-owned settings (scope "hello-bar", seeded from defaults.json).
    readonly property var cfg: {
        if (host && host.settings) return host.settings.all();
        return ({});
    }
    readonly property bool showDate: cfg.showDate !== false

    property string timeText: ""
    property string dateText: ""

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            root.timeText = Qt.formatDateTime(d, "HH:mm");
            root.dateText = Qt.formatDateTime(d, "ddd dd MMM");
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: barWindow
                required property var modelData
                screen: modelData

                anchors.top: true
                anchors.left: true
                anchors.right: true
                implicitHeight: 34
                exclusiveZone: 34
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    anchors.topMargin: 3
                    anchors.bottomMargin: 3
                    radius: height / 2
                    color: Qt.alpha(root.c.surface0, 0.85)
                }
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰖟"
                        font.family: "Hack Nerd Font"
                        font.pixelSize: 14
                        color: root.c.mauve
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.timeText
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Bold
                        font.pixelSize: 13
                        color: root.c.text
                    }
                }
                Text {
                    visible: root.showDate
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.dateText
                    font.family: "Hack Nerd Font"
                    font.pixelSize: 12
                    color: root.c.subtext0
                }
            }
        }
    }
}
