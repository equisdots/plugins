import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 180
    property real minHeight: 200
    property real maxWidth: 620
    property real maxHeight: 720
    property real minAspect: 0.7
    property real maxAspect: 1.2
    property bool isRound: false
    property bool windowShown: true

    property var now: new Date()
    readonly property int year: root.now.getFullYear()
    readonly property int month: root.now.getMonth()
    readonly property int today: root.now.getDate()
    readonly property var weekNames: ["S", "M", "T", "W", "T", "F", "S"]
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property int firstWeekday: new Date(root.year, root.month, 1).getDay()
    readonly property int daysInMonth: new Date(root.year, root.month + 1, 0).getDate()
    readonly property var cells: {
        let out = [];
        for (let i = 0; i < root.firstWeekday; i++) out.push(0);
        for (let d = 1; d <= root.daysInMonth; d++) out.push(d);
        while (out.length % 7 !== 0) out.push(0);
        return out;
    }

    Timer {
        interval: 60000
        running: root.windowShown
        repeat: true
        onTriggered: root.now = new Date()
    }

    Rectangle {
        anchors.fill: parent
        radius: Math.min(width, height) * 0.13
        color: "#fbfbfd"
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.08)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(10, Math.min(20, width * 0.075))
        spacing: Math.max(2, height * 0.015)

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.monthNames[root.month].toUpperCase()
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(9, Math.min(14, height * 0.045))
                font.weight: Font.Bold
                font.letterSpacing: 1.4
                color: "#ff3b30"
            }
            Item { Layout.fillWidth: true }
            Text {
                text: String(root.year)
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(9, Math.min(12, height * 0.035))
                color: "#86868b"
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2
            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: parent.width * 0.36
                spacing: -4
                Text {
                    text: String(root.today)
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.min(parent.height * 0.95, width * 0.75)
                    font.weight: Font.Black
                    color: "#1d1d1f"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: Qt.formatDate(root.now, "dddd")
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.max(9, Math.min(13, height * 0.038))
                    color: "#86868b"
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(14, height * 0.05)
                    spacing: 0
                    Repeater {
                        model: root.weekNames
                        delegate: Text {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: modelData
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.max(7, Math.min(10, height * 0.026))
                            color: "#86868b"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
                Grid {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 7
                    rows: Math.ceil(root.cells.length / 7)
                    readonly property real cw: width / 7
                    readonly property real ch: height / Math.max(1, rows)
                    Repeater {
                        model: root.cells
                        delegate: Item {
                            required property var modelData
                            width: Grid.cw
                            height: Grid.ch
                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, parent.height) * 0.72
                                height: width
                                radius: width / 2
                                visible: modelData > 0
                                color: modelData === root.today ? "#ff3b30" : "transparent"
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: modelData > 0
                                text: modelData > 0 ? String(modelData) : ""
                                font.family: Theme.fontFamily
                                font.pixelSize: Math.max(7, Math.min(11, parent.height * 0.55))
                                font.weight: modelData === root.today ? Font.Bold : Font.Normal
                                color: modelData === root.today ? "#ffffff" : "#1d1d1f"
                            }
                        }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(0, 0, 0, 0.08) }
        Text {
            Layout.fillWidth: true
            text: "TODAY  ·  " + Qt.formatDate(root.now, "dddd d MMMM").toUpperCase()
            font.family: Theme.fontFamily
            font.pixelSize: Math.max(8, Math.min(10, height * 0.028))
            font.letterSpacing: 0.8
            color: "#86868b"
            elide: Text.ElideRight
        }
    }
}
