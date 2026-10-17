// UnitConv — the Units (unitconv) plugin's panel (equisdots plugin standard).
//
// Loaded by the shell's panel host from ui/plugins/unitconv/ (manifest
// provides.panels.units). Pure JavaScript conversion (no network): a category
// selector, two numeric fields and unit dropdowns, converted live. The optional
// default category comes from ~/.config/hypr/plugins/unitconv/settings.json
// (scope "unitconv"), seeded by defaults.json.
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.core
import qs.ui.bar

Item {
    id: window
    focus: true

    Scaler { id: sc; currentWidth: Screen.width }
    function s(v) { return sc.s(v) }

    // ── unit tables ───────────────────────────────────────────────────────────
    // Non-temperature categories carry a factor to the base unit (m, g, B, s).
    // Temperature is handled by explicit formulas below.
    readonly property var categories: [
        { id: "Length", units: ["m", "km", "cm", "in", "ft", "mi"] },
        { id: "Mass", units: ["g", "kg", "lb", "oz"] },
        { id: "Temperature", units: ["C", "F", "K"] },
        { id: "Data", units: ["B", "KB", "MB", "GB", "TB"] },
        { id: "Time", units: ["s", "min", "h", "day"] }
    ]

    readonly property var factors: ({
        "Length": { "m": 1, "km": 1000, "cm": 0.01, "in": 0.0254, "ft": 0.3048, "mi": 1609.344 },
        "Mass": { "g": 1, "kg": 1000, "lb": 453.59237, "oz": 28.349523125 },
        "Data": { "B": 1, "KB": 1024, "MB": 1048576, "GB": 1073741824, "TB": 1099511627776 },
        "Time": { "s": 1, "min": 60, "h": 3600, "day": 86400 }
    })

    function unitsOf(id) {
        for (let i = 0; i < window.categories.length; i++)
            if (window.categories[i].id === id) return window.categories[i].units;
        return [];
    }
    readonly property var currentUnits: window.unitsOf(window.currentCategoryId)

    function toBase(cat, unit, v) {
        if (cat === "Temperature") {
            if (unit === "C") return v;
            if (unit === "F") return (v - 32) * 5 / 9;
            if (unit === "K") return v - 273.15;
            return v;
        }
        let f = (window.factors[cat] || {})[unit];
        return (typeof f === "number") ? v * f : v;
    }
    function fromBase(cat, unit, base) {
        if (cat === "Temperature") {
            if (unit === "C") return base;
            if (unit === "F") return base * 9 / 5 + 32;
            if (unit === "K") return base + 273.15;
            return base;
        }
        let f = (window.factors[cat] || {})[unit];
        return (typeof f === "number" && f !== 0) ? base / f : base;
    }
    function convert(cat, from, to, v) {
        return window.fromBase(cat, to, window.toBase(cat, from, v));
    }

    function fmt(n) {
        if (typeof n !== "number" || !isFinite(n)) return "";
        if (n === 0) return "0";
        let a = Math.abs(n);
        if (a >= 1e15 || a < 1e-6) return n.toExponential(4);
        return String(Number(n.toPrecision(8)));
    }

    // ── state ─────────────────────────────────────────────────────────────────
    property string currentCategoryId: "Length"
    property string fromUnit: "m"
    property string toUnit: "km"
    property string inputText: "1"
    property string resultText: ""

    function recompute() {
        let v = parseFloat(String(window.inputText).replace(",", "."));
        if (isNaN(v)) { window.resultText = ""; return; }
        window.resultText = window.fmt(window.convert(window.currentCategoryId, window.fromUnit, window.toUnit, v));
    }

    function applyCategory(id) {
        if (window.unitsOf(id).length === 0) id = "Length";
        window.currentCategoryId = id;
        let us = window.unitsOf(id);
        window.fromUnit = us[0] || "";
        window.toUnit = us[1] || us[0] || "";
        window.recompute();
    }

    function swap() {
        let f = window.fromUnit;
        window.fromUnit = window.toUnit;
        window.toUnit = f;
        if (window.resultText !== "") {
            window.inputText = window.resultText;
            amountField.text = window.resultText;
        }
        window.recompute();
    }

    Component.onCompleted: window.applyCategory("Length")

    // Optional default category seed (defaults.json -> unitconv.category).
    Process {
        id: settingsProc
        command: ["bash", "-c",
            "cat '" + Quickshell.env("HOME") + "/.config/hypr/plugins/unitconv/settings.json' 2>/dev/null || echo '{}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let p = JSON.parse(this.text || "{}");
                    let u = p.unitconv || {};
                    if (u.category) window.applyCategory(String(u.category));
                } catch (e) {}
            }
        }
    }

    function closeSelf() {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
    }
    Keys.onEscapePressed: (event) => { window.closeSelf(); event.accepted = true; }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusXl
        color: Theme.glassFill
        border.width: 1
        border.color: Theme.outlineVariant

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: s(14)
            spacing: s(12)

            Text {
                text: "Units"
                font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: s(18)
                color: Theme.text
            }

            // ── category chips ────────────────────────────────────────────────
            Flow {
                Layout.fillWidth: true
                spacing: s(8)

                Repeater {
                    model: window.categories
                    delegate: Rectangle {
                        width: chipText.implicitWidth + s(24)
                        height: s(32)
                        radius: Theme.radiusFull
                        color: window.currentCategoryId === modelData.id
                            ? Theme.stateLayer(Theme.mauve, Theme.statePress)
                            : Theme.surfaceContainer
                        border.width: 1
                        border.color: window.currentCategoryId === modelData.id ? Theme.mauve : Theme.outlineVariant

                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            text: modelData.id
                            font.family: "Hack Nerd Font"; font.pixelSize: s(13)
                            font.weight: window.currentCategoryId === modelData.id ? Font.Bold : Font.Normal
                            color: window.currentCategoryId === modelData.id ? Theme.mauve : Theme.subtext0
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.applyCategory(modelData.id)
                        }
                    }
                }
            }

            // ── converter card ────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: converter.implicitHeight + s(28)
                radius: Theme.radiusLg
                color: Theme.surfaceContainerLow
                border.width: 1
                border.color: Theme.outlineVariant

                ColumnLayout {
                    id: converter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: s(14)
                    spacing: s(12)

                    // from
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: s(10)

                        Text {
                            text: "From"
                            Layout.preferredWidth: s(44)
                            font.family: "Hack Nerd Font"; font.pixelSize: s(12)
                            color: Theme.subtext0
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: s(40)
                            radius: Theme.radiusMd
                            color: Theme.surfaceContainer
                            border.width: 1
                            border.color: amountField.activeFocus ? Theme.mauve : Theme.outlineVariant

                            TextField {
                                id: amountField
                                anchors.fill: parent
                                anchors.leftMargin: s(12)
                                anchors.rightMargin: s(12)
                                text: "1"
                                background: Item {}
                                color: Theme.text
                                font.family: "Hack Nerd Font"; font.pixelSize: s(15)
                                placeholderText: "0"
                                placeholderTextColor: Theme.subtext0
                                verticalAlignment: TextInput.AlignVCenter
                                selectByMouse: true
                                validator: DoubleValidator { notation: DoubleValidator.StandardNotation }
                                onTextEdited: { window.inputText = text; window.recompute(); }
                            }
                        }

                        UnitCombo {
                            id: fromCombo
                            Layout.preferredWidth: s(104)
                            units: window.currentUnits
                            current: window.fromUnit
                            onPicked: (u) => { window.fromUnit = u; window.recompute(); }
                        }
                    }

                    // equals / swap
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: s(10)

                        Item { Layout.preferredWidth: s(44) }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Theme.outlineVariant
                        }

                        Button {
                            id: swapBtn
                            implicitWidth: s(72)
                            implicitHeight: s(30)
                            padding: 0
                            onClicked: window.swap()
                            background: Rectangle {
                                radius: Theme.radiusFull
                                color: swapBtn.down ? Theme.stateLayer(Theme.blue, Theme.statePress)
                                    : (swapBtn.hovered ? Theme.stateLayer(Theme.blue, Theme.stateHover) : Theme.surfaceContainer)
                                border.width: 1
                                border.color: Theme.outlineVariant
                            }
                            contentItem: Text {
                                text: "⇄ swap"
                                font.family: "Hack Nerd Font"; font.pixelSize: s(12)
                                color: Theme.text
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    // to
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: s(10)

                        Text {
                            text: "To"
                            Layout.preferredWidth: s(44)
                            font.family: "Hack Nerd Font"; font.pixelSize: s(12)
                            color: Theme.subtext0
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: s(40)
                            radius: Theme.radiusMd
                            color: Theme.surfaceContainer
                            border.width: 1
                            border.color: Theme.outlineVariant

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: s(12)
                                anchors.rightMargin: s(12)
                                text: window.resultText
                                font.family: "Hack Nerd Font"; font.pixelSize: s(15); font.weight: Font.Bold
                                color: Theme.green
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }

                        UnitCombo {
                            id: toCombo
                            Layout.preferredWidth: s(104)
                            units: window.currentUnits
                            current: window.toUnit
                            onPicked: (u) => { window.toUnit = u; window.recompute(); }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            Text {
                Layout.fillWidth: true
                text: "Offline conversion - no network. Data uses 1024-based units."
                font.family: "Hack Nerd Font"; font.pixelSize: s(11)
                color: Theme.subtext0
            }
        }
    }
}
