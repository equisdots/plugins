import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.core

// Samurai Dock settings (Plugins -> Samurai Dock). This page owns the editable
// launcher list; it writes only to the plugin's own settings section.
Item {
    id: root

    property var bar: null
    property var host: null

    readonly property var defaultApps: ([
        { label: "TERM", glyph: "󰆍", exec: "kitty" },
        { label: "FILES", glyph: "󰉋", exec: "nautilus" },
        { label: "WEB", glyph: "󰖟", exec: "brave" },
        { label: "CODE", glyph: "󰅩", exec: "code" },
        { label: "MUSIC", glyph: "󰝚", exec: "spotify" }
    ])

    readonly property var cfg: {
        if (root.host && root.host.settings) return root.host.settings.section;
        Config.rev;
        let d = Config.rawSettings ? Config.rawSettings["samurai-dock"] : null;
        return (d && typeof d === "object") ? d : ({});
    }

    property var dApps: []

    function cleanApp(a) {
        return {
            label: String((a && a.label) || ""),
            glyph: String((a && a.glyph) || "󰀻"),
            exec: String((a && a.exec) || "")
        };
    }

    function syncFromConfig() {
        let list = Array.isArray(root.cfg.apps) ? root.cfg.apps : root.defaultApps;
        root.dApps = list.map(function (a) { return root.cleanApp(a); });
    }
    Component.onCompleted: root.syncFromConfig()
    onHostChanged: if (root.host) root.syncFromConfig()

    function persistApps(list) {
        let clean = list.map(root.cleanApp).filter(function (a) { return a.exec.trim() !== ""; });
        root.dApps = clean;
        if (root.host && root.host.settings) {
            root.host.settings.set("apps", clean);
        } else {
            let base = (Config.rawSettings["samurai-dock"] && typeof Config.rawSettings["samurai-dock"] === "object")
                ? Config.rawSettings["samurai-dock"] : {};
            Config.setSetting("samurai-dock", Object.assign({}, base, { apps: clean }));
        }
    }

    function updateApp(i, key, value) {
        if (i < 0 || i >= root.dApps.length) return;
        let list = root.dApps.map(function (a) { return root.cleanApp(a); });
        list[i][key] = String(value);
        root.persistApps(list);
    }

    function removeApp(i) {
        let list = root.dApps.slice();
        if (i < 0 || i >= list.length) return;
        list.splice(i, 1);
        root.persistApps(list);
    }

    function moveApp(i, delta) {
        let list = root.dApps.slice();
        let j = i + delta;
        if (i < 0 || i >= list.length || j < 0 || j >= list.length) return;
        let tmp = list[i]; list[i] = list[j]; list[j] = tmp;
        root.persistApps(list);
    }

    property string newLabel: ""
    property string newGlyph: "󰀻"
    property string newExec: ""

    function addApp() {
        let cmd = root.newExec.trim();
        if (cmd === "") return;
        let list = root.dApps.slice();
        list.push({
            label: root.newLabel.trim() !== "" ? root.newLabel.trim() : cmd.split("/").pop().split(" ")[0].toUpperCase(),
            glyph: root.newGlyph.trim() !== "" ? root.newGlyph.trim() : "󰀻",
            exec: cmd
        });
        root.persistApps(list);
        root.newLabel = "";
        root.newGlyph = "󰀻";
        root.newExec = "";
    }

    component FlatButton: Rectangle {
        id: btn
        property string text: ""
        signal clicked()
        width: 24; height: 24
        color: mouse.containsMouse ? Theme.surfaceContainerHigh : "transparent"
        border.width: 1; border.color: Theme.outlineVariant; radius: 0
        Text {
            anchors.centerIn: parent
            text: btn.text
            font.family: "Hack Nerd Font"; font.pixelSize: 11
            color: mouse.containsMouse ? Theme.text : Theme.subtext0
        }
        MouseArea {
            id: mouse; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    component AppField: TextField {
        property string labelText: ""
        font.family: "Hack Nerd Font"; font.pixelSize: 11
        color: Theme.text
        placeholderText: labelText
        Layout.fillWidth: true
        Layout.preferredHeight: 30
        leftPadding: 8; rightPadding: 8
        background: Rectangle {
            color: Theme.surfaceContainerLow
            border.width: 1; border.color: parent.activeFocus ? Theme.text : Theme.outlineVariant
            radius: 0
        }
    }

    component AppEditor: Rectangle {
        id: card
        property int appIndex: 0
        property var app: ({})
        Layout.fillWidth: true
        implicitHeight: cardCol.implicitHeight + 16
        color: Theme.surfaceContainerLow
        border.width: 1; border.color: Theme.outlineVariant; radius: 0

        ColumnLayout {
            id: cardCol
            anchors.fill: parent
            anchors.margins: 8
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "APP " + ("0" + (card.appIndex + 1)).slice(-2)
                    font.family: "Hack Nerd Font"; font.pixelSize: 9
                    font.letterSpacing: 1.2; color: Theme.subtext0
                }
                Item { Layout.fillWidth: true }
                FlatButton { text: "↑"; onClicked: root.moveApp(card.appIndex, -1) }
                FlatButton { text: "↓"; onClicked: root.moveApp(card.appIndex, 1) }
                FlatButton { text: "×"; onClicked: root.removeApp(card.appIndex) }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Text { width: 54; text: "GLYPH"; font.family: "Hack Nerd Font"; font.pixelSize: 9; color: Theme.subtext0 }
                AppField {
                    text: card.app.glyph || ""
                    labelText: "Nerd Font glyph"
                    onEditingFinished: root.updateApp(card.appIndex, "glyph", text)
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Text { width: 54; text: "LABEL"; font.family: "Hack Nerd Font"; font.pixelSize: 9; color: Theme.subtext0 }
                AppField {
                    text: card.app.label || ""
                    labelText: "Short label"
                    onEditingFinished: root.updateApp(card.appIndex, "label", text)
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Text { width: 54; text: "EXEC"; font.family: "Hack Nerd Font"; font.pixelSize: 9; color: Theme.subtext0 }
                AppField {
                    text: card.app.exec || ""
                    labelText: "Command (runs through bash -lc)"
                    onEditingFinished: root.updateApp(card.appIndex, "exec", text)
                }
            }
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: pageCol.implicitHeight + 24

        ColumnLayout {
            id: pageCol
            x: 12; y: 12
            width: flick.width - 24
            spacing: 10

            Text {
                text: "SAMURAI DOCK"
                font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: 18
                color: Theme.text
            }
            Text {
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                text: "Independent bottom dock in the Samurai design language. The launcher list below is live: label, Nerd Font glyph and the command opened by each icon."
                font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 48
                color: Theme.surfaceContainerLow
                border.width: 1; border.color: Theme.outlineVariant; radius: 0
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                    Text { text: "APPS / LAUNCHERS"; font.family: "Hack Nerd Font"; font.pixelSize: 9; font.letterSpacing: 1.8; color: Theme.text }
                    Item { Layout.fillWidth: true }
                    Text { text: String(root.dApps.length) + " ITEMS"; font.family: "Hack Nerd Font"; font.pixelSize: 9; color: Theme.subtext0 }
                }
            }

            Repeater {
                model: root.dApps
                delegate: AppEditor {
                    appIndex: index
                    app: modelData
                }
            }

            Item { Layout.preferredHeight: 4 }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: addCol.implicitHeight + 16
                color: Theme.surfaceContainerLow
                border.width: 1; border.color: Theme.outlineVariant; radius: 0
                ColumnLayout {
                    id: addCol
                    anchors.fill: parent; anchors.margins: 8; spacing: 5
                    Text { text: "ADD LAUNCHER"; font.family: "Hack Nerd Font"; font.pixelSize: 9; font.letterSpacing: 1.4; color: Theme.text }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 6
                        AppField { Layout.preferredWidth: 72; Layout.fillWidth: false; text: root.newGlyph; labelText: "Glyph"; onTextEdited: root.newGlyph = text }
                        AppField { Layout.fillWidth: true; text: root.newLabel; labelText: "Label"; onTextEdited: root.newLabel = text }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 6
                        AppField { Layout.fillWidth: true; text: root.newExec; labelText: "Command, e.g. kitty -e btop"; onTextEdited: root.newExec = text }
                        Rectangle {
                            width: 72; height: 30; radius: 0
                            color: addMouse.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                            border.width: 1; border.color: Theme.outlineVariant
                            Text { anchors.centerIn: parent; text: "ADD"; font.family: "Hack Nerd Font"; font.pixelSize: 9; font.letterSpacing: 1.2; color: Theme.text }
                            MouseArea { id: addMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.addApp() }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                text: "Edits are saved to the plugin settings immediately. Commands are executed with bash -lc, so arguments, pipes and ~ are supported."
                font.family: "Hack Nerd Font"; font.pixelSize: 9; color: Theme.subtext0
            }
        }
    }
}
