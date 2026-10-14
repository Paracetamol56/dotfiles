import QtQuick
import "../bar"

// On/off switch
Rectangle {
    id: root

    property bool checked: false
    signal toggled

    width: 40
    height: 22
    radius: height / 2
    color: checked ? Theme.mauve : Qt.alpha(Theme.surface1, 0.9)

    Behavior on color {
        ColorAnimation {
            duration: Theme.animDuration
        }
    }

    Rectangle {
        width: 16
        height: 16
        radius: 8
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 3 : 3
        color: root.checked ? Theme.base : Theme.subtext0

        Behavior on x {
            NumberAnimation {
                duration: Theme.animDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
