import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../bar/edit"
import "../../../bar"
import "../../../../core"

// ═══════════════════════════════════════════════════════════════════════════
// DockPage — the Dock plugin's own settings page (equisdots plugin standard).
//
// Ships in the plugin repo and is deployed by dots with the rest of the plugin
// UI to <quickshell>/ui/plugins/dock/settings/ — the relative imports above
// resolve against that deployed path, not this repo.
//
// Contract: receives the BarEditor root as `bar` (bar.s(), bar.colors).
// Everything it edits lives in settings.json → "dock"; the host adapter
// (host/Dock.qml) reads the same object live.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    anchors.fill: parent

    property var bar: null
    property var host: null   // injected SDK handle (equisdots/plugin-sdk)

    // ── local mirror of settings.json → dock ─────────────────────────────────
    property string dPosition: "bottom"
    property real dIconSize: 44
    property real dSpacing: 10
    property real dPadding: 10
    property real dMargin: 8
    property real dRadius: 20
    property bool dReserve: false
    property bool dShowLabels: false
    property bool dMagnify: true
    property real dMagnifyScale: 1.35
    property real dOpacity: 0.85
    property bool dBorder: true
    property string dBgMode: "auto"
    property string dColor: "surface0"
    property string dBorderColor: "surface1"
    property var dApps: []

    readonly property var cfg: {
        Config.rev;
        let d = Config.rawSettings ? Config.rawSettings.dock : null;
        return (d && typeof d === "object") ? d : ({});
    }

    function num(v, d) { return (typeof v === "number" && isFinite(v)) ? v : d; }

    function syncFromConfig() {
        let d = root.cfg;
        root.dPosition = (["top","bottom","left","right"].indexOf(String(d.position)) >= 0) ? String(d.position) : "bottom";
        root.dIconSize = root.num(d.iconSize, 44);
        root.dSpacing = root.num(d.spacing, 10);
        root.dPadding = root.num(d.padding, 10);
        root.dMargin = root.num(d.margin, 8);
        root.dRadius = root.num(d.radius, 20);
        root.dReserve = d.reserve === true;
        root.dShowLabels = d.showLabels === true;
        root.dMagnify = d.magnify !== false;
        root.dMagnifyScale = root.num(d.magnifyScale, 1.35);
        root.dOpacity = root.num(d.opacity, 0.85);
        root.dBorder = d.border !== false;
        root.dBgMode = (d.background === "custom") ? "custom" : "auto";
        root.dColor = (typeof d.color === "string" && d.color !== "") ? d.color : "surface0";
        root.dBorderColor = (typeof d.borderColor === "string" && d.borderColor !== "") ? d.borderColor : "surface1";
        root.dApps = Array.isArray(d.apps) ? d.apps.map(function (a) { return a; }) : [];
    }
    Component.onCompleted: root.syncFromConfig()

    // ── commit into settings.json → dock (immediate: live while editing) ─────
    property var _pending: ({})
    Timer { id: saveTimer; interval: 250; onTriggered: root.flush() }
    function set(key, v) {
        root._pending[key] = v;
        root.flush();   // apply on every change, not debounced
    }
    function flush() {
        let keys = Object.keys(root._pending);
        if (keys.length === 0) return;
        let base = (Config.rawSettings.dock && typeof Config.rawSettings.dock === "object")
                   ? Config.rawSettings.dock : {};
        Config.setSetting("dock", Object.assign({}, base, root._pending));
        root._pending = {};
    }
    Component.onDestruction: root.flush()

    function setApps(arr) {
        root.dApps = arr.slice();
        root.set("apps", root.dApps);
    }
    function addApp(a) {
        let list = root.dApps.slice();
        list.push({ id: String(a.id || a.exec || ""), label: String(a.label || a.name || ""),
                    icon: String(a.icon || ""), exec: String(a.exec || "") });
        root.setApps(list);
    }
    function removeApp(i) {
        let list = root.dApps.slice();
        if (i < 0 || i >= list.length) return;
        list.splice(i, 1);
        root.setApps(list);
    }
    function moveApp(i, dir) {
        let list = root.dApps.slice();
        let j = i + dir;
        if (i < 0 || i >= list.length || j < 0 || j >= list.length) return;
        let tmp = list[i]; list[i] = list[j]; list[j] = tmp;
        root.setApps(list);
    }

    function appIcon(a) {
        let ic = String((a && a.icon) || "").trim();
        if (ic === "") ic = String((a && a.id) || "").trim();
        if (ic === "") return "";
        return ic.charAt(0) === "/" ? "file://" + ic : "image://icon/" + ic;
    }

    // ── installed-app picker (scripts/apps.sh, shipped with the plugin) ──────
    property var catalog: []
    property string addSearch: ""
    readonly property string appScript: String(Qt.resolvedUrl("../scripts/apps.sh")).replace("file://", "")
    Process {
        id: appsProc
        command: ["bash", root.appScript]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.catalog = (JSON.parse(this.text).apps) || []; }
                catch (e) { root.catalog = []; }
            }
        }
    }
    readonly property var pickerResults: {
        let q = root.addSearch.trim().toLowerCase();
        let all = root.catalog || [];
        if (q === "") return all.slice(0, 60);
        let out = [];
        for (let i = 0; i < all.length && out.length < 60; i++) {
            let n = String(all[i].name || "").toLowerCase();
            let id = String(all[i].id || "").toLowerCase();
            if (n.indexOf(q) >= 0 || id.indexOf(q) >= 0) out.push(all[i]);
        }
        return out;
    }
    property bool showPicker: false

    // new-app manual fields
    property string newLabel: ""
    property string newExec: ""
    property string newIcon: ""

    readonly property var colorRoles: ["surface0", "surface1", "surface2", "base", "mantle", "crust", "text", "blue", "green", "yellow", "red", "mauve", "teal", "peach"]
    function cycleColor(current, roles) {
        let i = roles.indexOf(current);
        return roles[(i + 1) % roles.length];
    }

    readonly property var flickable: body.item ? body.item.flickable : null

    // ── preview colors (mirror of the host's resolution) ─────────────────────
    function toColor(spec, fallbackRole) {
        if (root.bar && root.bar.colors) {
            if (typeof spec === "string" && spec.charAt(0) === "#") return spec;
            if (root.bar.colors[spec] !== undefined) return root.bar.colors[spec];
            if (root.bar.colors[fallbackRole] !== undefined) return root.bar.colors[fallbackRole];
        }
        return "#1e1e2e";
    }
    function withAlpha(c, a) {
        let col = Qt.color(c);
        return Qt.rgba(col.r, col.g, col.b, a);
    }
    readonly property color previewBg: withAlpha(
        root.dBgMode === "custom" ? root.toColor(root.dColor, "surface0") : root.toColor("surface0", "surface0"),
        root.dOpacity)
    readonly property color previewBorder: root.dBorder
        ? withAlpha(root.toColor(root.dBorderColor, "surface1"), Math.min(1, root.dOpacity + 0.2))
        : "transparent"

    Loader {
        id: body
        anchors.fill: parent
        active: root.bar !== null
        sourceComponent: pageBody
    }

    Component {
        id: pageBody
        Item {
            anchors.fill: parent
            property alias flickable: flick

            Flickable {
                id: flick
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentHeight: col.height + bar.s(16)
                ScrollBar.vertical: ScrollBar {
                    id: vScroll
                    width: bar.s(4)
                    policy: ScrollBar.AsNeeded
                    hoverEnabled: true
                    active: flick.moving || vScroll.hovered
                    contentItem: Rectangle {
                        radius: bar.s(2)
                        color: bar.colors.surface2
                        opacity: vScroll.active ? 1.0 : 0.45
                    }
                    background: Item {}
                }

                Column {
                    id: col
                    x: bar.s(8)
                    y: bar.s(8)
                    width: flick.width - bar.s(16)
                    spacing: bar.s(9)

                    Text {
                        text: "Dock"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(24)
                        color: bar.colors.text
                    }
                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: "A launcher dock on any screen edge. Configure the applications, their dimensions and colors; with \"Auto palette\" it follows the shell's active palette."
                        font.pixelSize: bar.s(11)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }

                    // ── live preview ─────────────────────────────────────────
                    SectionTitle { bar: root.bar; text: "Preview" }
                    Rectangle {
                        width: parent.width
                        height: bar.s(96)
                        radius: bar.s(14)
                        color: Qt.alpha(bar.colors.surface0, 0.35)
                        border.width: 1
                        border.color: bar.colors.surface1

                        Rectangle {
                            id: previewPanel
                            anchors.centerIn: parent
                            height: bar.s(56)
                            width: previewRow.implicitWidth + bar.s(16)
                            radius: bar.s(root.dRadius * 0.6)
                            color: root.previewBg
                            border.width: root.dBorder ? 1 : 0
                            border.color: root.previewBorder

                            Row {
                                id: previewRow
                                anchors.centerIn: parent
                                spacing: bar.s(8)
                                Repeater {
                                    model: root.dApps.slice(0, 8)
                                    delegate: Rectangle {
                                        required property var modelData
                                        width: bar.s(30); height: bar.s(30)
                                        radius: bar.s(9)
                                        color: Qt.alpha(bar.colors.text, 0.06)
                                        Image {
                                            anchors.centerIn: parent
                                            width: bar.s(19); height: width
                                            source: root.appIcon(modelData)
                                            sourceSize: Qt.size(width, height)
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                        }
                                    }
                                }
                                Text {
                                    visible: root.dApps.length === 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "no apps yet"
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: bar.s(11)
                                    color: bar.colors.subtext0
                                }
                            }
                        }
                    }

                    // ── applications ─────────────────────────────────────────
                    SectionTitle { bar: root.bar; text: "Applications" }

                    Column {
                        width: parent.width
                        spacing: bar.s(8)

                        Repeater {
                            model: root.dApps
                            delegate: Rectangle {
                                id: appRow
                                required property var modelData
                                required property int index
                                width: parent.width
                                height: bar.s(52)
                                radius: bar.s(16)
                                color: Qt.alpha(bar.colors.surface0, 0.4)
                                border.width: 1
                                border.color: bar.colors.surface1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: bar.s(12)
                                    anchors.rightMargin: bar.s(10)
                                    spacing: bar.s(10)

                                    Rectangle {
                                        Layout.preferredWidth: bar.s(34)
                                        Layout.preferredHeight: bar.s(34)
                                        radius: bar.s(10)
                                        color: Qt.alpha(bar.colors.text, 0.06)
                                        Image {
                                            anchors.centerIn: parent
                                            width: bar.s(22); height: width
                                            source: root.appIcon(appRow.modelData)
                                            sourceSize: Qt.size(width, height)
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                        }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: bar.s(1)
                                        Text {
                                            text: String(appRow.modelData.label || appRow.modelData.id || "")
                                            font.family: "Hack Nerd Font"
                                            font.weight: Font.Bold
                                            font.pixelSize: bar.s(12)
                                            color: bar.colors.text
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: String(appRow.modelData.exec || "")
                                            font.family: "Hack Nerd Font"
                                            font.pixelSize: bar.s(10)
                                            color: bar.colors.subtext0
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                    EditorButton { bar: root.bar; compact: true; icon: "↑"; label: ""; enabled: appRow.index > 0; onActivated: root.moveApp(appRow.index, -1) }
                                    EditorButton { bar: root.bar; compact: true; icon: "↓"; label: ""; enabled: appRow.index < root.dApps.length - 1; onActivated: root.moveApp(appRow.index, 1) }
                                    EditorButton { bar: root.bar; compact: true; icon: "✕"; label: ""; accentRole: "red"; onActivated: root.removeApp(appRow.index) }
                                }
                            }
                        }

                        EditLabel {
                            visible: root.dApps.length === 0
                            bar: root.bar
                            width: parent.width
                            text: "No applications yet. Add them below."
                            font.pixelSize: bar.s(11)
                            color: bar.colors.subtext0
                        }

                        RowLayout {
                            width: parent.width
                            spacing: bar.s(8)
                            EditorButton {
                                bar: root.bar
                                compact: true
                                icon: "󰍉"
                                label: root.showPicker ? "Hide installed apps" : "Browse installed apps"
                                active: root.showPicker
                                onActivated: {
                                    root.showPicker = !root.showPicker;
                                    if (root.showPicker) { appsProc.running = false; appsProc.running = true; }
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }

                        // picker
                        Column {
                            visible: root.showPicker
                            width: parent.width
                            spacing: bar.s(8)

                            Rectangle {
                                width: parent.width
                                height: bar.s(40)
                                radius: bar.s(14)
                                color: Qt.alpha(bar.colors.surface0, 0.4)
                                border.width: 1
                                border.color: searchField.activeFocus ? bar.colors.mauve : bar.colors.surface1
                                TextField {
                                    id: searchField
                                    anchors.fill: parent
                                    anchors.leftMargin: bar.s(12)
                                    anchors.rightMargin: bar.s(12)
                                    background: Item {}
                                    placeholderText: "Search installed applications…"
                                    placeholderTextColor: Qt.alpha(bar.colors.subtext0, 0.55)
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: bar.s(13)
                                    color: bar.colors.text
                                    selectByMouse: true
                                    onTextChanged: root.addSearch = text
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: Math.min(bar.s(260), pickList.contentHeight + bar.s(8))
                                radius: bar.s(14)
                                color: Qt.alpha(bar.colors.surface0, 0.4)
                                border.width: 1
                                border.color: bar.colors.surface1

                                Flickable {
                                    id: pickList
                                    anchors.fill: parent
                                    anchors.margins: bar.s(4)
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds
                                    contentHeight: pickCol.height
                                    Column {
                                        id: pickCol
                                        width: pickList.width
                                        Repeater {
                                            model: root.pickerResults
                                            delegate: Rectangle {
                                                id: pickRow
                                                required property var modelData
                                                width: pickCol.width
                                                height: bar.s(38)
                                                radius: bar.s(10)
                                                color: pickMa.containsMouse ? Qt.alpha(bar.colors.mauve, 0.14) : "transparent"
                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: bar.s(8)
                                                    anchors.rightMargin: bar.s(8)
                                                    spacing: bar.s(10)
                                                    Image {
                                                        Layout.preferredWidth: bar.s(22); Layout.preferredHeight: bar.s(22)
                                                        source: root.appIcon(pickRow.modelData)
                                                        sourceSize: Qt.size(width, height)
                                                        fillMode: Image.PreserveAspectFit
                                                        smooth: true
                                                    }
                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: String(pickRow.modelData.name || pickRow.modelData.id || "")
                                                        font.family: "Hack Nerd Font"
                                                        font.pixelSize: bar.s(12)
                                                        color: bar.colors.text
                                                        elide: Text.ElideRight
                                                    }
                                                    Text {
                                                        text: "+"
                                                        font.family: "Hack Nerd Font"
                                                        font.pixelSize: bar.s(14)
                                                        color: bar.colors.mauve
                                                    }
                                                }
                                                MouseArea {
                                                    id: pickMa
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.addApp({ id: pickRow.modelData.id, label: pickRow.modelData.name,
                                                                      icon: pickRow.modelData.icon, exec: pickRow.modelData.exec });
                                                        root.addSearch = ""; searchField.text = "";
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // manual add
                        SectionTitle { bar: root.bar; text: "Add manually" }
                        FieldCard {
                            bar: root.bar; width: parent.width
                            label: "Label"; value: root.newLabel; maxLength: 60
                            onEdited: (t) => { root.newLabel = t; }
                        }
                        FieldCard {
                            bar: root.bar; width: parent.width
                            label: "Command"; value: root.newExec; maxLength: 400
                            placeholder: "e.g. kitty"
                            onEdited: (t) => { root.newExec = t; }
                        }
                        FieldCard {
                            bar: root.bar; width: parent.width
                            label: "Icon"; value: root.newIcon; maxLength: 200
                            placeholder: "icon name or /path/to.png"
                            onEdited: (t) => { root.newIcon = t; }
                        }
                        EditorButton {
                            bar: root.bar
                            compact: true
                            icon: "＋"
                            label: "Add application"
                            enabled: root.newExec.trim() !== ""
                            onActivated: {
                                root.addApp({ id: root.newLabel || root.newExec, label: root.newLabel || root.newExec,
                                              icon: root.newIcon, exec: root.newExec });
                                root.newLabel = ""; root.newExec = ""; root.newIcon = "";
                            }
                        }
                    }

                    // ── layout ───────────────────────────────────────────────
                    SectionTitle { bar: root.bar; text: "Layout" }

                    RowLayout {
                        width: parent.width
                        spacing: bar.s(8)
                        OptionCard { bar: root.bar; Layout.fillWidth: true; icon: "↓"; label: "Bottom"; active: root.dPosition === "bottom"; onActivated: { root.dPosition = "bottom"; root.set("position", "bottom"); } }
                        OptionCard { bar: root.bar; Layout.fillWidth: true; icon: "↑"; label: "Top"; active: root.dPosition === "top"; onActivated: { root.dPosition = "top"; root.set("position", "top"); } }
                        OptionCard { bar: root.bar; Layout.fillWidth: true; icon: "←"; label: "Left"; active: root.dPosition === "left"; onActivated: { root.dPosition = "left"; root.set("position", "left"); } }
                        OptionCard { bar: root.bar; Layout.fillWidth: true; icon: "→"; label: "Right"; active: root.dPosition === "right"; onActivated: { root.dPosition = "right"; root.set("position", "right"); } }
                    }

                    Grid {
                        width: parent.width
                        columns: 2
                        columnSpacing: bar.s(28)
                        rowSpacing: bar.s(10)
                        Stepper { bar: root.bar; label: "Size " + Math.round(root.dIconSize); onDec: { root.dIconSize = Math.max(16, root.dIconSize - 2); root.set("iconSize", root.dIconSize); } onInc: { root.dIconSize = Math.min(96, root.dIconSize + 2); root.set("iconSize", root.dIconSize); } }
                        Stepper { bar: root.bar; label: "Gap " + Math.round(root.dSpacing); onDec: { root.dSpacing = Math.max(2, root.dSpacing - 2); root.set("spacing", root.dSpacing); } onInc: { root.dSpacing = Math.min(40, root.dSpacing + 2); root.set("spacing", root.dSpacing); } }
                        Stepper { bar: root.bar; label: "Pad " + Math.round(root.dPadding); onDec: { root.dPadding = Math.max(4, root.dPadding - 2); root.set("padding", root.dPadding); } onInc: { root.dPadding = Math.min(40, root.dPadding + 2); root.set("padding", root.dPadding); } }
                        Stepper { bar: root.bar; label: "Margin " + Math.round(root.dMargin); onDec: { root.dMargin = Math.max(0, root.dMargin - 2); root.set("margin", root.dMargin); } onInc: { root.dMargin = Math.min(80, root.dMargin + 2); root.set("margin", root.dMargin); } }
                        Stepper { bar: root.bar; label: "Radius " + Math.round(root.dRadius); onDec: { root.dRadius = Math.max(0, root.dRadius - 2); root.set("radius", root.dRadius); } onInc: { root.dRadius = Math.min(60, root.dRadius + 2); root.set("radius", root.dRadius); } }
                    }
                    RowLayout {
                        width: parent.width
                        spacing: bar.s(12)
                        Text { text: "Show labels"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(12); color: bar.colors.text; Layout.fillWidth: true }
                        ToggleSwitch { bar: root.bar; checked: root.dShowLabels; onToggled: { root.dShowLabels = checked; root.set("showLabels", checked); } }
                    }
                    RowLayout {
                        width: parent.width
                        spacing: bar.s(12)
                        Text { text: "Reserve space"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(12); color: bar.colors.text; Layout.fillWidth: true }
                        ToggleSwitch { bar: root.bar; checked: root.dReserve; onToggled: { root.dReserve = checked; root.set("reserve", checked); } }
                    }

                    // ── appearance ───────────────────────────────────────────
                    SectionTitle { bar: root.bar; text: "Appearance" }

                    RowLayout {
                        width: parent.width
                        spacing: bar.s(8)
                        OptionCard { bar: root.bar; Layout.fillWidth: true; icon: "󰏘"; label: "Auto palette"; active: root.dBgMode === "auto"; onActivated: { root.dBgMode = "auto"; root.set("background", "auto"); } }
                        OptionCard { bar: root.bar; Layout.fillWidth: true; icon: "󰃉"; label: "Custom"; active: root.dBgMode === "custom"; onActivated: { root.dBgMode = "custom"; root.set("background", "custom"); } }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: bar.s(12)
                        Text { text: "Background"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(12); color: bar.colors.text; Layout.fillWidth: true }
                        ColorCycle { bar: root.bar; role: root.dColor; roles: root.colorRoles; onCycled: (r) => { root.dColor = r; root.set("background", "custom"); root.dBgMode = "custom"; root.set("color", r); } }
                    }
                    FieldCard {
                        bar: root.bar; width: parent.width
                        label: "Custom color"; value: (root.dColor.charAt(0) === "#") ? root.dColor : ""; fieldWidth: 140
                        placeholder: "#rrggbb"
                        swatch: root.toColor(root.dColor, "surface0")
                        onEdited: (t) => { if (t.trim() !== "") { root.dColor = t.trim(); root.dBgMode = "custom"; root.set("background", "custom"); root.set("color", root.dColor); } }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: bar.s(12)
                        Text { text: "Border"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(12); color: bar.colors.text; Layout.fillWidth: true }
                        ColorCycle { bar: root.bar; role: root.dBorderColor; roles: root.colorRoles; onCycled: (r) => { root.dBorderColor = r; root.set("borderColor", r); } }
                        ToggleSwitch { bar: root.bar; checked: root.dBorder; onToggled: { root.dBorder = checked; root.set("border", checked); } }
                    }
                    RowLayout {
                        width: parent.width
                        spacing: bar.s(12)
                        Text { text: "Magnify on hover"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(12); color: bar.colors.text; Layout.fillWidth: true }
                        Stepper { bar: root.bar; label: root.dMagnifyScale.toFixed(2) + "x"; onDec: { root.dMagnifyScale = Math.max(1.0, Math.round((root.dMagnifyScale - 0.05) * 100) / 100); root.set("magnifyScale", root.dMagnifyScale); } onInc: { root.dMagnifyScale = Math.min(1.8, Math.round((root.dMagnifyScale + 0.05) * 100) / 100); root.set("magnifyScale", root.dMagnifyScale); } }
                        ToggleSwitch { bar: root.bar; checked: root.dMagnify; onToggled: { root.dMagnify = checked; root.set("magnify", checked); } }
                    }
                    Grid {
                        width: parent.width
                        columns: 2
                        columnSpacing: bar.s(28)
                        rowSpacing: bar.s(10)
                        Stepper { bar: root.bar; label: "Opacity " + Math.round(root.dOpacity * 100) + "%"; onDec: { root.dOpacity = Math.max(0.15, Math.round((root.dOpacity - 0.05) * 100) / 100); root.set("opacity", root.dOpacity); } onInc: { root.dOpacity = Math.min(1.0, Math.round((root.dOpacity + 0.05) * 100) / 100); root.set("opacity", root.dOpacity); } }
                    }
                }
            }
        }
    }
}
