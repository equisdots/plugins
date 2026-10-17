// UnitCombo — rounded unit dropdown used by the Units panel.
//
// A styled ComboBox: Theme.surfaceContainer fill, Theme.radiusMd corners and
// Theme.outlineVariant hairline. The caller passes the unit list and the
// current unit; picking one emits `picked(unit)`.
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import qs.core
import qs.ui.bar

ComboBox {
    id: combo

    property var units: []
    property string current: ""
    signal picked(string unit)

    Scaler { id: sc; currentWidth: Screen.width }
    function s(v) { return sc.s(v) }

    model: combo.units
    currentIndex: combo.units.indexOf(combo.current)
    font.family: "Hack Nerd Font"
    font.pixelSize: combo.s(14)
    implicitHeight: combo.s(40)

    onActivated: (i) => combo.picked(combo.units[i])

    background: Rectangle {
        radius: Theme.radiusMd
        color: Theme.surfaceContainer
        border.width: 1
        border.color: (combo.activeFocus || combo.popup.visible) ? Theme.mauve : Theme.outlineVariant
    }

    contentItem: Text {
        leftPadding: combo.s(12)
        rightPadding: combo.s(24)
        text: combo.displayText
        font: combo.font
        color: Theme.text
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Text {
        x: combo.width - width - combo.s(10)
        y: (combo.height - height) / 2
        text: "󰅀"
        font.family: "Hack Nerd Font"
        font.pixelSize: combo.s(12)
        color: Theme.subtext0
    }

    popup: Popup {
        y: combo.height + combo.s(4)
        width: combo.width
        implicitHeight: contentItem.implicitHeight + combo.s(8)
        padding: combo.s(4)

        background: Rectangle {
            radius: Theme.radiusMd
            color: Theme.surfaceContainerHigh
            border.width: 1
            border.color: Theme.outlineVariant
        }
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: combo.popup.visible ? combo.delegateModel : null
            currentIndex: combo.highlightedIndex
        }
    }

    delegate: ItemDelegate {
        width: combo.width
        contentItem: Text {
            text: modelData
            font.family: "Hack Nerd Font"
            font.pixelSize: combo.s(14)
            color: Theme.text
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: Theme.radiusSm
            color: highlighted ? Theme.stateLayer(Theme.mauve, Theme.stateHover) : "transparent"
        }
    }
}
