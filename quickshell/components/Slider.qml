import QtQuick
import qs.common

// Volume slider, 0..max (1 = 100%). Past 100% the fill turns peach and a tick marks 100%.
// Drag or click to set, scroll for 2% steps.
Item {
    id: root

    property real value: 0
    property real max: 1
    property color accent: Theme.mauve
    property bool muted: false
    signal moved(real value)

    implicitHeight: 18

    function set(v) {
        moved(Math.max(0, Math.min(max, Math.round(v * 100) / 100)));
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Qt.alpha(Theme.surface1, 0.8)

        // Up to 100%
        Rectangle {
            width: track.width * Math.min(root.value, 1) / root.max
            height: parent.height
            radius: parent.radius
            color: root.muted ? Theme.overlay0 : root.accent
        }

        // Beyond 100%
        Rectangle {
            visible: root.value > 1
            x: track.width / root.max
            width: track.width * (root.value - 1) / root.max
            height: parent.height
            radius: parent.radius
            color: root.muted ? Theme.overlay0 : Theme.peach
        }

        // 100% mark
        Rectangle {
            visible: root.max > 1
            x: track.width / root.max - 1
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: 10
            radius: 1
            color: Theme.overlay1
        }
    }

    Rectangle {
        visible: mouse.containsMouse || mouse.pressed
        x: track.width * Math.min(root.value, root.max) / root.max - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 12
        height: 12
        radius: 6
        color: Theme.lavender
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.topMargin: -4
        anchors.bottomMargin: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: m => root.set(m.x / width * root.max)
        onPositionChanged: m => {
            if (pressed)
                root.set(m.x / width * root.max);
        }
        onWheel: w => root.set(root.value + (w.angleDelta.y > 0 ? 0.02 : -0.02))
    }
}
