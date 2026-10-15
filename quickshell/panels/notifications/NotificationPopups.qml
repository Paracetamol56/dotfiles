import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common
import qs.components
import qs.services

// Notification popups, top right under the bar, on the focused monitor.
// Never takes the keyboard, and only the cards themselves catch the mouse (input mask), so
// the rest of the screen stays clickable. Each card hides after its timeout, paused on hover.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    readonly property bool focusedScreen: Hyprland.focusedMonitor?.name === modelData.name

    anchors {
        top: true
        right: true
    }
    margins {
        // Same spot as the right-aligned panels: under the bar, at its right edge
        top: 10 + Theme.barHeight + 12
        right: 10
    }
    implicitWidth: 380
    implicitHeight: Math.max(1, stack.implicitHeight)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notification-popups"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
    visible: focusedScreen && Notifications.popups.length > 0

    mask: Region {
        item: stack
    }

    Column {
        id: stack
        width: parent.width
        spacing: 8

        Repeater {
            model: Notifications.popups

            NotificationCard {
                id: card

                required property var modelData
                notification: modelData
                popup: true
                width: stack.width

                // Slide in from the right
                opacity: 0
                transform: Translate {
                    id: slide
                    x: 40
                }
                Component.onCompleted: appear.start()

                ParallelAnimation {
                    id: appear
                    NumberAnimation {
                        target: card
                        property: "opacity"
                        to: 1
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: slide
                        property: "x"
                        to: 0
                        duration: 260
                        easing.type: Easing.OutCubic
                    }
                }

                // Hide (not dismiss: it stays in the history) after the timeout; hover pauses it
                Timer {
                    interval: Notifications.timeout(card.notification)
                    running: interval > 0 && !card.hovered
                    onTriggered: Notifications.hidePopup(card.notification)
                }
            }
        }
    }
}
