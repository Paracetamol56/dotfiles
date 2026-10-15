import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Zen mode's black on one screen (services/Zen.qml). On the zen window's monitor it sits under
// the windows, in place of the wallpaper; on the others it covers everything and swallows
// clicks, so nothing there can be reached. Never takes the keyboard.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    readonly property bool main: modelData.name === Zen.monitor

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: main ? WlrLayer.Bottom : WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-zen"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
    visible: Zen.active || black.opacity > 0

    Rectangle {
        id: black
        anchors.fill: parent
        color: "black"
        opacity: Zen.active ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
    }
}
