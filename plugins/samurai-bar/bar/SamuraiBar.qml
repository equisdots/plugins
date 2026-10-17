import QtQuick
import Quickshell
import Quickshell.Io
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

    // ── system (shared poller) ──────────────────────────────────────────────
    Component.onCompleted: SysData.subscribe()
    Component.onDestruction: SysData.unsubscribe()

    // ── workspaces ──────────────────────────────────────────────────────────
    property var wsList: []
    property int wsActive: -1
    Process {
        id: wsProc
        command: ["bash", Quickshell.env("HOME") + "/.config/hypr/plugins/samurai-bar/scripts/workspaces.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { let o = JSON.parse(this.text); root.wsList = o.ws || []; root.wsActive = o.active; }
                catch (e) { root.wsList = []; }
            }
        }
    }
    Timer { interval: 1500; running: true; repeat: true; onTriggered: { wsProc.running = false; wsProc.running = true; } }

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
    component Seg: Row {
        id: seg
        property string label: ""
        property string value: ""
        property color valueColor: root.c.text
        spacing: 5

        Rectangle { width: 1; height: root.barH - 12; color: root.hair; anchors.verticalCenter: parent.verticalCenter }
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
                        model: root.wsList
                        delegate: Item {
                            required property var modelData
                            readonly property bool on: modelData === root.wsActive
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
                                    "hyprctl dispatch workspace " + modelData])
                            }
                        }
                    }
                }

                // ── center: clock + date ───────────────────────────────────
                Row {
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

                // ── right: system segments ─────────────────────────────────
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    height: root.barH
                    spacing: 10

                    Seg {
                        visible: root.cfg.showCpu !== false
                        anchors.verticalCenter: parent.verticalCenter
                        label: "CPU"; value: SysData.cpu + "%"
                        valueColor: root.status(SysData.cpu < 85, SysData.cpu < 95)
                    }
                    Seg {
                        visible: root.cfg.showMem !== false
                        anchors.verticalCenter: parent.verticalCenter
                        label: "MEM"; value: SysData.ramPercent + "%"
                    }
                    Seg {
                        visible: root.cfg.showTemp !== false
                        anchors.verticalCenter: parent.verticalCenter
                        label: "TEMP"; value: (SysData.temp > 0 ? SysData.temp + "°" : "--")
                        valueColor: root.status(SysData.temp < 80 || SysData.temp === 0, SysData.temp < 90)
                    }
                    Seg {
                        visible: root.cfg.showNet !== false
                        anchors.verticalCenter: parent.verticalCenter
                        label: "NET"
                        value: "↓" + (SysData.netRx / 1024).toFixed(1) + " ↑" + (SysData.netTx / 1024).toFixed(1)
                    }
                    Seg {
                        visible: root.cfg.showBattery !== false
                        anchors.verticalCenter: parent.verticalCenter
                        label: "BAT"
                        value: (root.batPct < 0 ? "AC" : root.batPct + "%")
                        valueColor: root.status(root.batPct < 0 || root.batPct > 15)
                    }

                    Rectangle { width: 1; height: root.barH - 12; color: root.hair; anchors.verticalCenter: parent.verticalCenter }
                    Item {
                        width: 18; height: root.barH
                        anchors.verticalCenter: parent.verticalCenter
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

    function pad2(n) { return (n < 10 ? "0" : "") + n; }
}
