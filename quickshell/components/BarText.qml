import QtQuick
import QtQuick.Effects
import qs.common

Text {
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Font.DemiBold
    verticalAlignment: Text.AlignVCenter

    Behavior on color {
        ColorAnimation {
            duration: Theme.animDuration
        }
    }

    property bool shadow: true
    layer.enabled: shadow
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 1)
        blurMax: 12
        shadowBlur: 0.75
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
    }
}
