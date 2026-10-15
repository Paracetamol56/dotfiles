import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services

// Base for the bar's popups (dashboard, calendar…): dims the screen and drops a card
// under the bar with the dotted backdrop and a title header. Closed by clicking outside,
// Esc, or the bar button again. Content goes in the card, below `header`; widgets should
// set `blurSource: backdrop` (the content shares the backdrop's coordinates).
PanelWindow {
    id: root

    required property var modelData
    // Name used by Panels to open this modal
    required property string name

    property string title: ""
    property string subtitle: ""
    property int cardWidth: 720
    // "center" (under the bar), "middle" (centre of the screen), or "left" / "right" to line
    // up with that edge of the bar (near its button)
    property string align: "center"
    property real cardHeight: 400

    default property alias content: body.data
    // Keys other than Esc, for modals with keyboard controls
    signal keyPressed(var event)
    readonly property Item header: header
    readonly property Item backdrop: backdrop
    // modelData, not screen: screen changes while the window maps, which looped this binding
    readonly property bool open: Panels.current === name && Panels.screen === modelData
    // Below the bar: its 10px top margin + its height + a gap
    readonly property int cardTop: 10 + Theme.barHeight + 12

    screen: modelData
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-" + name
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    // Stay mapped until the closing animation has finished
    visible: open || card.opacity > 0

    // Dimmed backdrop; clicking it closes the modal
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.open ? 0.35 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Panels.close()
        }
    }

    Item {
        anchors.fill: parent
        focus: root.open
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) {
                Panels.close();
                e.accepted = true;
            } else {
                root.keyPressed(e);
            }
        }
    }

    Rectangle {
        id: card

        width: root.cardWidth
        height: root.cardHeight
        // Same 10px side margin as the bar
        x: root.align === "left" ? 10 : root.align === "right" ? parent.width - width - 10 : (parent.width - width) / 2
        y: (root.align === "middle" ? Math.round((parent.height - height) / 2) : root.cardTop) + (root.open ? 0 : -12)
        radius: Theme.radius
        color: Theme.base
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.97
        transformOrigin: root.align === "left" ? Item.TopLeft : root.align === "right" ? Item.TopRight : root.align === "middle" ? Item.Center : Item.Top

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.7)
            blurMax: 32
            shadowBlur: 1
            shadowVerticalOffset: 6
        }

        Backdrop {
            id: backdrop
            anchors.fill: parent
            active: cardMouse.containsMouse
            glowX: cardMouse.mouseX
            glowY: cardMouse.mouseY
        }

        // Swallows clicks so they don't reach the dimmed backdrop, and tracks the cursor for the glow
        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
        }

        // Same origin as the backdrop, so widgets' blur lines up
        Item {
            id: body
            anchors.fill: parent

            Column {
                id: header
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 28
                spacing: 6

                BarText {
                    textFormat: Text.StyledText
                    text: root.title
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    shadow: false
                }

                BarText {
                    text: root.subtitle
                    color: Theme.subtext0
                    font.weight: Font.Normal
                    shadow: false
                }
            }
        }
    }
}
