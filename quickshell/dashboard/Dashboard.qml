import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../bar"

// Dashboard modal: dims the screen and drops a card under the bar.
// Opened from the Arch button; closed by clicking outside, Esc, or the button again.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    // modelData, not screen: screen changes while the window maps, which looped this binding
    readonly property bool open: Panels.dashboardScreen === modelData
    // Below the bar: its 10px top margin + its height + a gap
    readonly property int cardTop: 10 + Theme.barHeight + 12

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-dashboard"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    // Stay mapped until the closing animation has finished
    visible: open || card.opacity > 0

    // Dimmed backdrop; clicking it closes the dashboard
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
            onClicked: Panels.closeDashboard()
        }
    }

    Item {
        anchors.fill: parent
        focus: root.open
        Keys.onEscapePressed: Panels.closeDashboard()
    }

    Rectangle {
        id: card

        width: 720
        // Fits the widgets, with the same margin as the sides
        height: astronomy.y + astronomy.height + 28
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.cardTop + (root.open ? 0 : -12)
        radius: Theme.radius
        color: Theme.base
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.97
        transformOrigin: Item.Top

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

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        Column {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 28
            spacing: 6

            BarText {
                readonly property int hour: clock.hours
                readonly property string user: Quickshell.env("USER") ?? ""
                readonly property string name: user.charAt(0).toUpperCase() + user.slice(1)

                textFormat: Text.StyledText
                text: (hour < 6 ? "Good night" : hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening") + `, <font color="${Theme.mauve}">${name}</font>`
                font.pixelSize: 24
                font.weight: Font.Bold
                shadow: false
            }

            BarText {
                text: Qt.formatDate(clock.date, "dddd d MMMM yyyy")
                color: Theme.subtext0
                font.weight: Font.Normal
                shadow: false
            }
        }

        // Widgets, two rows: wide ones on the left, narrow ones filling the right
        MediaPlayer {
            id: media
            blurSource: backdrop
            anchors.top: header.bottom
            anchors.topMargin: 24
            anchors.left: header.left
            width: 460
            height: 170
        }

        Weather {
            blurSource: backdrop
            anchors.top: media.top
            anchors.left: media.right
            anchors.leftMargin: 16
            anchors.right: header.right
            height: media.height
        }

        QuickLaunch {
            id: launch
            blurSource: backdrop
            anchors.top: media.bottom
            anchors.topMargin: 16
            anchors.left: media.left
            width: media.width
            height: 104
        }

        Capture {
            blurSource: backdrop
            anchors.top: launch.top
            anchors.left: launch.right
            anchors.leftMargin: 16
            anchors.right: header.right
            height: launch.height
        }

        Astronomy {
            id: astronomy
            blurSource: backdrop
            anchors.top: launch.bottom
            anchors.topMargin: 16
            anchors.left: header.left
            anchors.right: header.right
            height: 160
        }
    }
}
