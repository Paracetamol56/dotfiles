import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.services

// One notification: app icon (or its image), summary, body, progress bar, action buttons.
// Critical ones get a red strip. Click → default action; × → dismiss. Used by the popups and
// the notification center.
Rectangle {
    id: root

    required property var notification
    // Popups get a solid background and shadow; in the center they sit on a blurred widget
    property bool popup: false

    readonly property var n: notification
    readonly property bool critical: n ? Notifications.isCritical(n) : false
    readonly property real progress: n ? Notifications.progress(n) : -1
    readonly property string imageSource: n?.image || ""
    readonly property string iconSource: n?.appIcon ? Quickshell.iconPath(n.appIcon, true) : ""
    readonly property alias hovered: mouse.containsMouse

    implicitHeight: content.implicitHeight + 24
    radius: Theme.radius
    color: popup ? Qt.alpha(Theme.base, 0.96) : mouse.containsMouse ? Qt.alpha(Theme.surface0, 0.6) : Qt.alpha(Theme.surface0, 0.35)

    Behavior on color {
        ColorAnimation {
            duration: Theme.animDuration
        }
    }

    layer.enabled: popup
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.6)
        blurMax: 16
        shadowBlur: 0.8
        shadowVerticalOffset: 3
    }

    // Critical: red strip on the left
    Rectangle {
        visible: root.critical
        width: 3
        height: parent.height - 16
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        radius: 1.5
        color: Theme.red
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Notifications.invokeDefault(root.n)
    }

    Row {
        id: content
        x: 14
        y: 12
        width: parent.width - 28
        spacing: 12

        // The notification's image (e.g. a screenshot) if it has one, else the app icon
        Item {
            width: 40
            height: 40

            ClippingRectangle {
                anchors.fill: parent
                visible: root.imageSource !== ""
                radius: Theme.radius
                color: "transparent"

                Image {
                    anchors.fill: parent
                    source: root.imageSource
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 80
                    sourceSize.height: 80
                }
            }

            IconImage {
                anchors.centerIn: parent
                visible: root.imageSource === "" && root.iconSource !== ""
                implicitSize: 32
                source: root.iconSource
            }

            Label {
                anchors.centerIn: parent
                visible: root.imageSource === "" && root.iconSource === ""
                text: root.critical ? Icons.bellRing : Icons.bell
                font.family: Icons.font
                font.pixelSize: 20
                color: root.critical ? Theme.red : Theme.mauve
            }
        }

        Column {
            width: parent.width - 52
            spacing: 3

            // App · time, and the dismiss ×
            Item {
                width: parent.width
                height: 14

                Label {
                    anchors.left: parent.left
                    anchors.right: close.left
                    anchors.rightMargin: 8
                    text: [root.n?.appName, root.ago(Notifications.times[root.n?.id])].filter(s => s).join(" · ")
                    font.pixelSize: 10
                    color: Theme.overlay1
                }

                Label {
                    id: close
                    anchors.right: parent.right
                    text: Icons.x
                    font.family: Icons.font
                    font.pixelSize: 13
                    color: closeMouse.containsMouse ? Theme.red : Theme.overlay1

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.dismiss(root.n)
                    }
                }
            }

            Label {
                width: parent.width
                text: root.n?.summary ?? ""
                font.pixelSize: 13
                font.weight: Font.Bold
                color: root.critical ? Theme.red : Theme.text
            }

            Text {
                visible: text !== ""
                width: parent.width
                text: root.n?.body ?? ""
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.subtext1
                linkColor: Theme.blue
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            // Progress (the "value" hint)
            Rectangle {
                visible: root.progress >= 0
                width: parent.width
                height: 5
                radius: 2.5
                color: Qt.alpha(Theme.surface1, 0.8)

                Rectangle {
                    width: parent.width * Math.max(0, root.progress)
                    height: parent.height
                    radius: parent.radius
                    color: Theme.mauve
                }
            }

            // Actions, except the "default" one (that's what clicking the card does)
            Flow {
                visible: actionsRepeater.count > 0
                width: parent.width
                spacing: 6
                topPadding: 4

                Repeater {
                    id: actionsRepeater
                    model: (root.n?.actions ?? []).filter(a => a.identifier !== "default")

                    Button {
                        required property var modelData
                        text: modelData.text
                        height: 26
                        onClicked: {
                            modelData.invoke();
                            Notifications.dismiss(root.n);
                        }
                    }
                }
            }
        }
    }

    function ago(date) {
        if (!date)
            return "";
        const s = (Date.now() - date) / 1000;
        if (s < 60)
            return "now";
        if (s < 3600)
            return `${Math.round(s / 60)} min ago`;
        if (s < 86400)
            return `${Math.round(s / 3600)} h ago`;
        return Qt.formatDateTime(date, "d MMM HH:mm");
    }
}
