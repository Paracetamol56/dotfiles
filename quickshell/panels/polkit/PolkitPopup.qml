import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common
import qs.components
import qs.services

// Polkit password prompt, styled like a notification card and shown where notifications
// pop up (top right under the bar, on the focused monitor). Takes the keyboard only while a
// request is waiting. Enter authenticates, Esc or Cancel cancels.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    readonly property var flow: Polkit.flow
    readonly property bool shown: Polkit.active && Hyprland.focusedMonitor?.name === modelData.name

    anchors {
        top: true
        right: true
    }
    margins {
        top: 10 + Theme.barHeight + 12
        right: 10
    }
    implicitWidth: 380
    implicitHeight: card.implicitHeight + 16
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-polkit"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    visible: shown || card.opacity > 0

    onShownChanged: {
        if (shown) {
            password.text = "";
            Qt.callLater(() => password.forceActiveFocus());
        }
    }

    function cancel() {
        if (flow && !flow.isCompleted)
            flow.cancelAuthenticationRequest();
    }

    // A failed attempt clears the field for the next try
    Connections {
        target: root.flow
        function onAuthenticationFailed() {
            password.text = "";
            password.forceActiveFocus();
        }
    }

    // Same card as a notification popup (components/NotificationCard.qml)
    Rectangle {
        id: card

        width: parent.width
        implicitHeight: content.implicitHeight + 24
        radius: Theme.radius
        color: Qt.alpha(Theme.base, 0.96)
        opacity: root.shown ? 1 : 0

        transform: Translate {
            x: root.shown ? 0 : 40

            Behavior on x {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

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
                    text: Icons.shieldCheck
                    font.family: Icons.font
                    font.pixelSize: 22
                    color: Theme.accent
                }
            }

            Column {
                width: parent.width - 52
                spacing: 6

                // "Authentication · now", and the cancel ×
                Item {
                    width: parent.width
                    height: 14

                    Label {
                        anchors.left: parent.left
                        text: `Authentication · as ${Quickshell.env("USER")}`
                        font.pixelSize: 10
                        color: Theme.overlay1
                    }

                    Label {
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
                            onClicked: root.cancel()
                        }
                    }
                }

                Label {
                    text: "Password required"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }

                // What the app wants to do
                Text {
                    width: parent.width
                    text: root.flow?.message ?? ""
                    wrapMode: Text.Wrap
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.subtext1
                }

                // Same look as the launcher's search box and the lock screen
                Rectangle {
                    width: parent.width
                    height: 40
                    radius: Theme.radius
                    color: Qt.alpha(Theme.crust, 0.6)
                    border.width: password.activeFocus ? 2 : 1
                    border.color: root.flow?.supplementaryIsError ? Theme.red : password.activeFocus ? Qt.alpha(Theme.accent, 0.7) : Theme.surface0

                    Label {
                        id: lockIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: Icons.lock
                        font.family: Icons.font
                        font.pixelSize: 15
                        color: Theme.accent
                    }

                    TextInput {
                        id: password
                        anchors.left: lockIcon.right
                        anchors.leftMargin: 10
                        anchors.right: layoutCode.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "●"
                        color: Theme.text
                        selectionColor: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        clip: true
                        enabled: root.flow?.isResponseRequired ?? false

                        onAccepted: if (text !== "" && root.flow) root.flow.submit(text)
                        Keys.onEscapePressed: root.cancel()

                        Label {
                            visible: password.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            // PAM's own prompt ("Password: "), tidied up
                            text: (root.flow?.inputPrompt || "Password").replace(/:\s*$/, "")
                            font.pixelSize: 14
                            color: Theme.overlay0
                        }
                    }

                    // Keyboard layout, so a password typed in the wrong layout is obvious
                    Label {
                        id: layoutCode
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: Keyboard.current.code
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Theme.overlay1
                    }
                }

                // Wrong password and other PAM messages
                Label {
                    visible: text !== ""
                    width: parent.width
                    text: root.flow?.supplementaryMessage ?? ""
                    wrapMode: Text.WordWrap
                    elide: Text.ElideNone
                    font.pixelSize: 10
                    color: root.flow?.supplementaryIsError ? Theme.red : Theme.subtext0
                }

                // Like a notification's actions
                Row {
                    spacing: 6
                    topPadding: 2

                    Button {
                        text: "Authenticate"
                        filled: true
                        height: 28
                        enabled: password.text !== "" && (root.flow?.isResponseRequired ?? false)
                        onClicked: root.flow.submit(password.text)
                    }

                    Button {
                        text: "Cancel"
                        height: 28
                        onClicked: root.cancel()
                    }
                }
            }
        }
    }
}
