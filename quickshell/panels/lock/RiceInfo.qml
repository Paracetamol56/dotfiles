import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.components
import qs.services

// The rice as a spec sheet printed on the lock screen's wallpaper: kanji header, the stack with
// versions, the last commit of ~/.config (with a barcode drawn from its hash) and the palette.
// No card: thin lines, separators and small mono labels on the background.
Item {
    id: root

    // From `info` below: { hyprland, quickshell, kitty, kernel, when, date, subject, hash }
    property var info: ({})

    readonly property var accents: ["rosewater", "flamingo", "pink", "mauve", "red", "maroon", "peach",
        "yellow", "green", "teal", "sky", "sapphire", "blue", "lavender"]
    readonly property string accent: Theme.choice.accent ?? "mauve"
    readonly property string flavor: Theme.choice.flavor ?? "mocha"
    readonly property string flavorName: ({ latte: "Latte", frappe: "Frappé", macchiato: "Macchiato", mocha: "Mocha" })[flavor] ?? flavor
    readonly property color line: Qt.alpha(Theme.overlay0, 0.5)

    implicitWidth: 470
    implicitHeight: sheet.implicitHeight

    Process {
        running: true
        command: ["sh", "-c", 'printf "hyprland=%s\\n" "$(hyprctl version -j | jq -r .version)"; '
            + 'printf "quickshell=%s\\n" "$(qs --version | cut -d" " -f2)"; '
            + 'printf "kitty=%s\\n" "$(kitty --version | cut -d" " -f2)"; '
            + 'printf "kernel=%s\\n" "$(uname -r)"; '
            + 'git -C "$HOME/.config" log -1 --format="when=%cr%ndate=%cd%nsubject=%s%nhash=%H" --date=format:"%Y.%m.%d %H:%M"']
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0)
                        out[line.slice(0, i)] = line.slice(i + 1);
                }
                root.info = out;
            }
        }
    }

    // Small spaced-out mono label, e.g. "SYS.INFO // 01"
    component Tag: Label {
        font.pixelSize: 11
        font.letterSpacing: 2
        color: Theme.overlay1
    }

    // Full-width hairline with a short accent lead
    component Rule: Item {
        width: parent.width
        height: 2

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 1
            color: root.line
        }

        Rectangle {
            width: 36
            height: 2
            color: Theme.accent
        }
    }

    // Vertical katakana along the left edge: "dotfiles"
    Column {
        id: spine
        anchors.top: sheet.top
        anchors.bottom: sheet.bottom
        width: 22
        spacing: 2

        Repeater {
            model: ["ド", "ッ", "ト", "フ", "ァ", "イ", "ル"]

            Label {
                required property string modelData
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData
                font.family: "Noto Sans CJK JP"
                font.pixelSize: 15
                font.weight: Font.Light
                // Vertical forms: small ッ and ァ sit top-right, as in vertical writing
                font.features: { "vert": 1 }
                color: Theme.overlay1
            }
        }

        // The spine continues as a line down to the bottom
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 1
            height: spine.height - y
            color: root.line
        }
    }

    Column {
        id: sheet
        anchors.left: spine.right
        anchors.leftMargin: 18
        anchors.right: parent.right
        spacing: 14

        // ── Header: 環境 + labels ─────────────────────────
        Item {
            width: parent.width
            height: kanji.implicitHeight

            Label {
                id: kanji
                text: "環境"
                font.family: "Noto Sans CJK JP"
                font.pixelSize: 56
                font.weight: Font.Light
                color: Theme.accent
            }

            Column {
                anchors.left: kanji.right
                anchors.leftMargin: 16
                anchors.verticalCenter: kanji.verticalCenter
                spacing: 4

                Tag {
                    text: "SYS.INFO // システム情報"
                }

                Label {
                    text: Distro.name || "Linux"
                    font.pixelSize: 22
                    font.weight: Font.Bold
                    color: Theme.text
                }

                Label {
                    text: `Catppuccin ${root.flavorName} · ${root.accent}`
                    font.pixelSize: 13
                    color: Theme.subtext0
                }
            }

            Label {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 6
                text: Distro.icon
                font.family: Theme.fontFamily
                font.pixelSize: 40
                color: Qt.alpha(Theme.accent, 0.85)
            }
        }

        Rule {}

        // ── Stack: 01 COMPOSITOR ....... Hyprland 0.56.2 ──
        Column {
            width: parent.width
            spacing: 0

            Repeater {
                model: [
                    ["COMPOSITOR", "Hyprland", root.info.hyprland],
                    ["SHELL", "Quickshell", root.info.quickshell],
                    ["TERMINAL", "kitty", root.info.kitty],
                    ["PROMPT", "zsh + starship", ""],
                    ["KERNEL", "Linux", root.info.kernel]
                ]

                Item {
                    id: row
                    required property var modelData
                    required property int index
                    width: parent.width
                    height: 30

                    Label {
                        id: num
                        anchors.verticalCenter: parent.verticalCenter
                        text: String(row.index + 1).padStart(2, "0")
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: Theme.accent
                    }

                    Tag {
                        id: key
                        anchors.left: num.right
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData[0]
                    }

                    // Dotted leader between the key and the value
                    Row {
                        anchors.left: key.right
                        anchors.leftMargin: 10
                        anchors.right: value.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        clip: true

                        Repeater {
                            model: 60

                            Rectangle {
                                width: 2
                                height: 1
                                color: root.line
                            }
                        }
                    }

                    Row {
                        id: value
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Label {
                            text: row.modelData[1]
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            color: Theme.text
                        }

                        Label {
                            visible: text !== ""
                            text: row.modelData[2] ?? ""
                            font.pixelSize: 15
                            color: Theme.accent
                        }
                    }
                }
            }
        }

        Rule {}

        // ── Last update + barcode of the commit hash ──────
        Item {
            width: parent.width
            height: Math.max(updateText.implicitHeight, barcode.height + hashText.implicitHeight + 4)

            Column {
                id: updateText
                width: parent.width - barcode.width - 20
                spacing: 4

                Tag {
                    text: "LAST UPDATE // 更新"
                }

                Label {
                    text: root.info.when ?? "—"
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: Theme.text
                }

                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.info.subject ?? ""
                    font.pixelSize: 13
                    color: Theme.subtext0
                }

                Label {
                    text: root.info.date ?? ""
                    font.pixelSize: 11
                    color: Theme.overlay1
                }
            }

            // One bar per hex digit of the hash: its value sets the bar and gap widths
            Row {
                id: barcode
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 4
                height: 52
                spacing: 0

                Repeater {
                    model: (root.info.hash ?? "0000000000000000000000000000000000000000").slice(0, 32).split("")

                    Item {
                        required property string modelData
                        readonly property int v: parseInt(modelData, 16) || 0
                        width: bar.width + 1 + ((v >> 2) & 1) * 2
                        height: barcode.height

                        Rectangle {
                            id: bar
                            width: 1 + (v & 3)
                            height: parent.height
                            color: Theme.text
                            opacity: 0.85
                        }
                    }
                }
            }

            Label {
                id: hashText
                anchors.horizontalCenter: barcode.horizontalCenter
                anchors.top: barcode.bottom
                anchors.topMargin: 4
                text: (root.info.hash ?? "").slice(0, 12).toUpperCase()
                font.pixelSize: 10
                font.letterSpacing: 3
                color: Theme.overlay1
            }
        }

        Rule {}

        // ── Palette: tall bars, the active accent lifted, with its hex ─
        Item {
            width: parent.width
            height: 66

            Tag {
                id: paletteTag
                text: "PALETTE // 配色"
            }

            Label {
                anchors.right: parent.right
                anchors.baseline: paletteTag.baseline
                text: `${root.accent.toUpperCase()}  ${Theme.palette[root.accent] ?? ""}`
                font.pixelSize: 11
                font.letterSpacing: 2
                color: Theme.accent
            }

            Row {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 40
                spacing: 3

                Repeater {
                    model: root.accents

                    Rectangle {
                        required property string modelData
                        readonly property bool active: root.accent === modelData
                        anchors.bottom: parent.bottom
                        width: (parent.width - parent.spacing * (root.accents.length - 1)) / root.accents.length
                        height: active ? 40 : 28
                        radius: 2
                        color: Theme.palette[modelData] ?? Theme.accent
                    }
                }
            }
        }
    }
}
