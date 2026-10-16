// Calculator — the Calculator plugin's panel (equisdots plugin standard).
//
// Loaded by the shell's panel host from ui/plugins/calculator/ (manifest
// provides.panels.calculator); the qs.* imports resolve against the shell tree.
// "=" evaluates the expression through scripts/calculator.sh (qalc when
// available) and falls back to a small, safe in-panel evaluator that only
// understands numbers and + - * / ( ). The copy button pipes the result to
// wl-copy via stdin (no shell quoting).
import QtQuick
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

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/plugins/calculator/scripts/calculator.sh"

    // ── state ──────────────────────────────────────────────────────────────
    property string expr: ""
    property string result: ""
    property bool evaluated: false  // the last action was "="
    property int historyLimit: 8

    ListModel { id: historyModel }

    function closeSelf() {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
    }

    // ── input handling ─────────────────────────────────────────────────────
    function press(k) {
        if (window.evaluated) {
            // A digit after "=" starts a fresh calculation; an operator chains.
            if ("0123456789.".indexOf(k) >= 0) { window.expr = ""; window.result = ""; }
            window.evaluated = false;
        }
        const ops = "+-*/";
        if (ops.indexOf(k) >= 0) {
            if (window.expr === "") { if (k !== "-") return; }
            else {
                const last = window.expr.charAt(window.expr.length - 1);
                if (ops.indexOf(last) >= 0) { window.expr = window.expr.slice(0, -1) + k; return; }
                if (last === "(" && k !== "-") return;
            }
        }
        if (k === ".") {
            const m = window.expr.match(/(\d*\.?\d*)$/);
            if (m && m[1].indexOf(".") >= 0) return;
        }
        window.expr += k;
    }

    function backspace() {
        window.expr = window.expr.slice(0, -1);
        window.result = "";
        window.evaluated = false;
    }

    function clearAll() {
        window.expr = "";
        window.result = "";
        window.evaluated = false;
    }

    function toggleSign() {
        const m = window.expr.match(/(\d+\.?\d*)$/);
        if (!m) return;
        const start = window.expr.length - m[1].length;
        const before = start > 0 ? window.expr.charAt(start - 1) : "";
        if (before === "-" && (start < 2 || "+-*/(".indexOf(window.expr.charAt(start - 2)) >= 0)) {
            window.expr = window.expr.substring(0, start - 1) + window.expr.substring(start);
        } else if (before === "" || "+-*/(".indexOf(before) >= 0) {
            window.expr = window.expr.substring(0, start) + "-" + m[1];
        }
    }

    function applyPercent() {
        const m = window.expr.match(/(\d+\.?\d*)$/);
        if (!m) return;
        const start = window.expr.length - m[1].length;
        window.expr = window.expr.substring(0, start) + "(" + m[1] + "/100)";
    }

    // ── evaluation ─────────────────────────────────────────────────────────
    function compute() {
        const e = window.expr.trim();
        if (e === "") return;
        calcProc.command = ["bash", window.scriptPath, e];
        calcProc.running = false;
        calcProc.running = true;
    }

    Process {
        id: calcProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const out = (this.text || "").trim();
                let res;
                if (out === "__NO_QALC__") res = window.jsEvaluate(window.expr);
                else if (out === "") res = "error";
                else res = out;
                window.result = res;
                window.evaluated = true;
                window.pushHistory(window.expr, res);
            }
        }
    }

    function pushHistory(e, r) {
        if (e === "" || r === "" || r === "error") return;
        historyModel.insert(0, { expr: e, res: r });
        while (historyModel.count > window.historyLimit) historyModel.remove(historyModel.count - 1);
    }

    // Safe evaluator: numbers and + - * / ( ) only — never eval().
    function jsEvaluate(src) {
        const tokens = window.tokenize(src);
        if (!tokens || tokens.length === 0) return "error";
        const pos = { i: 0 };
        const v = window.parseAdd(tokens, pos);
        if (v === null || pos.i !== tokens.length || !isFinite(v)) return "error";
        return window.fmtNumber(v);
    }

    function tokenize(src) {
        const t = [];
        let i = 0;
        while (i < src.length) {
            const c = src.charAt(i);
            if (c === " ") { i++; continue; }
            if ("+-*/()".indexOf(c) >= 0) { t.push({ type: c }); i++; continue; }
            if ((c >= "0" && c <= "9") || c === ".") {
                let num = "";
                while (i < src.length && ((src.charAt(i) >= "0" && src.charAt(i) <= "9") || src.charAt(i) === ".")) {
                    num += src.charAt(i); i++;
                }
                t.push({ type: "num", value: parseFloat(num) });
                continue;
            }
            return null;
        }
        return t;
    }

    function parseAdd(t, p) {
        let v = window.parseMul(t, p);
        if (v === null) return null;
        while (p.i < t.length && (t[p.i].type === "+" || t[p.i].type === "-")) {
            const op = t[p.i].type; p.i++;
            const r = window.parseMul(t, p);
            if (r === null) return null;
            v = op === "+" ? v + r : v - r;
        }
        return v;
    }

    function parseMul(t, p) {
        let v = window.parseUnary(t, p);
        if (v === null) return null;
        while (p.i < t.length && (t[p.i].type === "*" || t[p.i].type === "/")) {
            const op = t[p.i].type; p.i++;
            const r = window.parseUnary(t, p);
            if (r === null) return null;
            v = op === "*" ? v * r : v / r;
        }
        return v;
    }

    function parseUnary(t, p) {
        if (p.i < t.length && t[p.i].type === "-") { p.i++; const v = window.parseUnary(t, p); return v === null ? null : -v; }
        if (p.i < t.length && t[p.i].type === "+") { p.i++; return window.parseUnary(t, p); }
        return window.parsePrimary(t, p);
    }

    function parsePrimary(t, p) {
        if (p.i >= t.length) return null;
        const tok = t[p.i];
        if (tok.type === "num") { p.i++; return tok.value; }
        if (tok.type === "(") {
            p.i++;
            const v = window.parseAdd(t, p);
            if (v === null) return null;
            if (p.i >= t.length || t[p.i].type !== ")") return null;
            p.i++;
            return v;
        }
        return null;
    }

    function fmtNumber(v) {
        if (!isFinite(v)) return "error";
        return String(Math.round(v * 1e10) / 1e10);
    }

    // ── clipboard ──────────────────────────────────────────────────────────
    function copyResult() {
        const t = window.result !== "" ? window.result : window.expr;
        if (t === "") return;
        copyProc.write(t);
        copyProc.running = false;
        copyProc.running = true;
    }

    Process {
        id: copyProc
        stdinEnabled: true
        command: ["wl-copy"]
        stdout: StdioCollector {}
    }

    // ── keyboard ───────────────────────────────────────────────────────────
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Backspace) { window.backspace(); event.accepted = true; return; }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { window.compute(); event.accepted = true; return; }
        if (event.key === Qt.Key_Escape) { window.closeSelf(); event.accepted = true; return; }
        const t = event.text;
        if (t.length === 1 && "0123456789.+-*/".indexOf(t) >= 0) { window.press(t); event.accepted = true; }
    }

    // ── keypad key ─────────────────────────────────────────────────────────
    component KeyButton: Rectangle {
        id: key
        property string label
        property string variant: "num"
        signal action()
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: window.s(48)
        radius: Theme.radiusMd
        color: key.variant === "op" ? Theme.surfaceContainerHigh
             : key.variant === "fn" ? Theme.stateLayer(Theme.mauve, 0.16)
             : Theme.surfaceContainer
        border.width: 1
        border.color: Theme.outlineVariant
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.stateLayer(Theme.text, Theme.stateHover)
            opacity: keyMa.containsMouse ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durShort } }
        }
        Text {
            anchors.centerIn: parent
            text: key.label
            font.family: "Hack Nerd Font"
            font.pixelSize: window.s(18)
            font.weight: Font.Bold
            color: key.variant === "fn" ? Theme.mauve : Theme.text
        }
        MouseArea {
            id: keyMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: key.action()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusXl
        color: Theme.glassFill
        border.width: 1
        border.color: Theme.outlineVariant
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: s(14)
            spacing: s(10)

            // ── header ─────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.gapSm
                Text { text: "\uf1ec"; font.family: "Hack Nerd Font"; font.pixelSize: s(18); color: Theme.mauve }
                Text { Layout.fillWidth: true; text: "Calculator"; font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: s(18); color: Theme.text }

                // copy
                Rectangle {
                    Layout.preferredWidth: s(32)
                    Layout.preferredHeight: s(32)
                    radius: Theme.radiusSm
                    color: copyMa.containsMouse ? Theme.stateLayer(Theme.mauve, 0.18) : "transparent"
                    border.width: 1
                    border.color: Theme.outlineVariant
                    Behavior on color { ColorAnimation { duration: Theme.durShort } }
                    Text { anchors.centerIn: parent; text: "\uf0c5"; font.family: "Hack Nerd Font"; font.pixelSize: s(14); color: copyMa.containsMouse ? Theme.mauve : Theme.subtext0 }
                    MouseArea { id: copyMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: window.copyResult() }
                }
            }

            // ── display ────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: s(96)
                radius: Theme.radiusLg
                color: Theme.surfaceContainerLow
                border.width: 1
                border.color: Theme.outlineVariant
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: s(12)
                    spacing: s(2)
                    Text {
                        Layout.fillWidth: true
                        text: window.expr === "" ? "0" : window.expr
                        font.family: "Hack Nerd Font"
                        font.pixelSize: s(16)
                        color: Theme.subtext0
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideLeft
                        maximumLineCount: 1
                    }
                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: window.result === "" ? " " : window.result
                        font.family: "Hack Nerd Font"
                        font.pixelSize: s(30)
                        font.weight: Font.Black
                        color: window.result === "error" ? Theme.red : Theme.text
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideLeft
                        maximumLineCount: 1
                    }
                }
            }

            // ── keypad ─────────────────────────────────────────────────────
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 4
                columnSpacing: s(8)
                rowSpacing: s(8)

                KeyButton { label: "C"; variant: "fn"; onAction: window.clearAll() }
                KeyButton { label: "\u00b1"; variant: "fn"; onAction: window.toggleSign() }
                KeyButton { label: "%"; variant: "fn"; onAction: window.applyPercent() }
                KeyButton { label: "/"; variant: "op"; onAction: window.press("/") }

                KeyButton { label: "7"; onAction: window.press("7") }
                KeyButton { label: "8"; onAction: window.press("8") }
                KeyButton { label: "9"; onAction: window.press("9") }
                KeyButton { label: "*"; variant: "op"; onAction: window.press("*") }

                KeyButton { label: "4"; onAction: window.press("4") }
                KeyButton { label: "5"; onAction: window.press("5") }
                KeyButton { label: "6"; onAction: window.press("6") }
                KeyButton { label: "-"; variant: "op"; onAction: window.press("-") }

                KeyButton { label: "1"; onAction: window.press("1") }
                KeyButton { label: "2"; onAction: window.press("2") }
                KeyButton { label: "3"; onAction: window.press("3") }
                KeyButton { label: "+"; variant: "op"; onAction: window.press("+") }

                KeyButton { label: "0"; onAction: window.press("0") }
                KeyButton { label: "."; onAction: window.press(".") }
                KeyButton { label: "="; variant: "op"; Layout.columnSpan: 2; onAction: window.compute() }
            }

            // ── history ────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: s(64)
                radius: Theme.radiusMd
                color: Theme.surfaceContainerLow
                border.width: 1
                border.color: Theme.outlineVariant
                clip: true
                visible: historyModel.count > 0

                ListView {
                    id: historyList
                    anchors.fill: parent
                    anchors.margins: s(4)
                    model: historyModel
                    spacing: s(2)
                    clip: true
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    delegate: Rectangle {
                        width: historyList.width
                        height: s(18)
                        radius: Theme.radiusXs
                        color: histMa.containsMouse ? Theme.stateLayer(Theme.mauve, 0.12) : "transparent"
                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: s(6)
                            anchors.rightMargin: s(6)
                            text: model.expr + "  =  " + model.res
                            font.family: "Hack Nerd Font"
                            font.pixelSize: s(11)
                            color: histMa.containsMouse ? Theme.mauve : Theme.subtext0
                            elide: Text.ElideLeft
                            verticalAlignment: Text.AlignVCenter
                        }
                        MouseArea {
                            id: histMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { window.expr = model.expr; window.result = ""; window.evaluated = false; }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: historyModel.count === 0
                text: "qalc when available, else a safe + - * / evaluator"
                font.family: "Hack Nerd Font"
                font.pixelSize: s(10)
                color: Theme.subtext0
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
