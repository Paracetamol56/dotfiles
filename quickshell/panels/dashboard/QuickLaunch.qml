import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.components
import qs.services

// Pinned apps, launched from their desktop entries (real app icons, not Lucide)
Widget {
    id: root

    // Desktop entry ids, i.e. /usr/share/applications/<id>.desktop
    property var apps: ["kitty", "zen", "thunar", "obsidian", "spotify", "discord", "signal", "io.element.Element"]

    Row {
        anchors.centerIn: parent

        Repeater {
            model: root.apps

            Item {
                id: app

                required property string modelData
                readonly property DesktopEntry entry: DesktopEntries.byId(modelData)

                visible: entry !== null
                width: (root.width - root.padding * 2) / root.apps.length
                height: 76

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Theme.radius
                    color: appMouse.containsMouse ? Qt.alpha(Theme.surface1, 0.6) : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animDuration
                        }
                    }
                }

                IconImage {
                    id: icon
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 10
                    implicitSize: 34
                    source: Quickshell.iconPath(app.entry?.icon ?? "", "application-x-executable")
                    scale: appMouse.containsMouse ? 1.08 : 1

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Label {
                    anchors.top: icon.bottom
                    anchors.topMargin: 7
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(implicitWidth, parent.width - 6)
                    text: app.entry?.name ?? ""
                    font.pixelSize: 10
                    color: appMouse.containsMouse ? Theme.lavender : Theme.subtext1
                }

                MouseArea {
                    id: appMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        app.entry.execute();
                        Panels.close();
                    }
                }
            }
        }
    }
}
