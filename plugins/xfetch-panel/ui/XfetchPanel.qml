import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

// XFetch Panel — an xfetch-style system fetch inside the shell: a logo, a
// monospace field list (key CAPS → value) and the live palette strip. Opened
// with `qs_manager.sh toggle xfetch`.
Item {
    id: window
    focus: true

    Scaler { id: sc; currentWidth: Screen.width }
    function s(v) { return sc.s(v); }

    property var info: []
    readonly property var pal: [Theme.color0, Theme.color1, Theme.color2, Theme.color3,
                                Theme.color4, Theme.color5, Theme.color6, Theme.color7,
                                Theme.color8, Theme.color9, Theme.color10, Theme.color11,
                                Theme.color12, Theme.color13, Theme.color14, Theme.color15]
    function val(k) { for (let i = 0; i < window.info.length; i++) if (window.info[i].k === k) return window.info[i].v; return ""; }

    Process {
        id: reader
        command: ["bash", Quickshell.env("HOME") + "/.config/hypr/plugins/xfetch-panel/scripts/fetch-info.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = [];
                (this.text || "").trim().split("\n").forEach(l => {
                    let i = l.indexOf("|");
                    if (i > 0) out.push({ k: l.slice(0, i), v: l.slice(i + 1) });
                });
                window.info = out;
            }
        }
    }
    Component.onCompleted: reader.running = true

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusXl
        color: Theme.glassFill
        border.width: 1
        border.color: Theme.outlineVariant

        RowLayout {
            anchors.fill: parent
            anchors.margins: s(22)
            spacing: s(22)

            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                spacing: s(6)
                Text { Layout.alignment: Qt.AlignHCenter; text: "󰣇"; font.family: "Hack Nerd Font"; font.pixelSize: s(72); color: Theme.mauve }
                Text { Layout.alignment: Qt.AlignHCenter; text: window.val("user"); font.family: "Hack Nerd Font"; font.pixelSize: s(13); font.bold: true; color: Theme.text }
            }

            Rectangle { Layout.fillHeight: true; width: 1; color: Theme.outlineVariant }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: s(7)

                Repeater {
                    model: window.info
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: s(10)
                        Text {
                            text: modelData.k.toUpperCase()
                            Layout.preferredWidth: s(74)
                            font.family: "Hack Nerd Font"; font.pixelSize: s(10); font.letterSpacing: 1.3
                            color: Theme.subtext0
                        }
                        Text {
                            text: modelData.v
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            font.family: "Hack Nerd Font"; font.pixelSize: s(12)
                            color: Theme.text
                        }
                    }
                }

                Row {
                    Layout.topMargin: s(8)
                    spacing: s(3)
                    Repeater {
                        model: window.pal
                        delegate: Rectangle {
                            required property var modelData
                            width: s(18); height: s(18); radius: Theme.radiusXs
                            color: modelData
                            border.width: 1; border.color: Theme.outlineVariant
                        }
                    }
                }
            }
        }
    }
}
