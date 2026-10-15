import QtQuick
import qs.common
import qs.components

// The joke: Windows' "Activate Windows" watermark, for Linux. Bottom right, half-transparent
// grey, like the original. LockSurface slides it in and out, mirroring the rice info.
Column {
    spacing: 2

    Label {
        text: "Activate Linux"
        font.family: "Noto Sans"
        font.pixelSize: 24
        font.weight: Font.Light
        color: Qt.rgba(1, 1, 1, 0.45)
    }

    Label {
        text: "Go to Settings to activate Linux."
        font.family: "Noto Sans"
        font.pixelSize: 14
        color: Qt.rgba(1, 1, 1, 0.45)
    }
}
