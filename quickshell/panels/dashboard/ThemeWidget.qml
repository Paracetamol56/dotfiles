import QtQuick
import Quickshell
import qs.common
import qs.components

// Theme + lighting: Catppuccin flavor squares, accent dots and the LED brightness. Runs
// ~/.config/theme/apply.py, so everything switches (Hyprland, kitty, starship, btop, fastfetch,
// Qt, the RGB LEDs); the shell itself recolours live from theme.json.
Widget {
    id: root

    readonly property var flavors: [
        { key: "latte", name: "Latte" }, { key: "frappe", name: "Frappé" },
        { key: "macchiato", name: "Macchiato" }, { key: "mocha", name: "Mocha" }
    ]
    readonly property var accents: ["rosewater", "flamingo", "pink", "mauve", "red", "maroon", "peach",
        "yellow", "green", "teal", "sky", "sapphire", "blue", "lavender"]
    readonly property string flavor: Theme.choice.flavor ?? "mocha"
    readonly property string accent: Theme.choice.accent ?? "mauve"
    readonly property int tileSize: 58

    // LED brightness 0..1. While dragging, the slider's own value; applied once it settles
    property real ledDraft: -1
    readonly property real led: ledDraft >= 0 ? ledDraft : (Theme.choice.led ?? 100) / 100

    function apply(flavor, accent) {
        Quickshell.execDetached(["python3", Theme.themeDir + "/apply.py", flavor, accent]);
    }

    Timer {
        id: ledApply
        interval: 500
        onTriggered: {
            Quickshell.execDetached(["python3", Theme.themeDir + "/apply.py", "--led", String(Math.round(root.ledDraft * 100))]);
        }
    }

    // theme.json caught up with the draft: follow it again
    Connections {
        target: Theme
        function onChoiceChanged() {
            if (!ledApply.running && Math.round(root.ledDraft * 100) === (Theme.choice.led ?? 100))
                root.ledDraft = -1;
        }
    }

    Column {
        anchors.fill: parent
        spacing: 10

        Row {
            id: topRow
            width: parent.width
            height: root.tileSize
            spacing: 8

            // One square per flavor, previewing its colours with the current accent
            Repeater {
                model: root.flavors

                Rectangle {
                    id: tile
                    required property var modelData
                    readonly property bool active: root.flavor === modelData.key
                    readonly property var pal: Theme.palettes[modelData.key] ?? ({})

                    width: root.tileSize
                    height: root.tileSize
                    radius: Theme.radius
                    color: pal.base ?? Theme.base
                    border.width: active ? 2 : 1
                    border.color: active ? Theme.accent : tileMouse.containsMouse ? Theme.overlay0 : Theme.surface1

                    // Accent dot and a surface bar, in this flavor's colours
                    Rectangle {
                        x: 7
                        y: 7
                        width: 10
                        height: 10
                        radius: 5
                        color: tile.pal[root.accent] ?? Theme.accent
                    }

                    Rectangle {
                        x: 21
                        y: 9
                        width: tile.width - 28
                        height: 6
                        radius: 3
                        color: tile.pal.surface1 ?? Theme.surface1
                    }

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 5
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 4
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: tile.modelData.name
                        font.pixelSize: 9
                        font.weight: tile.active ? Font.Bold : Font.Normal
                        color: tile.pal.text ?? Theme.text
                    }

                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.apply(tile.modelData.key, root.accent)
                    }
                }
            }

            // LED brightness, filling the rest of the row
            Column {
                width: topRow.width - (root.tileSize + topRow.spacing) * 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Item {
                    width: parent.width
                    height: ledLabel.implicitHeight

                    Label {
                        id: ledLabel
                        text: Icons.lightbulb
                        font.family: Icons.font
                        font.pixelSize: 14
                        // What the LEDs get: Latte's accent, the most saturated
                        color: Theme.palettes.latte?.[root.accent] ?? Theme.accent
                    }

                    Label {
                        anchors.left: ledLabel.right
                        anchors.leftMargin: 6
                        anchors.verticalCenter: ledLabel.verticalCenter
                        text: "Lighting"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.subtext1
                    }

                    Label {
                        anchors.right: parent.right
                        anchors.verticalCenter: ledLabel.verticalCenter
                        text: root.led > 0 ? Math.round(root.led * 100) + "%" : "Off"
                        font.pixelSize: 11
                        color: Theme.subtext0
                    }
                }

                Slider {
                    width: parent.width
                    value: root.led
                    accent: Theme.palettes.latte?.[root.accent] ?? Theme.accent
                    onMoved: v => {
                        root.ledDraft = v;
                        ledApply.restart();
                    }
                }
            }
        }

        // Accents as they look in the current flavor
        Row {
            id: accentRow
            width: parent.width
            spacing: (width - 24 * root.accents.length) / (root.accents.length - 1)

            Repeater {
                model: root.accents

                Rectangle {
                    id: swatch
                    required property string modelData
                    readonly property bool active: root.accent === modelData

                    width: 24
                    height: 24
                    radius: 12
                    color: "transparent"
                    border.width: active ? 2 : 0
                    border.color: Theme.text

                    Rectangle {
                        anchors.centerIn: parent
                        width: swatch.active ? 16 : swatchMouse.containsMouse ? 20 : 18
                        height: width
                        radius: width / 2
                        color: Theme.palette[swatch.modelData] ?? Theme.accent

                        Behavior on width {
                            NumberAnimation {
                                duration: Theme.animDuration
                            }
                        }
                    }

                    MouseArea {
                        id: swatchMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.apply(root.flavor, swatch.modelData)
                    }

                    Tooltip {
                        target: swatch
                        hovered: swatchMouse.containsMouse
                        text: swatch.modelData
                    }
                }
            }
        }
    }
}
