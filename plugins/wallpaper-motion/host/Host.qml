// Wallpaper Motion host — keeps the saved frame rate sticky: watches the live
// xwww scene and, whenever a NEW scene starts (new pid, e.g. after applying a
// wallpaper in the picker), re-applies the saved rate. No davincix changes.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Item {
    id: root
    visible: false
    width: 0
    height: 0

    // Injected by ui/PluginHosts.qml.
    property var host: null
    property string lastPid: ""

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/wallpaper-motion/scripts/motion.sh"

    function poll() { st.running = false; st.running = true; }

    Process {
        id: st
        command: ["bash", root.scriptPath, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                let t = (this.text || "").trim();
                let pid = t.split(/\s+/)[0] || "";
                if (pid === "") { root.lastPid = ""; return; }
                if (pid === root.lastPid) return;
                root.lastPid = pid;
                applyTimer.restart();
            }
        }
    }
    Timer { interval: 2500; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.poll() }

    Timer {
        id: applyTimer
        interval: 1800
        onTriggered: {
            let fps = root.host ? Number(root.host.settings.get("fps", 30)) : 30;
            applyProc.command = ["bash", root.scriptPath, "apply-if-diff", String(fps)];
            applyProc.running = true;
        }
    }
    Process { id: applyProc }
}
