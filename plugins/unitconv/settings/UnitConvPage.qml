import QtQuick
import QtQuick.Layouts
import qs.core

// Units settings (Plugins -> Units). Informational: conversion is pure
// JavaScript in the panel. The optional default category lives in
// ~/.config/hypr/plugins/unitconv/settings.json (scope "unitconv"), seeded by
// defaults.json.
Item {
    id: page
    property var bar: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gapLg
        spacing: Theme.gapMd

        Text { text: "Units"; font.family: "Hack Nerd Font"; font.bold: true; font.pixelSize: 20; color: Theme.text }
        Text {
            text: "Offline unit converter: length, mass, temperature, data and time. Live conversion, no network."
            font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0
            Layout.fillWidth: true; wrapMode: Text.WordWrap
        }

        Rectangle {
            Layout.fillWidth: true
            radius: Theme.radiusLg
            color: Theme.surfaceContainerLow
            border.width: 1; border.color: Theme.outlineVariant
            implicitHeight: inner.implicitHeight + Theme.gapLg * 2

            ColumnLayout {
                id: inner
                anchors.fill: parent; anchors.margins: Theme.gapLg; spacing: Theme.gapSm
                Text { text: "Categories"; font.family: "Hack Nerd Font"; font.pixelSize: 12; color: Theme.text }
                Text {
                    text: "Length (m/km/cm/in/ft/mi), Mass (g/kg/lb/oz), Temperature (C/F/K), Data (B/KB/MB/GB/TB), Time (s/min/h/day)"
                    font.family: "Hack Nerd Font"; font.pixelSize: 12; color: Theme.subtext0
                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Setting: unitconv.category (default Length). Data uses 1024-based units."
            font.family: "Hack Nerd Font"; font.pixelSize: 11; color: Theme.subtext0
            wrapMode: Text.WordWrap
        }

        Item { Layout.fillHeight: true }
    }
}
