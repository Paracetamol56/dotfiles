import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.common

// Base for dashboard widgets: a blurred copy of what's behind it (CSS backdrop-filter: blur),
// then a crust layer at 50%. The content itself stays opaque.
Item {
    id: root

    default property alias content: inner.data
    property real padding: 14
    // What to blur behind the widget; must share the widget's parent and fill it (the card backdrop)
    property Item blurSource: null

    // Grab a margin around the widget so the blur doesn't fade to transparent at its edges
    readonly property int blurMargin: 32

    // Small drop shadow. The shape is the card's own colour, so only the shadow shows
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.base
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.6)
            blurMax: 16
            shadowBlur: 0.7
            shadowVerticalOffset: 2
            shadowHorizontalOffset: 0
        }
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: "transparent"

        // A hidden ShaderEffectSource never updates, so the copy stays visible
        // and the blur is applied as a layer effect on its wrapper
        Item {
            visible: root.blurSource !== null
            x: -root.blurMargin
            y: -root.blurMargin
            width: root.width + root.blurMargin * 2
            height: root.height + root.blurMargin * 2
            layer.enabled: visible
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: 32
                blur: 0.7
            }

            ShaderEffectSource {
                anchors.fill: parent
                sourceItem: root.blurSource
                sourceRect: Qt.rect(root.x - root.blurMargin, root.y - root.blurMargin, root.width + root.blurMargin * 2, root.height + root.blurMargin * 2)
                live: true
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Theme.crust, 0.5)
        }
    }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: root.padding
    }
}
