import QtQuick
import "../bar"

// Icon, label and value on one line; hover shows `tooltip` if set
Item {
    id: reading

    property string icon
    property color iconColor
    property string label
    property string value
    property int valueFormat: Text.PlainText
    property int valueSize: 10
    property string tooltip: ""
    property int labelWidth: 80

    width: parent.width
    implicitHeight: line.implicitHeight

    Row {
        id: line
        width: parent.width
        spacing: 8

        Label {
            width: 14
            anchors.verticalCenter: parent.verticalCenter
            text: reading.icon
            font.family: Icons.font
            font.pixelSize: 12
            color: reading.iconColor
        }

        Label {
            width: reading.labelWidth
            anchors.verticalCenter: parent.verticalCenter
            text: reading.label
            font.pixelSize: 10
            color: Theme.overlay1
        }

        Label {
            width: parent.width - 14 - reading.labelWidth - parent.spacing * 2
            anchors.verticalCenter: parent.verticalCenter
            text: reading.value
            textFormat: reading.valueFormat
            font.pixelSize: reading.valueSize
            color: Theme.text
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: reading.tooltip !== ""
    }

    Tooltip {
        target: reading
        hovered: hover.containsMouse
        text: reading.tooltip
    }
}
