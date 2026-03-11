
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "widgets"

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bgWindow
            required property var modelData
            screen: modelData

            aboveWindows: false
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Background

            anchors {
                top:    true
                left:   true
                bottom: true
                right:  true
            }

            Clock {
                anchors.centerIn:         parent
                anchors.verticalCenterOffset: 400
                z: 1
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Bar {
            id: barWindow
            required property var modelData
            screen: modelData
        }
    }
}

