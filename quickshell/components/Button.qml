import QtQuick
import qs.common

// Small rounded button: icon, optional text; `filled` for the main action
Rectangle {
    id: button

    property string icon
    property string text: ""
    property bool filled: false
    // Highlighted, e.g. while a scan it started is running
    property bool checked: false
    // Shown on hover, e.g. for icon-only buttons
    property string tooltip: ""
    property bool enabled: true
    signal clicked

    width: content.implicitWidth + (text ? 24 : 16)
    height: 30
    radius: Theme.radius
    opacity: enabled ? 1 : 0.4
    color: filled ? (mouse.containsMouse ? Theme.lavender : Theme.accent) : checked ? Qt.alpha(Theme.accent, 0.25) : (mouse.containsMouse ? Qt.alpha(Theme.surface1, 0.8) : Qt.alpha(Theme.surface0, 0.8))

    Behavior on color {
        ColorAnimation {
            duration: Theme.animDuration
        }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 8

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: button.icon
            font.family: Icons.font
            font.pixelSize: 14
            color: button.filled ? Theme.base : button.checked ? Theme.accent : Theme.text
        }

        Label {
            visible: button.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: button.text
            font.weight: Font.Bold
            color: button.filled ? Theme.base : Theme.text
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        // Hover stays on when disabled, so the tooltip can still explain why
        cursorShape: button.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (button.enabled) button.clicked()
    }

    Tooltip {
        target: button
        hovered: mouse.containsMouse
        text: button.tooltip
    }
}
