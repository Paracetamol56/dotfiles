import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common
import qs.services

// Volume / layout feedback card (OsdCard, notification look) at the bottom centre of the
// focused monitor. Click-through and never takes the keyboard.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    anchors.bottom: true
    margins.bottom: 80
    implicitWidth: 360
    implicitHeight: card.implicitHeight + 16
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
    visible: Hyprland.focusedMonitor?.name === modelData.name && (Osd.shown || card.opacity > 0)

    // Click-through: an empty input region
    mask: Region {}

    OsdCard {
        id: card
        width: parent.width
        opacity: Osd.shown ? 1 : 0
        scale: Osd.shown ? 1 : 0.95

        Behavior on opacity {
            NumberAnimation {
                duration: 180
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
    }
}
