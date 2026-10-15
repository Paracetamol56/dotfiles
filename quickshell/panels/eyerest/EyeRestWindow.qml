import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.components
import qs.services

// The eye-rest overlay on one screen (services/EyeRest.qml): a blurred snapshot of the screen
// (taken as it appears; Hyprland's blur is off), tinted, with 休憩 and a 20-second countdown. Never takes the
// keyboard; a click anywhere dismisses it on every screen.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-eyerest"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
    visible: EyeRest.shown || tint.opacity > 0

    property int remaining: EyeRest.breakSeconds

    Connections {
        target: EyeRest
        function onShownChanged() {
            if (EyeRest.shown) {
                root.remaining = EyeRest.breakSeconds;
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: EyeRest.shown && root.remaining > 0
        onTriggered: root.remaining--
    }

    // What's on the screen, blurred. Created each time the overlay opens, so its one frame is
    // taken then; it stays drawn (under the blur) so it gets a capture context
    Loader {
        id: snapshot
        anchors.fill: parent
        active: root.visible
        opacity: tint.opacity

        sourceComponent: ScreencopyView {
            captureSource: root.modelData
            live: false
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: snapshot.item
        blurEnabled: true
        blurMax: 64
        blur: 1
        opacity: tint.opacity
    }

    Rectangle {
        id: tint
        anchors.fill: parent
        color: Qt.alpha(Theme.crust, 0.55)
        opacity: EyeRest.shown ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: EyeRest.dismiss()
    }

    Column {
        anchors.centerIn: parent
        spacing: 14
        opacity: tint.opacity
        scale: 0.96 + 0.04 * tint.opacity

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "休憩"
            font.family: "Noto Sans CJK JP"
            font.pixelSize: 72
            font.weight: Font.Light
            color: Theme.accent
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.remaining > 0 ? "Rest your eyes" : "Well rested"
            font.pixelSize: 34
            font.weight: Font.Bold
            color: Theme.text
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Look at something about 6 metres away for 20 seconds."
            font.pixelSize: 16
            color: Theme.subtext0
        }

        // Countdown: seconds left and a draining bar
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320
            height: 70

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 12
                text: root.remaining > 0 ? root.remaining : "✓"
                font.pixelSize: 28
                font.weight: Font.Bold
                color: root.remaining > 0 ? Theme.text : Theme.green
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 4
                radius: 2
                color: Qt.alpha(Theme.surface1, 0.8)

                Rectangle {
                    width: parent.width * root.remaining / EyeRest.breakSeconds
                    height: parent.height
                    radius: parent.radius
                    color: Theme.accent

                    Behavior on width {
                        NumberAnimation {
                            duration: 1000
                        }
                    }
                }
            }
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 10
            text: root.remaining > 0 ? "Click anywhere to skip" : "Click anywhere to get back to work"
            font.pixelSize: 12
            color: Theme.overlay1
        }
    }
}
