import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 240
    property real minHeight: 120
    property real maxWidth: 900
    property real maxHeight: 420
    property real minAspect: 1.1
    property real maxAspect: 3.4
    property bool isRound: false
    property bool windowShown: true

    readonly property string homeDir: Quickshell.env("HOME") || "/home"
    readonly property string musicDir: {
        let v = Quickshell.env("QS_RUN_MUSIC");
        if (v !== "" && v !== undefined && v !== null)
            return v;
        return (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell/music";
    }
    readonly property string musicFilePath: root.musicDir + "/music_info.json"
    readonly property string controlScript: root.homeDir + "/.config/hypr/scripts/quickshell/ui/bar/popups/music/player_control.sh"
    readonly property string equalizerScript: root.homeDir + "/.config/hypr/scripts/quickshell/ui/bar/popups/music/equalizer.sh"
    readonly property string serifFamily: "Noto Serif CJK JP"

    property var musicData: null
    property bool artReady: false
    property int posSecs: 0
    property int lenSecs: 0
    property int displayPercent: 0
    property string positionText: "0:00"
    property string lengthText: "0:00"
    property bool userSeeking: false
    property double lastSeekAt: 0
    property double lastPlayAt: 0

    property var eqData: ({
        "b1": 0, "b2": 0, "b3": 0, "b4": 0, "b5": 0,
        "b6": 0, "b7": 0, "b8": 0, "b9": 0, "b10": 0,
        "preset": "Flat", "pending": false
    })
    property double lastEqUpdate: 0

    readonly property string status: root.musicData && root.musicData.status ? String(root.musicData.status) : "Stopped"
    readonly property bool isMediaActive: root.status === "Playing" || root.status === "Paused"
    readonly property bool isPlaying: root.status === "Playing"
    readonly property string titleText: root.musicData && root.musicData.title ? String(root.musicData.title) : (root.isMediaActive ? "Unknown Track" : "Nothing Playing")
    readonly property string artistText: root.musicData && root.musicData.artist ? String(root.musicData.artist) : ""
    readonly property string playerName: root.musicData && root.musicData.playerName ? String(root.musicData.playerName) : ""
    readonly property string deviceName: root.musicData && root.musicData.deviceName ? String(root.musicData.deviceName) : ""
    readonly property string mediaSource: root.musicData && root.musicData.source ? String(root.musicData.source) : ""
    readonly property string artUrl: root.musicData && root.musicData.artUrl ? String(root.musicData.artUrl) : ""
    readonly property bool hasUsableArt: root.artUrl !== "" && root.artUrl.indexOf("placeholder_blank") === -1
    readonly property string coverSource: {
        if (!root.hasUsableArt)
            return "";
        if (root.artUrl.indexOf("://") !== -1)
            return root.artUrl;
        return "file://" + root.artUrl;
    }
    onCoverSourceChanged: root.artReady = false
    readonly property string deviceLine: {
        let d = root.deviceName;
        let s = root.mediaSource;
        if (d !== "" && s !== "")
            return d + " · via " + s;
        if (d !== "")
            return d;
        return s !== "" ? "via " + s : "";
    }

    readonly property real pad: Math.max(8, Math.min(20, Math.min(root.width, root.height) * 0.065))
    readonly property real mastH: Math.max(15, Math.min(26, root.height * 0.092))
    readonly property bool showEq: root.height >= 380 && root.width >= 360
    readonly property real eqH: root.showEq ? Math.min(118, Math.max(76, root.height * 0.27)) : 0
    readonly property real bodyH: Math.max(0, root.height - root.pad * 2 - root.mastH - (root.showEq ? root.eqH + root.pad * 0.5 : 0))
    readonly property bool showArt: root.width >= 300 && root.bodyH >= 96
    readonly property bool railVisible: root.width >= 500 && root.bodyH >= 150
    readonly property real discSize: Math.max(64, Math.min(230, root.bodyH * 0.78, root.width * 0.27))
    readonly property real ensoSize: root.discSize * 1.38
    readonly property bool compact: root.width < 330 || root.height < 150
    readonly property bool tiny: root.height < 140 || root.width < 280
    readonly property bool showKicker: root.bodyH >= 140 && root.width >= 330
    readonly property bool showDeviceLine: root.isMediaActive && root.deviceLine !== "" && root.width >= 330 && root.bodyH >= 126
    readonly property bool showDiscMeta: root.discSize >= 140
    readonly property real titlePx: Math.max(12, Math.min(34, root.height * (root.tiny ? 0.105 : 0.115)))
    readonly property real subPx: Math.max(8, Math.min(13, root.height * 0.048))
    readonly property real microPx: Math.max(6, Math.min(9, root.height * 0.032))
    readonly property real controlSize: Math.max(root.tiny ? 17 : 22, Math.min(48, root.bodyH * (root.tiny ? 0.20 : 0.22)))
    readonly property real playSize: root.controlSize * (root.tiny ? 1.22 : 1.34)
    readonly property real progressH: Math.max(root.tiny ? 4 : 5, Math.min(11, root.bodyH * 0.075))
    readonly property color ink: Theme.text
    readonly property color paper: Theme.base
    readonly property color accent: Theme.red
    readonly property var eqLabels: ["32", "64", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    readonly property var eqPresets: [
        { "name": "Flat", "values": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] },
        { "name": "Bass", "values": [5, 7, 5, 2, 1, 0, 0, 0, 1, 2] },
        { "name": "Vocal", "values": [-2, -1, 1, 3, 5, 5, 4, 2, 1, 0] },
        { "name": "Rock", "values": [5, 4, 2, -1, -2, -1, 2, 4, 5, 6] }
    ]

    function pad2(n) {
        return (n < 10 ? "0" : "") + n;
    }

    function fmtClock(secs) {
        let s = Math.max(0, Math.floor(secs || 0));
        return Math.floor(s / 60) + ":" + root.pad2(s % 60);
    }

    function trackKey(data) {
        if (!data)
            return "";
        return String(data.artist || "") + "|" + String(data.title || "") + "|" + String(data.length || "");
    }

    function updateDisplay() {
        let data = root.musicData;
        if (!data) {
            root.posSecs = 0;
            root.lenSecs = 0;
            root.displayPercent = 0;
            root.positionText = "0:00";
            root.lengthText = "0:00";
            return;
        }
        let pos = parseInt(data.position, 10);
        let len = parseInt(data.length, 10);
        if (isNaN(pos))
            pos = 0;
        if (isNaN(len))
            len = 0;
        root.posSecs = Math.max(0, len > 0 ? Math.min(pos, len) : pos);
        root.lenSecs = Math.max(0, len);
        let pct = Number(data.percent);
        if (!isFinite(pct))
            pct = root.lenSecs > 0 ? (root.posSecs / root.lenSecs) * 100 : 0;
        root.displayPercent = Math.round(Math.max(0, Math.min(100, pct)));
        root.positionText = data.positionStr ? String(data.positionStr) : root.fmtClock(root.posSecs);
        root.lengthText = data.lengthStr ? String(data.lengthStr) : root.fmtClock(root.lenSecs);
    }

    function applyMusicJson(text) {
        let raw = text ? String(text).trim() : "";
        if (raw === "")
            return;
        let next = null;
        try {
            next = JSON.parse(raw);
        } catch (e) {
            return;
        }
        if (!next || typeof next !== "object")
            return;
        let prev = root.musicData;
        let same = prev !== null && root.trackKey(prev) === root.trackKey(next);
        if (same && Date.now() - root.lastPlayAt < 1500 && prev.status)
            next.status = prev.status;
        root.musicData = next;
        if (same && (root.userSeeking || Date.now() - root.lastSeekAt < 1200))
            return;
        root.updateDisplay();
    }

    function readMusic() {
        musicReader.running = false;
        musicReader.running = true;
    }

    function readEq() {
        eqReader.running = false;
        eqReader.running = true;
    }

    function togglePlay() {
        root.lastPlayAt = Date.now();
        if (root.musicData) {
            let temp = Object.assign({}, root.musicData);
            temp.status = root.isPlaying ? "Paused" : "Playing";
            root.musicData = temp;
        }
        Quickshell.execDetached(["bash", root.controlScript, "play-pause", "", "", root.playerName]);
    }

    function skip(delta) {
        root.lastSeekAt = Date.now();
        root.lastPlayAt = Date.now();
        root.posSecs = 0;
        root.displayPercent = 0;
        root.positionText = root.fmtClock(0);
        Quickshell.execDetached(["bash", root.controlScript, delta < 0 ? "prev" : "next", "", "", root.playerName]);
    }

    function previewSeek(fraction) {
        if (root.lenSecs <= 0)
            return;
        let f = Math.max(0, Math.min(1, fraction));
        root.userSeeking = true;
        root.posSecs = Math.min(root.lenSecs, Math.round(root.lenSecs * f));
        root.displayPercent = Math.round(f * 100);
        root.positionText = root.fmtClock(root.posSecs);
    }

    function commitSeek() {
        if (root.lenSecs > 0) {
            root.lastSeekAt = Date.now();
            Quickshell.execDetached(["bash", root.controlScript, "seek", root.displayPercent.toFixed(2), String(root.lenSecs), root.playerName]);
        }
        seekSettleTimer.restart();
    }

    function eqValue(idx) {
        let data = root.eqData || ({});
        let v = Number(data["b" + idx]);
        return isNaN(v) ? 0 : Math.max(-12, Math.min(12, v));
    }

    function setEqBand(idx, value) {
        let v = Math.max(-12, Math.min(12, Math.round(value)));
        let temp = Object.assign({}, root.eqData || ({}));
        temp["b" + idx] = v;
        temp.preset = "Custom";
        temp.pending = true;
        root.eqData = temp;
        root.lastEqUpdate = Date.now();
    }

    function commitEqBand(idx) {
        Quickshell.execDetached(["bash", root.equalizerScript, "set_band", String(idx), String(root.eqValue(idx))]);
        root.lastEqUpdate = Date.now();
    }

    function applyEqPreset(name) {
        let preset = null;
        for (let i = 0; i < root.eqPresets.length; i++) {
            if (root.eqPresets[i].name === name)
                preset = root.eqPresets[i];
        }
        if (!preset)
            return;
        let temp = Object.assign({}, root.eqData || ({}));
        for (let i = 0; i < 10; i++)
            temp["b" + (i + 1)] = preset.values[i];
        temp.preset = name;
        temp.pending = false;
        root.eqData = temp;
        root.lastEqUpdate = Date.now();
        Quickshell.execDetached(["bash", root.equalizerScript, "preset", name]);
    }

    function applyEq() {
        if (!root.eqData || !root.eqData.pending)
            return;
        let temp = Object.assign({}, root.eqData);
        temp.pending = false;
        root.eqData = temp;
        root.lastEqUpdate = Date.now();
        Quickshell.execDetached(["bash", root.equalizerScript, "apply"]);
    }

    function rgba(c, a) {
        return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + a + ")";
    }

    function tint(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    Component.onCompleted: root.readMusic()

    onWindowShownChanged: {
        if (root.windowShown)
            root.readMusic();
    }

    Timer {
        interval: 1000
        running: root.isPlaying && root.windowShown && !root.userSeeking
        repeat: true
        onTriggered: {
            if (!root.isPlaying || root.lenSecs <= 0)
                return;
            root.posSecs = Math.min(root.posSecs + 1, root.lenSecs);
            root.displayPercent = Math.round((root.posSecs / root.lenSecs) * 100);
            root.positionText = root.fmtClock(root.posSecs);
        }
    }

    Timer {
        interval: 2000
        running: root.windowShown
        repeat: true
        triggeredOnStart: true
        onTriggered: root.readMusic()
    }

    Timer {
        interval: 2000
        running: root.windowShown && root.showEq
        repeat: true
        triggeredOnStart: true
        onTriggered: root.readEq()
    }

    Timer {
        id: seekSettleTimer
        interval: 1200
        onTriggered: root.userSeeking = false
    }

    Process {
        id: musicReader
        command: ["bash", "-c", "cat -- \"$1\" 2>/dev/null || true", "music-sumi-read", root.musicFilePath]
        stdout: StdioCollector {
            onStreamFinished: root.applyMusicJson(this.text)
        }
    }

    Process {
        id: eqReader
        command: ["bash", root.equalizerScript, "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (Date.now() - root.lastEqUpdate < 2000)
                    return;
                let raw = this.text ? this.text.trim() : "";
                if (raw === "")
                    return;
                try {
                    let data = JSON.parse(raw);
                    if (data && typeof data === "object") {
                        if (data.pending === undefined)
                            data.pending = false;
                        if (!data.preset)
                            data.preset = "Flat";
                        root.eqData = data;
                    }
                } catch (e) {}
            }
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Math.min(Theme.radiusSm, 6)
        color: root.paper
        border.width: 1
        border.color: root.tint(root.ink, 0.82)
        clip: true

        Canvas {
            id: paperTexture
            anchors.fill: parent
            property color inkColor: Theme.text
            property color accentColor: Theme.red
            onInkColorChanged: requestPaint()
            onAccentColorChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                let ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                let w = width;
                let h = height;
                let wash = ctx.createRadialGradient(w * 0.18, h * 0.26, 0, w * 0.18, h * 0.26, Math.max(w, h) * 0.72);
                wash.addColorStop(0, root.rgba(root.accent, 0.06));
                wash.addColorStop(1, root.rgba(root.accent, 0));
                ctx.fillStyle = wash;
                ctx.fillRect(0, 0, w, h);
                let seed = 20261003;
                function rnd() {
                    seed = (seed * 1664525 + 1013904223) % 4294967296;
                    return seed / 4294967296;
                }
                ctx.fillStyle = root.rgba(root.ink, 0.055);
                let count = Math.min(520, Math.floor(w * h / 900));
                for (let i = 0; i < count; i++) {
                    let x = rnd() * w;
                    let y = rnd() * h;
                    let s = 0.4 + rnd() * 0.9;
                    ctx.fillRect(x, y, s, s);
                }
            }
        }

        RowLayout {
            id: mast
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: root.pad
            anchors.rightMargin: root.pad
            anchors.topMargin: root.pad * 0.55
            height: root.mastH
            spacing: Math.max(4, root.pad * 0.4)

            SumiSeal {
                sealSize: Math.max(15, root.mastH * 0.8)
                glyph: "音"
                tilt: -5
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                text: "墨"
                font.family: root.serifFamily
                font.pixelSize: root.mastH * 0.78
                font.weight: Font.DemiBold
                color: root.ink
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                text: "· SOUND ROOM"
                visible: root.width >= 300
                font.family: Theme.fontFamily
                font.pixelSize: root.microPx
                font.letterSpacing: 1.8
                color: Theme.subtext0
                Layout.alignment: Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "No. 03 / 2026"
                visible: root.width >= 470
                font.family: Theme.fontFamily
                font.pixelSize: root.microPx
                font.letterSpacing: 1.4
                color: Theme.yellow
                Layout.alignment: Qt.AlignVCenter
            }
            Item {
                Layout.fillWidth: true
                visible: root.width >= 470
            }
            RowLayout {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter
                Text {
                    text: "●"
                    font.family: Theme.fontFamily
                    font.pixelSize: root.microPx * 0.9
                    color: root.isPlaying ? root.accent : Theme.overlay0
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: root.isPlaying ? "再生中" : (root.status === "Paused" ? "一時停止" : "停止")
                    font.family: Theme.fontFamily
                    font.pixelSize: root.microPx
                    font.letterSpacing: 1.0
                    color: root.isPlaying ? root.accent : Theme.subtext0
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        Rectangle {
            id: mastRule
            anchors.left: mast.left
            anchors.right: mast.right
            anchors.top: mast.bottom
            height: 1
            color: root.tint(root.ink, 0.28)
        }

        Item {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: mastRule.bottom
            anchors.bottom: root.showEq ? eqPanel.top : parent.bottom
            anchors.leftMargin: root.pad
            anchors.rightMargin: root.pad
            anchors.topMargin: root.pad * 0.55
            anchors.bottomMargin: root.showEq ? root.pad * 0.5 : root.pad

            Item {
                id: rail
                visible: root.railVisible
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: root.railVisible ? Math.max(20, Math.min(32, root.width * 0.05)) : 0

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: root.tint(root.ink, 0.18)
                }

                Column {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 0
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "音"
                        font.family: root.serifFamily
                        font.pixelSize: Math.max(14, Math.min(24, root.bodyH * 0.13))
                        color: root.ink
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "楽"
                        font.family: root.serifFamily
                        font.pixelSize: Math.max(14, Math.min(24, root.bodyH * 0.13))
                        color: root.ink
                    }
                }

                Column {
                    visible: root.bodyH >= 170
                    anchors.bottom: railSeal.top
                    anchors.bottomMargin: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 0
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "再"
                        font.family: root.serifFamily
                        font.pixelSize: root.microPx
                        color: Theme.subtext0
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "生"
                        font.family: root.serifFamily
                        font.pixelSize: root.microPx
                        color: Theme.subtext0
                    }
                }

                SumiSeal {
                    id: railSeal
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    sealSize: Math.max(18, Math.min(28, root.bodyH * 0.16))
                    glyph: "侍"
                    tilt: -4
                }
            }

            Item {
                id: discArea
                visible: root.showArt
                anchors.left: root.railVisible ? rail.right : body.left
                anchors.verticalCenter: body.verticalCenter
                width: root.ensoSize
                height: root.ensoSize

                Canvas {
                    id: ensoCanvas
                    anchors.fill: parent
                    property color inkColor: Theme.text
                    onInkColorChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    onPaint: {
                        let ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        let cx = width / 2;
                        let cy = height / 2;
                        let R = Math.min(width, height) * 0.445;
                        let start = -Math.PI * 0.25 + 0.12;
                        let sweep = Math.PI * 2 - 0.5;
                        let steps = 56;
                        ctx.lineCap = "round";
                        for (let i = 0; i < steps; i++) {
                            let a0 = start + sweep * i / steps;
                            let a1 = start + sweep * (i + 1) / steps + 0.006;
                            let t = i / (steps - 1);
                            let taper = 0.35 + 0.65 * Math.sin(Math.PI * Math.min(1, t * 1.06));
                            let wobble = 1 + 0.012 * Math.sin(i * 1.9) + 0.006 * Math.sin(i * 5.3);
                            ctx.beginPath();
                            ctx.arc(cx, cy, R * wobble, a0, a1);
                            ctx.lineWidth = Math.max(1.2, Math.min(width, height) * 0.055 * taper);
                            ctx.strokeStyle = root.rgba(root.ink, 0.82);
                            ctx.stroke();
                        }
                        ctx.beginPath();
                        ctx.arc(cx, cy, R * 1.035, start + sweep * 0.12, start + sweep * 0.3);
                        ctx.lineWidth = Math.max(1, Math.min(width, height) * 0.012);
                        ctx.strokeStyle = root.rgba(root.ink, 0.34);
                        ctx.stroke();
                    }
                }

                Item {
                    id: disc
                    width: root.discSize
                    height: root.discSize
                    anchors.centerIn: parent

                    Rectangle {
                        id: discFace
                        anchors.fill: parent
                        radius: width / 2
                        color: Theme.surface0
                        border.width: Math.max(1.5, root.discSize * 0.015)
                        border.color: root.ink
                        clip: true

                        Item {
                            id: spin
                            anchors.fill: parent

                            Image {
                                anchors.fill: parent
                                source: root.coverSource
                                visible: root.coverSource !== ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                smooth: true
                                mipmap: true
                                sourceSize: Qt.size(640, 640)
                                onStatusChanged: root.artReady = (status === Image.Ready)
                            }

                            NumberAnimation on rotation {
                                running: root.isPlaying && root.windowShown && root.artReady
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 44000
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !root.artReady
                            text: "音"
                            font.family: root.serifFamily
                            font.pixelSize: parent.width * 0.42
                            color: root.ink
                            opacity: 0.85
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: root.tint(root.accent, 0.035)
                        }
                    }

                    SumiSeal {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: -width * 0.12
                        anchors.bottomMargin: -height * 0.12
                        sealSize: Math.max(16, Math.min(34, root.discSize * 0.18))
                        glyph: "音"
                        tilt: -7
                    }
                }

                RowLayout {
                    visible: root.showDiscMeta
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: root.discSize * 0.12
                    anchors.rightMargin: root.discSize * 0.12
                    spacing: 4
                    Text {
                        text: "33 ⅓ RPM"
                        font.family: Theme.fontFamily
                        font.pixelSize: root.microPx * 0.82
                        font.letterSpacing: 1.0
                        color: Theme.subtext0
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "STEREO"
                        font.family: Theme.fontFamily
                        font.pixelSize: root.microPx * 0.82
                        font.letterSpacing: 1.0
                        color: Theme.subtext0
                    }
                }
            }

            Item {
                id: copy
                anchors.left: root.showArt ? discArea.right : (root.railVisible ? rail.right : body.left)
                anchors.leftMargin: root.showArt ? -root.discSize * 0.10 : (root.railVisible ? root.pad * 0.4 : 0)
                anchors.right: body.right
                anchors.top: body.top
                anchors.bottom: body.bottom

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Math.max(1, Math.min(4, root.bodyH * 0.018))

                    Text {
                        visible: root.showKicker
                        text: root.isMediaActive ? "NOW PLAYING / 03" : "SUMI · STANDBY"
                        font.family: Theme.fontFamily
                        font.pixelSize: root.microPx
                        font.letterSpacing: 2.0
                        color: root.accent
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Item {
                        id: titleClip
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.preferredHeight: titleMain.implicitHeight
                        clip: true

                        property int marqueeSpacing: Math.max(18, root.width * 0.04)
                        property real scrollProgress: 0

                        Item {
                            height: parent.height
                            x: titleMain.implicitWidth > titleClip.width
                                ? -titleClip.scrollProgress * (titleMain.implicitWidth + titleClip.marqueeSpacing)
                                : 0

                            Row {
                                spacing: titleClip.marqueeSpacing
                                Text {
                                    id: titleMain
                                    text: root.titleText
                                    font.family: root.serifFamily
                                    font.pixelSize: root.titlePx
                                    font.weight: Font.DemiBold
                                    color: root.ink
                                    onTextChanged: titleClip.scrollProgress = 0
                                }
                                Text {
                                    text: titleMain.text
                                    visible: titleMain.implicitWidth > titleClip.width
                                    font.family: root.serifFamily
                                    font.pixelSize: root.titlePx
                                    font.weight: Font.DemiBold
                                    color: root.ink
                                }
                            }
                        }

                        SequentialAnimation {
                            loops: Animation.Infinite
                            running: root.windowShown && titleMain.implicitWidth > titleClip.width
                            PauseAnimation { duration: 3000 }
                            NumberAnimation {
                                target: titleClip
                                property: "scrollProgress"
                                from: 0
                                to: 1
                                duration: (titleMain.implicitWidth + titleClip.marqueeSpacing) * 26
                            }
                            PropertyAction {
                                target: titleClip
                                property: "scrollProgress"
                                value: 0
                            }
                        }
                    }

                    Text {
                        visible: root.isMediaActive && root.artistText !== ""
                        text: root.artistText
                        font.family: Theme.fontFamily
                        font.pixelSize: root.subPx
                        font.letterSpacing: 0.7
                        color: Theme.subtext1
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: root.showDeviceLine
                        text: root.deviceLine
                        font.family: Theme.fontFamily
                        font.pixelSize: root.microPx
                        font.letterSpacing: 1.0
                        color: Theme.subtext0
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        Layout.fillWidth: true
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.minimumHeight: 0
                    }

                    Item {
                        id: progressArea
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.progressH + Math.max(4, root.progressH * 0.8)

                        Rectangle {
                            id: track
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: root.progressH
                            radius: height / 2
                            color: root.tint(root.ink, 0.10)
                            border.width: 1
                            border.color: root.tint(root.ink, 0.16)

                            Rectangle {
                                id: fill
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * (root.displayPercent / 100.0)
                                radius: parent.radius
                                color: root.ink
                                clip: true

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    y: parent.height * 0.26
                                    height: Math.max(0.6, parent.height * 0.10)
                                    color: root.tint(root.paper, 0.14)
                                }
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    y: parent.height * 0.62
                                    height: Math.max(0.6, parent.height * 0.08)
                                    color: root.tint(root.paper, 0.10)
                                }

                                Behavior on width {
                                    enabled: !root.userSeeking
                                    NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                                }
                            }

                            Rectangle {
                                id: progressDot
                                width: Math.max(6, root.progressH * 0.82)
                                height: width
                                radius: width / 2
                                color: root.accent
                                border.width: Math.max(1, width * 0.16)
                                border.color: root.paper
                                x: Math.max(-width * 0.2, Math.min(parent.width - width * 0.8, parent.width * (root.displayPercent / 100.0) - width / 2))
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: seekArea
                            anchors.fill: parent
                            preventStealing: true
                            cursorShape: root.lenSecs > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor

                            function fractionAt(mx) {
                                let p = seekArea.mapToItem(track, mx, 0);
                                return track.width > 0 ? Math.max(0, Math.min(1, p.x / track.width)) : 0;
                            }

                            onPressed: {
                                if (root.lenSecs > 0)
                                    root.previewSeek(fractionAt(mouse.x));
                            }
                            onPositionChanged: {
                                if (pressed && root.lenSecs > 0)
                                    root.previewSeek(fractionAt(mouse.x));
                            }
                            onReleased: {
                                if (root.lenSecs > 0)
                                    root.commitSeek();
                            }
                            onCanceled: root.userSeeking = false
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Math.max(4, root.pad * 0.4)
                        Text {
                            text: root.positionText
                            font.family: root.serifFamily
                            font.pixelSize: Math.max(10, Math.min(22, root.titlePx * 0.78))
                            font.weight: Font.DemiBold
                            color: root.ink
                            Layout.alignment: Qt.AlignBottom
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: root.tint(root.ink, 0.22)
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Text {
                            text: root.lengthText
                            font.family: Theme.fontFamily
                            font.pixelSize: root.microPx
                            color: Theme.subtext0
                            Layout.alignment: Qt.AlignBottom
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.playSize + 6
                        spacing: Math.max(5, root.controlSize * 0.24)

                        InkControl {
                            glyph: "󰒮"
                            Layout.alignment: Qt.AlignVCenter
                            onActivated: root.skip(-1)
                        }

                        Item {
                            width: root.playSize + 3
                            height: root.playSize + 3
                            implicitWidth: width
                            implicitHeight: height
                            Layout.alignment: Qt.AlignVCenter
                            scale: playMouse.containsMouse ? 1.03 : 1.0

                            Behavior on scale {
                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }

                            Rectangle {
                                x: 3
                                y: 3
                                width: parent.width - 3
                                height: parent.height - 3
                                radius: width / 2
                                color: root.tint(root.ink, 0.78)
                            }

                            Rectangle {
                                id: playFace
                                width: parent.width - 3
                                height: parent.height - 3
                                radius: width / 2
                                color: root.accent
                                border.width: Math.max(1, root.playSize * 0.035)
                                border.color: root.ink

                                Text {
                                    anchors.centerIn: parent
                                    text: root.isPlaying ? "󰏤" : "󰐊"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: parent.width * 0.42
                                    color: root.paper
                                }
                            }

                            MouseArea {
                                id: playMouse
                                anchors.fill: playFace
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.togglePlay()
                            }
                        }

                        InkControl {
                            glyph: "󰒭"
                            Layout.alignment: Qt.AlignVCenter
                            onActivated: root.skip(1)
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            visible: root.width >= 520 && !root.compact
                            text: "SUMI · 墨"
                            font.family: root.serifFamily
                            font.pixelSize: root.microPx
                            font.letterSpacing: 1.6
                            color: Theme.subtext0
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }
            }
        }

        Rectangle {
            id: eqPanel
            visible: root.showEq
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.eqH
            color: root.tint(root.ink, 0.035)

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 2
                color: root.tint(root.ink, 0.85)
            }

            RowLayout {
                id: eqHead
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: root.pad
                anchors.rightMargin: root.pad
                anchors.topMargin: Math.max(4, root.pad * 0.4)
                height: Math.max(14, root.microPx * 2)
                spacing: 5

                Text {
                    text: "調音 · TONAL"
                    font.family: Theme.fontFamily
                    font.pixelSize: root.microPx
                    font.letterSpacing: 1.4
                    color: Theme.subtext0
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: root.eqData && root.eqData.preset ? String(root.eqData.preset).toUpperCase() : "FLAT"
                    font.family: root.serifFamily
                    font.pixelSize: root.microPx + 1
                    font.weight: Font.DemiBold
                    color: root.accent
                    elide: Text.ElideRight
                    Layout.maximumWidth: root.width * 0.16
                    Layout.alignment: Qt.AlignVCenter
                }
                Item { Layout.fillWidth: true }
                Row {
                    spacing: 3
                    Layout.alignment: Qt.AlignVCenter
                    Repeater {
                        model: root.eqPresets
                        delegate: InkChip {
                            label: modelData.name
                            active: root.eqData && String(root.eqData.preset) === modelData.name
                            onPicked: root.applyEqPreset(modelData.name)
                        }
                    }
                }
                InkChip {
                    label: root.eqData && root.eqData.pending ? "APPLY" : "SAVED"
                    active: root.eqData && root.eqData.pending
                    Layout.alignment: Qt.AlignVCenter
                    onPicked: root.applyEq()
                }
            }

            Row {
                id: eqBands
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: eqHead.bottom
                anchors.bottom: parent.bottom
                anchors.leftMargin: root.pad
                anchors.rightMargin: root.pad
                anchors.topMargin: Math.max(3, root.pad * 0.25)
                anchors.bottomMargin: Math.max(4, root.pad * 0.35)
                spacing: Math.max(2, width * 0.006)

                Repeater {
                    model: 10
                    delegate: Item {
                        id: bandCell
                        property int bandNo: index + 1
                        property real bandValue: root.eqValue(bandNo)
                        property real norm: (bandValue + 12) / 24
                        property real valueH: Math.max(8, root.microPx + 1)
                        property real labelH: Math.max(8, root.microPx + 1)
                        property real trackTop: valueH + 1
                        property real trackH: Math.max(12, height - trackTop - labelH - 2)

                        width: (eqBands.width - (10 - 1) * eqBands.spacing) / 10
                        height: eqBands.height

                        Text {
                            id: bandValueText
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (bandCell.bandValue > 0 ? "+" : "") + Math.round(bandCell.bandValue)
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.max(6, root.microPx - 1)
                            color: Math.abs(bandCell.bandValue) >= 1 ? root.accent : Theme.subtext0
                        }

                        Rectangle {
                            id: bandTrack
                            anchors.top: parent.top
                            anchors.topMargin: bandCell.trackTop
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.max(6, Math.min(parent.width * 0.62, 18))
                            height: bandCell.trackH
                            radius: width * 0.42
                            color: root.tint(root.ink, 0.07)
                            border.width: 1
                            border.color: root.tint(root.ink, 0.16)
                            clip: true

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: parent.height * bandCell.norm
                                radius: parent.radius
                                gradient: Gradient {
                                    orientation: Gradient.Vertical
                                    GradientStop { position: 0.0; color: root.accent }
                                    GradientStop { position: 0.14; color: root.accent }
                                    GradientStop { position: 0.15; color: root.ink }
                                    GradientStop { position: 1.0; color: root.ink }
                                }
                            }
                        }

                        Text {
                            id: bandLabelText
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.eqLabels[index]
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.max(6, root.microPx - 1)
                            color: Theme.subtext0
                        }

                        MouseArea {
                            anchors.fill: bandTrack
                            anchors.margins: -Math.max(3, bandCell.width * 0.18)
                            cursorShape: Qt.SizeVerCursor
                            preventStealing: true

                            function valueAt(my) {
                                let p = mapToItem(bandTrack, 0, my);
                                return Math.max(0, Math.min(1, 1 - p.y / bandTrack.height)) * 24 - 12;
                            }

                            onPressed: root.setEqBand(bandCell.bandNo, valueAt(mouse.y))
                            onPositionChanged: {
                                if (pressed)
                                    root.setEqBand(bandCell.bandNo, valueAt(mouse.y));
                            }
                            onReleased: root.commitEqBand(bandCell.bandNo)
                            onCanceled: root.commitEqBand(bandCell.bandNo)
                        }
                    }
                }
            }
        }
    }

    component SumiSeal: Item {
        id: seal
        property real sealSize: 20
        property string glyph: "音"
        property real tilt: -6

        width: sealSize
        height: sealSize
        implicitWidth: sealSize
        implicitHeight: sealSize
        rotation: tilt

        Rectangle {
            anchors.fill: parent
            radius: Math.max(1, seal.sealSize * 0.06)
            color: root.accent
            border.width: Math.max(1, seal.sealSize * 0.07)
            border.color: root.paper

            Text {
                anchors.centerIn: parent
                text: seal.glyph
                font.family: root.serifFamily
                font.pixelSize: seal.sealSize * 0.56
                color: root.paper
            }
        }
    }

    component InkControl: Item {
        id: ctl
        property string glyph: ""
        signal activated()

        width: root.controlSize
        height: root.controlSize
        implicitWidth: width
        implicitHeight: height

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: ctlMouse.containsMouse || ctlMouse.pressed ? root.ink : "transparent"
            border.width: Math.max(1, root.controlSize * 0.055)
            border.color: root.ink

            Text {
                anchors.centerIn: parent
                text: ctl.glyph
                font.family: Theme.fontFamily
                font.pixelSize: ctl.height * 0.44
                color: ctlMouse.containsMouse || ctlMouse.pressed ? root.paper : root.ink
            }
        }

        MouseArea {
            id: ctlMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ctl.activated()
        }
    }

    component InkChip: Rectangle {
        id: chip
        property string label: ""
        property bool active: false
        signal picked()

        implicitWidth: chipText.implicitWidth + Math.max(6, root.microPx)
        implicitHeight: Math.max(13, root.microPx * 1.9)
        width: implicitWidth
        height: implicitHeight
        radius: 1
        color: chip.active || chipMouse.containsMouse ? root.accent : "transparent"
        border.width: 1
        border.color: chip.active || chipMouse.containsMouse ? root.accent : root.tint(root.ink, 0.55)

        Text {
            id: chipText
            anchors.centerIn: parent
            text: chip.label.toUpperCase()
            font.family: Theme.fontFamily
            font.pixelSize: Math.max(6, root.microPx - 1)
            font.letterSpacing: 0.6
            color: chip.active || chipMouse.containsMouse ? root.paper : root.ink
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.picked()
        }
    }
}
