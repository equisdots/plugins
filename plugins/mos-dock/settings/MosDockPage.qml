import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.core

// mos Dock settings (Plugins -> mos Dock). This page owns the editable
// launcher list; it writes only to the plugin's own settings section.
Item {
    id: root

    property var bar: null
    property var host: null

    readonly property var defaultApps: ([
        { label: "Finder", icon: "org.gnome.Nautilus", glyph: "󰉋", exec: "nautilus", match: ["nautilus", "org.gnome.Nautilus"] },
        { label: "Safari", icon: "brave-browser", glyph: "󰖟", exec: "brave", match: ["brave", "brave-browser"] },
        { label: "Mail", icon: "thunderbird", glyph: "󰇮", exec: "thunderbird", match: ["thunderbird"] },
        { label: "Music", icon: "spotify", glyph: "󰝚", exec: "spotify", match: ["spotify"] },
        { label: "Terminal", icon: "kitty", glyph: "󰆍", exec: "kitty", match: ["kitty"] },
        { label: "Settings", icon: "preferences-system", glyph: "󰒓", exec: "~/.config/hypr/scripts/qs_manager.sh toggle settings", match: [] }
    ])

    readonly property var cfg: {
        if (root.host && root.host.settings) {
            root.host.settings.revision;
            return root.host.settings.section;
        }
        Config.rev;
        let d = Config.rawSettings ? Config.rawSettings["mos-dock"] : null;
        return (d && typeof d === "object") ? d : ({});
    }

    property var dApps: []

    function set(key, value) {
        if (root.host && root.host.settings) {
            root.host.settings.set(key, value);
        } else {
            let base = (Config.rawSettings["mos-dock"] && typeof Config.rawSettings["mos-dock"] === "object")
                ? Config.rawSettings["mos-dock"] : {};
            Config.setSetting("mos-dock", Object.assign({}, base, { [key]: value }));
        }
    }

    function cleanApp(a) {
        let match = (a && a.match);
        if (typeof match === "string") match = [match];
        else if (!Array.isArray(match)) match = [];
        return {
            label: String((a && a.label) || ""),
            icon: String((a && a.icon) || ""),
            glyph: String((a && a.glyph) || "󰀻"),
            exec: String((a && a.exec) || ""),
            match: match.map(String)
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
            let base = (Config.rawSettings["mos-dock"] && typeof Config.rawSettings["mos-dock"] === "object")
                ? Config.rawSettings["mos-dock"] : {};
            Config.setSetting("mos-dock", Object.assign({}, base, { apps: clean }));
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
    property string newIcon: ""
    property string newGlyph: "󰀻"
    property string newExec: ""

    function addApp() {
        let cmd = root.newExec.trim();
        if (cmd === "") return;
        let list = root.dApps.slice();
        list.push({
            label: root.newLabel.trim() !== "" ? root.newLabel.trim() : cmd.split("/").pop().split(" ")[0],
            icon: root.newIcon.trim(),
            glyph: root.newGlyph.trim() !== "" ? root.newGlyph.trim() : "󰀻",
            exec: cmd,
            match: []
        });
        root.persistApps(list);
        root.newLabel = "";
        root.newIcon = "";
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

    component Stepper: Rectangle {
        id: step
        property string label: ""
        property string value: ""
        signal dec()
        signal inc()
        Layout.fillWidth: true
        implicitHeight: 42
        color: Theme.surfaceContainerLow
        border.width: 1; border.color: Theme.outlineVariant; radius: 0
        Text {
            anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
            text: step.label; font.family: "Hack Nerd Font"; font.pixelSize: 10; color: Theme.text
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter
            spacing: 5
            FlatButton { text: "−"; onClicked: step.dec() }
            Text { width: 48; height: 24; text: step.value; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.family: "Hack Nerd Font"; font.pixelSize: 9; color: Theme.text }
            FlatButton { text: "+"; onClicked: step.inc() }
        }
    }

    component ToggleRow: Rectangle {
        id: toggleRow
        property string label: ""
        property bool checked: false
        signal toggled(bool value)
        Layout.fillWidth: true
        implicitHeight: 42
        color: Theme.surfaceContainerLow
        border.width: 1; border.color: Theme.outlineVariant; radius: 0
        Text {
            anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
            text: toggleRow.label; font.family: "Hack Nerd Font"; font.pixelSize: 10; color: Theme.text
        }
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
            width: 34; height: 18; radius: 9
            color: toggleRow.checked ? Theme.text : Theme.surfaceContainerHigh
            Rectangle {
                width: 14; height: 14; radius: 7
                x: toggleRow.checked ? parent.width - width - 2 : 2
                anchors.verticalCenter: parent.verticalCenter
                color: toggleRow.checked ? Theme.base : Theme.text
                Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: toggleRow.toggled(!toggleRow.checked) }
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
                Text { width: 54; text: "ICON"; font.family: "Hack Nerd Font"; font.pixelSize: 9; color: Theme.subtext0 }
                AppField {
                    text: card.app.icon || ""
                    labelText: "System icon name or absolute path (empty = glyph)"
                    onEditingFinished: root.updateApp(card.appIndex, "icon", text)
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
                text: "MOS DOCK"
                font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: 18
                color: Theme.text
            }
            Text {
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                text: "Independent macOS Golden Gate-style bottom dock: Liquid Glass capsule, real app icons, magnification, hover labels, running dots, separator and Downloads/Trash. Each launcher can use a system icon name (or absolute path); an empty icon falls back to its Nerd Font glyph."
                font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0
            }

            Text { text: "APPEARANCE"; font.family: "Hack Nerd Font"; font.pixelSize: 9; font.letterSpacing: 1.6; color: Theme.subtext0; topPadding: 4 }
            Stepper {
                label: "Icon size"; value: (Number(root.cfg.iconSize) || 48) + " px"
                onDec: root.set("iconSize", Math.max(28, (Number(root.cfg.iconSize) || 48) - 2))
                onInc: root.set("iconSize", Math.min(96, (Number(root.cfg.iconSize) || 48) + 2))
            }
            Stepper {
                label: "Spacing"; value: (Number(root.cfg.spacing) || 8) + " px"
                onDec: root.set("spacing", Math.max(0, (Number(root.cfg.spacing) || 8) - 1))
                onInc: root.set("spacing", Math.min(30, (Number(root.cfg.spacing) || 8) + 1))
            }
            Stepper {
                label: "Dock opacity"; value: Math.round((Number(root.cfg.opacity) || 0.72) * 100) + "%"
                onDec: root.set("opacity", Math.max(0.15, Math.round(((Number(root.cfg.opacity) || 0.72) - 0.05) * 100) / 100))
                onInc: root.set("opacity", Math.min(1.0, Math.round(((Number(root.cfg.opacity) || 0.72) + 0.05) * 100) / 100))
            }
            ToggleRow {
                label: "Magnification"; checked: root.cfg.magnify !== false
                onToggled: (v) => root.set("magnify", v)
            }
            ToggleRow {
                label: "Show app labels"; checked: root.cfg.showLabels === true
                onToggled: (v) => root.set("showLabels", v)
            }
            ToggleRow {
                label: "Liquid Glass"; checked: root.cfg.glass !== false
                onToggled: (v) => root.set("glass", v)
            }
            ToggleRow {
                label: "Running-app dots"; checked: root.cfg.showIndicators !== false
                onToggled: (v) => root.set("showIndicators", v)
            }
            ToggleRow {
                label: "Bounce on launch"; checked: root.cfg.bounce !== false
                onToggled: (v) => root.set("bounce", v)
            }
            ToggleRow {
                label: "Show Downloads"; checked: root.cfg.showDownloads !== false
                onToggled: (v) => root.set("showDownloads", v)
            }
            ToggleRow {
                label: "Show Trash"; checked: root.cfg.showTrash !== false
                onToggled: (v) => root.set("showTrash", v)
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
                        AppField { Layout.fillWidth: true; text: root.newIcon; labelText: "Icon name or /path"; onTextEdited: root.newIcon = text }
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
