import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.core

// mos Topbar settings. Every control writes through host.settings (or the
// core Config fallback), so the bar reacts live without a shell restart.
Item {
    id: root
    property var bar: null
    property var host: null

    readonly property var cfg: {
        if (root.host && root.host.settings) {
            root.host.settings.revision;
            return root.host.settings.section;
        }
        Config.rev;
        let d = Config.rawSettings ? Config.rawSettings["mos-topbar"] : null;
        return (d && typeof d === "object") ? d : ({});
    }

    function set(key, value) {
        if (root.host && root.host.settings) root.host.settings.set(key, value);
        else {
            let base = (Config.rawSettings["mos-topbar"] && typeof Config.rawSettings["mos-topbar"] === "object")
                ? Config.rawSettings["mos-topbar"] : {};
            Config.setSetting("mos-topbar", Object.assign({}, base, { [key]: value }));
        }
    }
    function enabled(key, fallback) { return root.cfg[key] !== undefined ? root.cfg[key] !== false : fallback; }

    component Section: Text {
        Layout.fillWidth: true
        text: ""
        font.family: "Hack Nerd Font"; font.pixelSize: 9
        font.letterSpacing: 1.6; color: Theme.subtext0
        topPadding: 6
    }

    component ToggleRow: Rectangle {
        id: row
        property string label: ""
        property bool checked: false
        signal toggled(bool value)
        Layout.fillWidth: true
        implicitHeight: 44
        color: Theme.surfaceContainerLow
        border.width: 1; border.color: Theme.outlineVariant; radius: 0
        Text {
            anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter
            text: row.label; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.text
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 58; anchors.verticalCenter: parent.verticalCenter
            text: row.checked ? "ON" : "OFF"
            font.family: "Hack Nerd Font"; font.pixelSize: 9
            color: row.checked ? Theme.text : Theme.subtext0
        }
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
            width: 36; height: 20; radius: 10
            color: row.checked ? Theme.text : Theme.surfaceContainerHigh
            Rectangle {
                width: 16; height: 16; radius: 8
                x: row.checked ? parent.width - width - 2 : 2
                anchors.verticalCenter: parent.verticalCenter
                color: row.checked ? Theme.base : Theme.text
                Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: row.toggled(!row.checked)
        }
    }

    component Stepper: Rectangle {
        id: step
        property string label: ""
        property string value: ""
        signal dec()
        signal inc()
        Layout.fillWidth: true
        implicitHeight: 44
        color: Theme.surfaceContainerLow
        border.width: 1; border.color: Theme.outlineVariant; radius: 0
        Text {
            anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter
            text: step.label; font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.text
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Rectangle {
                width: 26; height: 26; radius: 0
                color: minusMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                border.width: 1; border.color: Theme.outlineVariant
                Text { anchors.centerIn: parent; text: "−"; font.family: "Hack Nerd Font"; font.pixelSize: 14; color: Theme.text }
                MouseArea { id: minusMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: step.dec() }
            }
            Text {
                width: 54; height: 26
                text: step.value; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                font.family: "Hack Nerd Font"; font.pixelSize: 10; color: Theme.text
            }
            Rectangle {
                width: 26; height: 26; radius: 0
                color: plusMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                border.width: 1; border.color: Theme.outlineVariant
                Text { anchors.centerIn: parent; text: "+"; font.family: "Hack Nerd Font"; font.pixelSize: 14; color: Theme.text }
                MouseArea { id: plusMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: step.inc() }
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
            spacing: 8

            Text {
                text: "MOS TOPBAR"
                font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: 18
                color: Theme.text
            }
            Text {
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                text: "macOS 27-style complete menu bar. Every option below applies live. Enable this plugin and disable the core bar so it owns the top edge."
                font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0
            }

            Section { text: "LAYOUT" }
            Stepper {
                label: "Bar height"; value: (Number(root.cfg.height) || 24) + " px"
                onDec: root.set("height", Math.max(20, (Number(root.cfg.height) || 24) - 2))
                onInc: root.set("height", Math.min(32, (Number(root.cfg.height) || 24) + 2))
            }
            Stepper {
                label: "Item spacing"; value: (Number(root.cfg.itemSpacing) || 5) + " px"
                onDec: root.set("itemSpacing", Math.max(0, (Number(root.cfg.itemSpacing) || 5) - 1))
                onInc: root.set("itemSpacing", Math.min(14, (Number(root.cfg.itemSpacing) || 5) + 1))
            }
            Stepper {
                label: "Bar opacity"; value: Math.round((Number(root.cfg.barOpacity) || 0.66) * 100) + "%"
                onDec: root.set("barOpacity", Math.max(0.15, Math.round(((Number(root.cfg.barOpacity) || 0.66) - 0.05) * 100) / 100))
                onInc: root.set("barOpacity", Math.min(1.0, Math.round(((Number(root.cfg.barOpacity) || 0.66) + 0.05) * 100) / 100))
            }
            Stepper {
                label: "Menu opacity"; value: Math.round((Number(root.cfg.menuOpacity) || 0.95) * 100) + "%"
                onDec: root.set("menuOpacity", Math.max(0.35, Math.round(((Number(root.cfg.menuOpacity) || 0.95) - 0.05) * 100) / 100))
                onInc: root.set("menuOpacity", Math.min(1.0, Math.round(((Number(root.cfg.menuOpacity) || 0.95) + 0.05) * 100) / 100))
            }

            Section { text: "LEADING MENUS" }
            ToggleRow {
                label: "Show app name"; checked: root.enabled("showAppName", true)
                onToggled: (v) => root.set("showAppName", v)
            }
            ToggleRow {
                label: "Show File / Edit / Format / View / Window / Help"; checked: root.enabled("showAppMenus", true)
                onToggled: (v) => root.set("showAppMenus", v)
            }

            Section { text: "MENU BAR EXTRAS" }
            ToggleRow {
                label: "Wi-Fi"; checked: root.enabled("showWifi", true)
                onToggled: (v) => root.set("showWifi", v)
            }
            ToggleRow {
                label: "Bluetooth"; checked: root.enabled("showBluetooth", true)
                onToggled: (v) => root.set("showBluetooth", v)
            }
            ToggleRow {
                label: "Battery"; checked: root.enabled("showBattery", true)
                onToggled: (v) => root.set("showBattery", v)
            }
            ToggleRow {
                label: "Clock + calendar"; checked: root.enabled("showClock", true)
                onToggled: (v) => root.set("showClock", v)
            }
            ToggleRow {
                label: "Control Center"; checked: root.enabled("showControlCenter", true)
                onToggled: (v) => root.set("showControlCenter", v)
            }
            ToggleRow {
                label: "Spotlight"; checked: root.enabled("showSpotlight", true)
                onToggled: (v) => root.set("showSpotlight", v)
            }
            ToggleRow {
                label: "Clock seconds"; checked: root.cfg.showSeconds === true
                onToggled: (v) => root.set("showSeconds", v)
            }
            ToggleRow {
                label: "Battery percentage"; checked: root.cfg.showBatteryPercent === true
                onToggled: (v) => root.set("showBatteryPercent", v)
            }

            Item { Layout.preferredHeight: 8 }
        }
    }
}
