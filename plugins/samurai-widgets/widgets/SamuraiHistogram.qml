import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 220
    property real minHeight: 120
    property real maxWidth: 1200
    property real maxHeight: 500
    property real minAspect: 0.8
    property real maxAspect: 5.0
    property bool isRound: false
    property bool windowShown: true

    readonly property bool active: root.visible && root.windowShown
    property bool cavaConsumerActive: false
    readonly property int bars: Math.max(16, Math.min(72, Math.floor(root.width / Math.max(12, root.width * 0.014))))
    readonly property real gap: Math.max(1, root.width * 0.003)
    readonly property real barW: Math.max(2, (root.width - root.s(24) - (root.bars - 1) * root.gap) / root.bars)
    readonly property int peak: {
        let m = 0;
        let lv = root.levels || [];
        for (let i = 0; i < lv.length; i++) m = Math.max(m, lv[i] || 0);
        return Math.round(m * 100);
    }
    readonly property var levels: {
        let src = Cava.barLevels || [];
        let out = [];
        let n = root.bars;
        for (let i = 0; i < n; i++) {
            let pos = n <= 1 ? 0 : (i / (n - 1)) * Math.max(0, src.length - 1);
            let a = Math.floor(pos);
            let b = Math.min(src.length - 1, a + 1);
            let v = (src[a] || 0) + ((src[b] || 0) - (src[a] || 0)) * (pos - a);
            let edge = Math.sin((i / Math.max(1, n - 1)) * Math.PI);
            out.push(Math.max(0, Math.min(1, v * (0.45 + edge * 0.55))));
        }
        return out;
    }

    function syncCava() {
        let want = root.active;
        if (want === root.cavaConsumerActive)
            return;
        if (want) Cava.registerConsumer();
        else Cava.unregisterConsumer();
        root.cavaConsumerActive = want;
    }

    onActiveChanged: root.syncCava()
    Component.onCompleted: root.syncCava()
    Component.onDestruction: if (root.cavaConsumerActive) Cava.unregisterConsumer()

    Rectangle {
        anchors.fill: parent
        radius: 2
        color: "#0a0a0b"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.16)
    }
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
        color: Theme.red
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(12, Math.min(20, height * 0.10))
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "SIGNAL"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(8, Math.min(11, height * 0.06))
                font.weight: Font.Bold
                font.letterSpacing: 1.5
                color: Theme.text
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "HISTOGRAM  ·  PEAK " + root.peak + "%"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(7, Math.min(9, height * 0.045))
                font.letterSpacing: 1.0
                color: Theme.subtext0
            }
            Text {
                text: "●"
                font.family: Theme.fontFamily
                font.pixelSize: 8
                color: Theme.red
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.12)
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 0
                anchors.rightMargin: 0
                height: parent.height - root.s(18)
                spacing: root.gap

                Repeater {
                    model: root.bars
                    delegate: Item {
                        width: root.barW
                        height: parent.height
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: Math.max(2, (root.levels[index] || 0) * parent.height)
                            color: root.levels[index] > 0.75 ? Theme.red : Theme.text
                            opacity: 0.30 + Math.min(0.70, (root.levels[index] || 0) * 0.70)
                            Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        Rectangle {
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 1
                            height: Math.max(2, (root.levels[index] || 0) * parent.height)
                            color: Qt.rgba(1, 1, 1, 0.12)
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.peak === 0
                text: "AUDIO IDLE"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(8, Math.min(10, root.height * 0.05))
                font.letterSpacing: 1.2
                color: Theme.overlay0
            }

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: root.s(14)
                Repeater {
                    model: 5
                    delegate: Text {
                        width: parent.width / 5
                        text: (index * 20) + "Hz"
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.max(7, Math.min(9, height * 0.55))
                        color: Theme.overlay0
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignBottom
                    }
                }
            }
        }
    }

    function s(v) { return Math.max(1, Math.round(v * Math.max(0.7, Math.min(1.4, root.width / 700)))); }
}
