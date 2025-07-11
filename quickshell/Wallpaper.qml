import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "widgets"

PanelWindow {
    property var modelData
    screen: modelData

    aboveWindows: false
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Background

    anchors {
        top: true
        left: true
        bottom: true
        right: true
    }

    // Background image
    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("./assets/crane_bg.png")
        fillMode: Image.PreserveAspectCrop
        z: 0
    }

    // Centered clock
    Clock {
      anchors.centerIn: parent
      anchors.verticalCenterOffset: -400
      z: 1
    }

    // Foreground image
    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("./assets/crane_fg.png")
        fillMode: Image.PreserveAspectCrop
        z: 2
    }
}
