import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

Item {
    id: root
    anchors.fill: parent

    property var bar: null
    property var host: null

    readonly property var defaultApps: ([
        { label: "Terminal", glyph: "󰆍", exec: "kitty" },
        { label: "Files", glyph: "󰉋", exec: "nautilus" },
        { label: "Browser", glyph: "󰖟", exec: "brave" },
        { label: "Code", glyph: "󰅩", exec: "code" }
    ])

    readonly property string settingsPath: {
        if (root.host && root.host.settingsFilePath)
            return String(root.host.settingsFilePath);
        return Quickshell.env("HOME") + "/.config/hypr/plugins/w11/settings.json";
    }
    readonly property string settingsScript: String(Qt.resolvedUrl("../scripts/settings-set.sh")).replace("file://", "")
    property var cfg: ({})
    property string dLayout: "full"
    property string dTheme: "windows11"
    property bool dIconPalette: false
    property int dBarHeight: 48
    property real dOpacity: 0.92
    property bool dShowSearch: true
    property bool dShowClock: true
    property bool dShowWeather: true
    property bool dShowBattery: true
    property bool dShowUser: true

    function applyCfgValues() {
        dLayout = String(root.cfg.layoutMode || "full");
        dTheme = String(root.cfg.themeMode || "windows11");
        dIconPalette = root.cfg.iconPalette === true;
        dBarHeight = Math.max(38, Math.min(68, Number(root.cfg.barHeight) || 48));
        dOpacity = Math.max(0.35, Math.min(1.0, Number(root.cfg.opacity) || 0.92));
        dShowSearch = root.cfg.showSearch !== false;
        dShowClock = root.cfg.showClock !== false;
        dShowWeather = root.cfg.showWeather !== false;
        dShowBattery = root.cfg.showBattery !== false;
        dShowUser = root.cfg.showUser !== false;
    }

    FileView {
        id: cfgFile
        path: root.settingsPath
        watchChanges: true
        onLoaded: root.parseCfg(cfgFile.text())
        onFileChanged: root.parseCfg(cfgFile.text())
    }

    function parseCfg(text) {
        try {
            let d = JSON.parse(text || "{}");
            root.cfg = (d && typeof d.w11 === "object" && d.w11 !== null) ? d.w11 : ({});
        } catch (e) {
            root.cfg = ({});
        }
    }
    property double writeGuardUntil: 0
    onCfgChanged: {
        // Ignore a late/old file read while a click is being persisted; the
        // controls must follow the click immediately.
        if (Date.now() < root.writeGuardUntil) {
            // Keep the local editor state authoritative while a click is being
            // persisted. Syncing here would restore the stale FileView snapshot
            // and force the user to close/reopen the panel after every pin.
            return;
        }
        root.applyCfgValues();
        root.syncApps();
        if (!root.menuLocalDirty) root.syncMenuApps();
    }

    property var dApps: []
    property var dMenuApps: []
    property bool menuLocalDirty: false
    property string newLabel: ""
    property string newGlyph: "󰀻"
    property string newExec: ""
    property string menuSearch: ""
    property bool menuPickerOpen: false
    readonly property var menuResults: {
        let q = root.menuSearch.trim().toLowerCase();
        let model = DesktopEntries.applications;
        let all = model ? model.values : [];
        let out = [];
        for (let i = 0; i < all.length; i++) {
            let a = all[i] || {};
            let name = String(a.name || "").toLowerCase();
            let id = String(a.id || "").toLowerCase();
            if (q === "" || name.indexOf(q) >= 0 || id.indexOf(q) >= 0) out.push(a);
            if (out.length >= 48) break;
        }
        return out;
    }

    function s(v) { return root.bar && root.bar.s ? root.bar.s(v) : v; }
    function set(key, value) {
        root.writeGuardUntil = Date.now() + 1200;
        if (key === "layoutMode") root.dLayout = String(value);
        else if (key === "themeMode") root.dTheme = String(value);
        else if (key === "iconPalette") root.dIconPalette = value === true;
        else if (key === "barHeight") root.dBarHeight = Math.max(38, Math.min(68, Number(value) || 48));
        else if (key === "opacity") root.dOpacity = Math.max(0.35, Math.min(1.0, Number(value) || 0.92));
        else if (key === "showSearch") root.dShowSearch = value === true;
        else if (key === "showClock") root.dShowClock = value === true;
        else if (key === "showWeather") root.dShowWeather = value === true;
        else if (key === "showBattery") root.dShowBattery = value === true;
        else if (key === "showUser") root.dShowUser = value === true;
        if (root.host && root.host.settings) root.host.settings.set(key, value);
        else Quickshell.execDetached(["bash", root.settingsScript, root.settingsPath, key, JSON.stringify(value)]);
    }
    function cleanApp(a) {
        return {
            label: String((a && a.label) || ""),
            glyph: String((a && a.glyph) || "󰀻"),
            exec: String((a && a.exec) || (a && a.execString) || "")
        };
    }
    function syncApps() {
        let list = Array.isArray(root.cfg.apps) ? root.cfg.apps : root.defaultApps;
        root.dApps = list.map(function (a) { return root.cleanApp(a); });
    }
    function cleanMenuApp(a) {
        return {
            id: String((a && a.id) || ""),
            name: String((a && a.name) || (a && a.label) || ""),
            icon: String((a && a.icon) || ""),
            exec: String((a && a.exec) || (a && a.execString) || "")
        };
    }
    function syncMenuApps() {
        let list = Array.isArray(root.cfg.menuApps) ? root.cfg.menuApps : [];
        root.dMenuApps = list.map(function (a) { return root.cleanMenuApp(a); });
    }
    function persistMenuApps(list) {
        let clean = list.map(root.cleanMenuApp).filter(function (a) { return a.exec.trim() !== ""; });
        root.menuLocalDirty = true;
        root.dMenuApps = clean;
        root.set("menuApps", clean);
    }
    function addMenuApp(a) {
        let clean = root.cleanMenuApp(a);
        if (clean.exec.trim() === "") return;
        let list = root.dMenuApps.slice();
        if (!list.some(function (x) { return x.exec === clean.exec; })) list.push(clean);
        root.persistMenuApps(list);
    }
    function removeMenuApp(i) {
        let list = root.dMenuApps.slice();
        if (i < 0 || i >= list.length) return;
        list.splice(i, 1);
        root.persistMenuApps(list);
    }
    function menuIcon(a) {
        let ic = String((a && a.icon) || "").trim();
        if (ic === "") return "";
        return ic.charAt(0) === "/" ? "file://" + ic : "image://icon/" + ic;
    }
    Component.onCompleted: {
        root.syncApps();
        root.syncMenuApps();
    }
    onHostChanged: if (root.host) { root.syncApps(); if (!root.menuLocalDirty) root.syncMenuApps(); }
    function persistApps(list) {
        let clean = list.map(root.cleanApp).filter(function (a) { return a.exec.trim() !== ""; });
        root.dApps = clean;
        root.set("apps", clean);
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
    function addApp() {
        let cmd = root.newExec.trim();
        if (cmd === "") return;
        let list = root.dApps.slice();
        list.push({
            label: root.newLabel.trim() !== "" ? root.newLabel.trim() : cmd.split("/").pop().split(" ")[0],
            glyph: root.newGlyph.trim() !== "" ? root.newGlyph.trim() : "󰀻",
            exec: cmd
        });
        root.persistApps(list);
        root.newLabel = "";
        root.newGlyph = "󰀻";
        root.newExec = "";
    }

    component SectionTitle: Text {
        text: ""
        font.family: "Hack Nerd Font"
        font.pixelSize: root.s(9)
        font.letterSpacing: 1.6
        color: Theme.subtext0
        topPadding: root.s(4)
    }

    component FlatButton: Rectangle {
        id: btn
        property string text: ""
        signal clicked()
        width: root.s(28); height: root.s(28)
        color: mouse.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer
        border.width: 1; border.color: Theme.outlineVariant
        radius: root.s(Theme.radiusSm)
        Text {
            anchors.centerIn: parent
            text: btn.text
            font.family: "Hack Nerd Font"; font.pixelSize: root.s(11)
            color: Theme.text
        }
        MouseArea {
            id: mouse; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    component Field: TextField {
        property string placeholder: ""
        font.family: "Hack Nerd Font"; font.pixelSize: root.s(11)
        color: Theme.text
        placeholderText: placeholder
        placeholderTextColor: Theme.overlay0
        Layout.fillWidth: true
        Layout.preferredHeight: root.s(30)
        leftPadding: root.s(8); rightPadding: root.s(8)
        background: Rectangle {
            color: Theme.surfaceContainer
            border.width: 1
            border.color: parent.activeFocus ? Theme.mauve : Theme.outlineVariant
            radius: root.s(Theme.radiusSm)
        }
    }

    component ToggleRow: Rectangle {
        id: row
        property string label: ""
        property bool checked: false
        signal toggled(bool value)
        Layout.fillWidth: true
        implicitHeight: root.s(42)
        color: Theme.surfaceContainerLow
        border.width: 1; border.color: Theme.outlineVariant; radius: root.s(Theme.radiusLg)
        Text {
            anchors.left: parent.left; anchors.leftMargin: root.s(10)
            anchors.verticalCenter: parent.verticalCenter
            text: row.label
            font.family: "Hack Nerd Font"; font.pixelSize: root.s(10); color: Theme.text
        }
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: root.s(10)
            anchors.verticalCenter: parent.verticalCenter
            width: root.s(34); height: root.s(18); radius: root.s(9)
            color: row.checked ? Theme.mauve : Theme.surfaceContainerHigh
            Rectangle {
                width: root.s(14); height: root.s(14); radius: root.s(7)
                x: row.checked ? parent.width - width - root.s(2) : root.s(2)
                anchors.verticalCenter: parent.verticalCenter
                color: row.checked ? Theme.base : Theme.text
                Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }
        }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: row.toggled(!row.checked)
        }
    }

    component ChoiceRow: Rectangle {
        id: choice
        property string label: ""
        property var options: []
        property string selectedValue: ""
        signal chosen(string next)
        Layout.fillWidth: true
        implicitHeight: root.s(46)
        color: Theme.surfaceContainerLow
        border.width: 1; border.color: Theme.outlineVariant; radius: root.s(Theme.radiusLg)
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.s(10); anchors.rightMargin: root.s(6)
            Text {
                text: choice.label
                font.family: "Hack Nerd Font"; font.pixelSize: root.s(10); color: Theme.text
                Layout.fillWidth: true
            }
            Repeater {
                model: choice.options
                delegate: Rectangle {
                    required property var modelData
                    width: root.s(76); height: root.s(28); radius: root.s(Theme.radiusFull)
                    color: modelData.value === choice.selectedValue ? Theme.mauve : Theme.surfaceContainerHigh
                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.family: "Hack Nerd Font"; font.pixelSize: root.s(9)
                        color: modelData.value === choice.selectedValue ? Theme.base : Theme.text
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: choice.chosen(modelData.value)
                    }
                }
            }
        }
    }

    component StepperRow: Rectangle {
        id: step
        property string label: ""
        property string value: ""
        signal dec()
        signal inc()
        Layout.fillWidth: true
        implicitHeight: root.s(42)
        color: Theme.surfaceContainerLow
        border.width: 1; border.color: Theme.outlineVariant; radius: root.s(Theme.radiusLg)
        Text {
            anchors.left: parent.left; anchors.leftMargin: root.s(10)
            anchors.verticalCenter: parent.verticalCenter
            text: step.label
            font.family: "Hack Nerd Font"; font.pixelSize: root.s(10); color: Theme.text
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: root.s(6)
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.s(5)
            FlatButton { text: "−"; onClicked: step.dec() }
            Text {
                width: root.s(54); height: root.s(24)
                text: step.value; horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: "Hack Nerd Font"; font.pixelSize: root.s(9); color: Theme.text
            }
            FlatButton { text: "+"; onClicked: step.inc() }
        }
    }

    component AppEditor: Rectangle {
        id: card
        property int appIndex: 0
        property var app: ({})
        Layout.fillWidth: true
        implicitHeight: cardCol.implicitHeight + root.s(16)
        color: Theme.surfaceContainerLow
        border.width: 1; border.color: Theme.outlineVariant; radius: root.s(Theme.radiusLg)
        ColumnLayout {
            id: cardCol
            anchors.fill: parent
            anchors.margins: root.s(8)
            spacing: root.s(5)
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "APP " + ("0" + (card.appIndex + 1)).slice(-2)
                    font.family: "Hack Nerd Font"; font.pixelSize: root.s(9)
                    font.letterSpacing: 1.2; color: Theme.subtext0
                }
                Item { Layout.fillWidth: true }
                FlatButton { text: "↑"; onClicked: root.moveApp(card.appIndex, -1) }
                FlatButton { text: "↓"; onClicked: root.moveApp(card.appIndex, 1) }
                FlatButton { text: "×"; onClicked: root.removeApp(card.appIndex) }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: root.s(6)
                Text { width: root.s(54); text: "GLYPH"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(9); color: Theme.subtext0 }
                Field {
                    text: card.app.glyph || ""
                    placeholder: "Nerd Font glyph"
                    onEditingFinished: root.updateApp(card.appIndex, "glyph", text)
                }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: root.s(6)
                Text { width: root.s(54); text: "LABEL"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(9); color: Theme.subtext0 }
                Field {
                    text: card.app.label || ""
                    placeholder: "Short label"
                    onEditingFinished: root.updateApp(card.appIndex, "label", text)
                }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: root.s(6)
                Text { width: root.s(54); text: "EXEC"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(9); color: Theme.subtext0 }
                Field {
                    text: card.app.exec || ""
                    placeholder: "Command (bash -lc)"
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
        contentHeight: pageCol.implicitHeight + root.s(24)

        ColumnLayout {
            id: pageCol
            x: root.s(12); y: root.s(12)
            width: flick.width - root.s(24)
            spacing: root.s(10)

            Text {
                text: "W11"
                font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: root.s(18)
                color: Theme.text
            }
            Text {
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                text: "Independent Windows 11-inspired taskbar. Choose a full-width bar or a compact centred dock, switch between Windows 11 styling and the active palette, and edit the launchers that appear in the bar."
                font.family: "Hack Nerd Font"; font.pixelSize: root.s(11); color: Theme.subtext0
            }

            SectionTitle { text: "LAYOUT" }
            ChoiceRow {
                label: "Taskbar"
                options: [
                    { value: "full", label: "Full width" },
                    { value: "compact", label: "Compact dock" }
                ]
                selectedValue: root.dLayout
                onChosen: (v) => root.set("layoutMode", v)
            }
            StepperRow {
                label: "Bar height"
                value: root.dBarHeight + " px"
                onDec: root.set("barHeight", Math.max(38, root.dBarHeight - 2))
                onInc: root.set("barHeight", Math.min(68, root.dBarHeight + 2))
            }
            StepperRow {
                label: "Opacity"
                value: Math.round(root.dOpacity * 100) + "%"
                onDec: root.set("opacity", Math.max(0.35, Math.round((root.dOpacity - 0.05) * 100) / 100))
                onInc: root.set("opacity", Math.min(1.0, Math.round((root.dOpacity + 0.05) * 100) / 100))
            }

            SectionTitle { text: "THEME" }
            ChoiceRow {
                label: "Style"
                options: [
                    { value: "windows11", label: "Windows 11" },
                    { value: "palette", label: "Palette" }
                ]
                selectedValue: root.dTheme
                onChosen: (v) => root.set("themeMode", v)
            }
            ToggleRow {
                label: "Tint launcher glyphs with the accent colour"
                checked: root.dIconPalette
                onToggled: (v) => root.set("iconPalette", v)
            }

            SectionTitle { text: "STATUS AREA" }
            ToggleRow { label: "Application search button"; checked: root.dShowSearch; onToggled: (v) => root.set("showSearch", v) }
            ToggleRow { label: "Clock and date"; checked: root.dShowClock; onToggled: (v) => root.set("showClock", v) }
            ToggleRow { label: "Weather temperature"; checked: root.dShowWeather; onToggled: (v) => root.set("showWeather", v) }
            ToggleRow { label: "Battery"; checked: root.dShowBattery; onToggled: (v) => root.set("showBattery", v) }
            ToggleRow { label: "User button"; checked: root.dShowUser; onToggled: (v) => root.set("showUser", v) }

            SectionTitle { text: "LAUNCHERS" }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: root.s(48)
                color: Theme.surfaceContainerLow
                border.width: 1; border.color: Theme.outlineVariant; radius: root.s(Theme.radiusLg)
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: root.s(10); anchors.rightMargin: root.s(10)
                    Text { text: "PINNED APPS"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(9); font.letterSpacing: 1.8; color: Theme.text }
                    Item { Layout.fillWidth: true }
                    Text { text: String(root.dApps.length) + " ITEMS"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(9); color: Theme.subtext0 }
                }
            }
            Repeater {
                model: root.dApps
                delegate: AppEditor { appIndex: index; app: modelData }
            }
            Item { Layout.preferredHeight: root.s(4) }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: addCol.implicitHeight + root.s(16)
                color: Theme.surfaceContainerLow
                border.width: 1; border.color: Theme.outlineVariant; radius: root.s(Theme.radiusLg)
                ColumnLayout {
                    id: addCol
                    anchors.fill: parent; anchors.margins: root.s(8); spacing: root.s(5)
                    Text { text: "ADD LAUNCHER"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(9); font.letterSpacing: 1.4; color: Theme.text }
                    RowLayout {
                        Layout.fillWidth: true; spacing: root.s(6)
                        Field { Layout.preferredWidth: root.s(74); Layout.fillWidth: false; text: root.newGlyph; placeholder: "Glyph"; onTextEdited: root.newGlyph = text }
                        Field { Layout.fillWidth: true; text: root.newLabel; placeholder: "Label"; onTextEdited: root.newLabel = text }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: root.s(6)
                        Field { Layout.fillWidth: true; text: root.newExec; placeholder: "Command, e.g. kitty"; onTextEdited: root.newExec = text }
                        FlatButton { text: "+"; onClicked: root.addApp() }
                    }
                }
            }

            SectionTitle { text: "START MENU APPS" }
            Text {
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                text: "Choose the applications pinned in the W11 start menu. Leave the list empty to show all installed applications."
                font.family: "Hack Nerd Font"; font.pixelSize: root.s(10); color: Theme.subtext0
            }
            Repeater {
                model: root.dMenuApps
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: root.s(44)
                    color: Theme.surfaceContainerLow
                    border.width: 1; border.color: Theme.outlineVariant; radius: root.s(Theme.radiusLg)
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: root.s(8); anchors.rightMargin: root.s(6)
                        spacing: root.s(8)
                        Image {
                            Layout.preferredWidth: root.s(24); Layout.preferredHeight: root.s(24)
                            source: root.menuIcon(modelData)
                            sourceSize: Qt.size(24, 24)
                            fillMode: Image.PreserveAspectFit
                            visible: source !== ""
                        }
                        Text {
                            visible: root.menuIcon(modelData) === ""
                            text: String(modelData.name || modelData.id || "").charAt(0).toUpperCase()
                            font.family: "Hack Nerd Font"; font.pixelSize: root.s(12); color: Theme.text
                            Layout.preferredWidth: root.s(24); horizontalAlignment: Text.AlignHCenter
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0
                            Text { text: String(modelData.name || modelData.id || ""); font.family: "Hack Nerd Font"; font.pixelSize: root.s(10); color: Theme.text; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text { text: String(modelData.exec || ""); font.family: "Hack Nerd Font"; font.pixelSize: root.s(8); color: Theme.subtext0; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                        FlatButton { text: "×"; onClicked: root.removeMenuApp(index) }
                    }
                }
            }
            Text {
                visible: root.dMenuApps.length === 0
                Layout.fillWidth: true
                text: "No pinned menu apps: showing every installed application."
                font.family: "Hack Nerd Font"; font.pixelSize: root.s(10); color: Theme.subtext0
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: root.s(38)
                color: Theme.surfaceContainerLow
                border.width: 1; border.color: Theme.outlineVariant; radius: root.s(Theme.radiusLg)
                Text {
                    anchors.left: parent.left; anchors.leftMargin: root.s(10); anchors.verticalCenter: parent.verticalCenter
                    text: root.menuPickerOpen ? "Hide installed applications" : "Add applications to the start menu"
                    font.family: "Hack Nerd Font"; font.pixelSize: root.s(10); color: Theme.text
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.menuPickerOpen = !root.menuPickerOpen;
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.menuPickerOpen
                spacing: root.s(5)
                Field {
                    Layout.fillWidth: true
                    text: root.menuSearch
                    placeholder: "Search installed applications…"
                    onTextEdited: root.menuSearch = text
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.min(root.s(280), menuPickCol.implicitHeight + root.s(8))
                    color: Theme.surfaceContainerLow
                    border.width: 1; border.color: Theme.outlineVariant; radius: root.s(Theme.radiusLg)
                    Flickable {
                        anchors.fill: parent; anchors.margins: root.s(4); clip: true
                        contentHeight: menuPickCol.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        Column {
                            id: menuPickCol
                            width: parent.width
                            Repeater {
                                model: root.menuResults
                                delegate: Rectangle {
                                    required property var modelData
                                    width: menuPickCol.width; height: root.s(36); radius: root.s(4)
                                    color: menuPickMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: root.s(6); anchors.rightMargin: root.s(6)
                                        spacing: root.s(7)
                                        Image {
                                            Layout.preferredWidth: root.s(21); Layout.preferredHeight: root.s(21)
                                            source: root.menuIcon(modelData)
                                            sourceSize: Qt.size(21, 21); fillMode: Image.PreserveAspectFit
                                            visible: source !== ""
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: String(modelData.name || modelData.id || "")
                                            font.family: "Hack Nerd Font"; font.pixelSize: root.s(10); color: Theme.text; elide: Text.ElideRight
                                        }
                                        Text { text: "+"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(13); color: Theme.text }
                                    }
                                    MouseArea {
                                        id: menuPickMouse
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.addMenuApp(modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
