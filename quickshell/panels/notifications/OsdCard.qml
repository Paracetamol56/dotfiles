import QtQuick
import QtQuick.Effects
import qs.common
import qs.components
import qs.services

// Volume / keyboard-layout feedback (services/Osd.qml) drawn like a notification popup:
// icon, "Sound · device" header, bold title, and a level bar for the volume.
Rectangle {
    id: root

    readonly property bool isVolume: Osd.kind === "volume"

    implicitHeight: content.implicitHeight + 24
    radius: Theme.radius
    color: Qt.alpha(Theme.base, 0.96)

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.6)
        blurMax: 16
        shadowBlur: 0.8
        shadowVerticalOffset: 3
    }

    Row {
        id: content
        x: 14
        y: 12
        width: parent.width - 28
        spacing: 12

        Item {
            width: 40
            height: 40

            Label {
                anchors.centerIn: parent
                text: !root.isVolume ? Icons.keyboard : Osd.muted ? Icons.volumeX : Osd.volume < 0.01 ? Icons.volume : Osd.volume < 0.5 ? Icons.volume1 : Icons.volume2
                font.family: Icons.font
                font.pixelSize: 22
                color: root.isVolume && Osd.muted ? Theme.overlay1 : Theme.accent
            }
        }

        Column {
            width: parent.width - 52
            spacing: 3

            Label {
                width: parent.width
                text: root.isVolume ? `Sound · ${Osd.device}` : "Keyboard"
                font.pixelSize: 10
                color: Theme.overlay1
            }

            Label {
                width: parent.width
                text: !root.isVolume ? Keyboard.current.name : Osd.muted ? "Muted" : `Volume ${Math.round(Osd.volume * 100)}%`
                font.pixelSize: 13
                font.weight: Font.Bold
                color: root.isVolume && Osd.volume > 1 && !Osd.muted ? Theme.peach : Theme.text
            }

            // Level, up to 150%, with a mark at 100%
            Item {
                visible: root.isVolume
                width: parent.width
                height: 9

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 5
                    radius: 2.5
                    color: Qt.alpha(Theme.surface1, 0.8)

                    Rectangle {
                        width: parent.width * Math.min(Osd.volume, 1.5) / 1.5
                        height: parent.height
                        radius: parent.radius
                        color: Osd.muted ? Theme.overlay0 : Osd.volume > 1 ? Theme.peach : Theme.accent

                        Behavior on width {
                            NumberAnimation {
                                duration: 120
                            }
                        }
                    }
                }

                Rectangle {
                    x: parent.width / 1.5 - 1
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2
                    height: 9
                    radius: 1
                    color: Theme.overlay1
                }
            }
        }
    }
}
