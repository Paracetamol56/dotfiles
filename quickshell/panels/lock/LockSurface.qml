import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import qs.common
import qs.components
import qs.services

// What one screen shows while locked: the wallpaper blurred, a big clock and date, and (on
// the focused screen) the password field with the keyboard layout and PAM's messages.
Item {
    id: root

    readonly property bool focused: {
        const s = QsWindow.window?.screen;
        return !s || Hyprland.focusedMonitor?.name === s.name;
    }
    readonly property string user: Quickshell.env("USER") ?? ""
    readonly property string wallpaper: Wallpaper.path

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.crust
    }

    Image {
        id: background
        anchors.fill: parent
        source: root.wallpaper ? "file://" + root.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: background
        blurEnabled: true
        blurMax: 64
        blur: 1
        brightness: -0.25
    }

    // ── Clock ─────────────────────────────────────────────

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.verticalCenter
        anchors.bottomMargin: 40
        spacing: -10

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.date, "HH:mm")
            font.pixelSize: 120
            font.weight: Font.Bold
            color: Theme.text
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(clock.date, "dddd d MMMM")
            font.pixelSize: 22
            color: Theme.subtext1
        }
    }

    // ── Password (focused screen only) ─────────────────────

    Column {
        visible: root.focused
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.verticalCenter
        anchors.topMargin: 30
        width: 340
        spacing: 12

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.user.charAt(0).toUpperCase() + root.user.slice(1)
            font.pixelSize: 16
            font.weight: Font.Bold
            color: Theme.accent
        }

        // Same look as the launcher's search box: lock icon, left-aligned text, thin border
        // (accent when focused, red after a wrong password, yellow while checking)
        Rectangle {
            width: parent.width
            height: 44
            radius: Theme.radius
            color: Qt.alpha(Theme.crust, 0.6)
            border.width: input.activeFocus ? 2 : 1
            border.color: Lock.failed ? Theme.red : Lock.checking ? Theme.yellow : input.activeFocus ? Qt.alpha(Theme.accent, 0.7) : Theme.surface0

            Behavior on border.color {
                ColorAnimation {
                    duration: Theme.animDuration
                }
            }

            Label {
                id: lockIcon
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.lock
                font.family: Icons.font
                font.pixelSize: 16
                color: Lock.failed ? Theme.red : Theme.accent
            }

            TextInput {
                id: input
                anchors.left: lockIcon.right
                anchors.leftMargin: 12
                anchors.right: layoutCode.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                echoMode: TextInput.Password
                passwordCharacter: "●"
                color: Theme.text
                selectionColor: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: 15
                focus: root.focused
                enabled: !Lock.checking
                clip: true

                // Shared with the other screens' fields through the Lock service
                text: Lock.password
                onTextChanged: Lock.password = text
                onAccepted: Lock.submit()

                Component.onCompleted: if (root.focused) forceActiveFocus()

                Label {
                    visible: input.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: Lock.checking ? "Checking…" : "Password"
                    font.pixelSize: 15
                    color: Theme.overlay0
                }
            }

            // Keyboard layout, so a password typed in the wrong layout is obvious
            Label {
                id: layoutCode
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: Keyboard.current.code
                font.pixelSize: 11
                font.weight: Font.Bold
                color: Theme.overlay1
            }
        }

        // Wrong password, faillock lockout…
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            visible: text !== ""
            text: Lock.message
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
            font.pixelSize: 12
            color: Lock.failed ? Theme.red : Theme.subtext0
        }
    }

    // ── Now playing, bottom centre ────────────────────────

    Row {
        readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? null

        visible: player !== null
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        spacing: 10

        Label {
            text: Icons.music
            font.family: Icons.font
            font.pixelSize: 14
            color: Theme.accent
        }

        Label {
            text: parent.player ? [parent.player.trackTitle, parent.player.trackArtist].filter(s => s).join(" · ") : ""
            font.pixelSize: 12
            color: Theme.subtext1
        }
    }
}
