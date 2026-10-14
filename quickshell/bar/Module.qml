import QtQuick

// One item of the bar: a Lucide icon, a label, a tooltip and mouse actions.
// No background: clickable items show hover by turning lavender.
Item {
    id: root

    property string icon: ""
    property color iconColor: Theme.text
    property string text: ""
    property color textColor: Theme.text
    property int textFormat: Text.PlainText
    property string tooltip: ""
    property int tooltipFormat: Text.PlainText
    property bool clickable: false
    property real padding: Theme.padding
    property real minWidth: 0
    property real maxWidth: Infinity
    property alias label: label
    property alias iconLabel: iconLabel
    readonly property alias hovered: mouse.containsMouse
    readonly property bool highlighted: clickable && mouse.containsMouse

    signal clicked
    signal rightClicked
    signal scrolled(int steps)

    implicitHeight: Theme.pillHeight
    implicitWidth: Math.ceil(Math.min(maxWidth, Math.max(minWidth, content.implicitWidth + padding * 2)))

    Row {
        id: content
        anchors.centerIn: parent
        spacing: iconLabel.visible && label.visible ? 8 : 0

        BarText {
            id: iconLabel
            anchors.verticalCenter: parent.verticalCenter
            visible: text !== ""
            text: root.icon
            color: root.highlighted ? Theme.lavender : root.iconColor
            font.family: Icons.font
            font.pixelSize: Theme.iconSize
            font.weight: Font.Normal
        }

        BarText {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            visible: text !== ""
            // Only capped when maxWidth is set, so the width never depends on itself
            width: Math.min(implicitWidth, root.maxWidth - root.padding * 2 - (iconLabel.visible ? iconLabel.implicitWidth + content.spacing : 0))
            text: root.text
            textFormat: root.textFormat
            elide: Text.ElideRight
            color: root.highlighted ? Theme.lavender : root.textColor
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: e => e.button === Qt.RightButton ? root.rightClicked() : root.clicked()
        onWheel: w => {
            if (w.angleDelta.y !== 0)
                root.scrolled(w.angleDelta.y > 0 ? 1 : -1);
        }
    }

    Tooltip {
        target: root
        hovered: mouse.containsMouse
        text: root.tooltip
        textFormat: root.tooltipFormat
    }
}
