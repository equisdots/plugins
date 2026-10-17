import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

// ============================================================================
// CryptoCard — desktop-widget face: BTC and ETH price in USD + 24h change.
//
// The value producer makes ONE CoinGecko call and prints the raw JSON; this
// face parses it and renders two rows (ticker badge, name, price, change).
// Refreshes every 60 s while shown.
// ============================================================================

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 200
    property real minHeight: 140
    property real maxWidth: 560
    property real maxHeight: 420
    property real minAspect: 0.9
    property real maxAspect: 2.2
    property bool isRound: false

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/cryptowidget/scripts/crypto.sh"

    property var data: null
    readonly property bool active: root.visible && root.width > 0 && root.height > 0

    readonly property var coins: [
        { ticker: "BTC", name: "Bitcoin", id: "bitcoin" },
        { ticker: "ETH", name: "Ethereum", id: "ethereum" }
    ]

    function refresh() {
        reader.running = false;
        reader.running = true;
    }

    function parse(text) {
        let t = (text || "").trim();
        if (t === "") return;
        try { root.data = JSON.parse(t); } catch (e) {}
    }

    function num(id, key) {
        let c = (root.data && root.data[id]) ? root.data[id] : null;
        if (!c) return NaN;
        let v = c[key];
        return (v === undefined || v === null) ? NaN : Number(v);
    }

    function fmtUsd(v) {
        if (!isFinite(v)) return "--";
        let s = v.toFixed(2).split(".");
        s[0] = s[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        return "$" + s[0] + "." + s[1];
    }

    function fmtChange(v) {
        if (!isFinite(v)) return "--";
        return (v >= 0 ? "+" : "") + v.toFixed(2) + "%";
    }

    function changeColor(v) {
        if (!isFinite(v)) return Theme.subtext0;
        return v >= 0 ? Theme.green : Theme.red;
    }

    onActiveChanged: if (root.active) root.refresh()

    Timer {
        interval: 60000
        running: root.active
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: reader
        running: false
        command: ["bash", root.scriptPath]
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }

    Component.onCompleted: root.refresh()

    GlassCard {
        anchors.fill: parent
        fill: Theme.widgetFill
        hairline: Theme.widgetHairline
        cornerRadius: Theme.radiusLg
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapXs

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gapSm

            Text {
                text: "󰠓"
                font.family: Theme.fontFamily
                font.pixelSize: 15
                color: Theme.yellow
            }

            Text {
                Layout.fillWidth: true
                text: "Crypto"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Bold
                color: Theme.text
            }

            Text {
                text: "USD"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.letterSpacing: 0.8
                color: Theme.subtext0
            }
        }

        Repeater {
            model: root.coins

            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: Theme.gapSm

                Rectangle {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 26
                    radius: Theme.radiusSm
                    color: Theme.surface2

                    Text {
                        anchors.centerIn: parent
                        text: modelData.ticker
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Black
                        color: Theme.text
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: modelData.name
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.text
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.fmtChange(root.num(modelData.id, "usd_24h_change"))
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: root.changeColor(root.num(modelData.id, "usd_24h_change"))
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignRight
                    text: root.fmtUsd(root.num(modelData.id, "usd"))
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.Black
                    color: Theme.text
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
