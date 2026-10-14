import QtQuick
import Quickshell

// Hover tooltip shown just under the bar, centred on its target
PopupWindow {
    id: root

    required property Item target
    property bool hovered: false
    property string text: ""
    property int textFormat: Text.PlainText

    anchor.item: target
    anchor.rect.width: target.width
    anchor.rect.height: target.height
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    visible: delay.ready && hovered && text !== ""
    color: "transparent"
    implicitWidth: box.width
    implicitHeight: box.height + gap

    readonly property int gap: 6

    Timer {
        id: delay
        property bool ready: false
        interval: 350
        running: root.hovered
        onTriggered: ready = true
    }
    onHoveredChanged: if (!hovered) delay.ready = false

    Rectangle {
        id: box
        y: root.gap
        width: label.implicitWidth + 16
        height: label.implicitHeight + 10
        radius: 6
        color: Theme.base
        border.color: Theme.surface1
        border.width: 1

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            textFormat: root.textFormat
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }
}
