import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import qs.common
import qs.components
import qs.services

// What one screen shows while locked: the wallpaper blurred, a rolling clock with the date in
// kanji and English, (on the focused screen) the password field with the keyboard layout, Num
// Lock and PAM's messages, now playing, and a card about the rice. Animates in when locking
// and back out to the sharp wallpaper when unlocking (Lock.unlocking).
Item {
    id: root

    readonly property bool focused: {
        const s = QsWindow.window?.screen;
        return !s || Hyprland.focusedMonitor?.name === s.name;
    }
    readonly property string user: Quickshell.env("USER") ?? ""
    readonly property string wallpaper: Wallpaper.path

    // 0 → 1 when the lock appears, back to 0 for the unlock outro
    property bool shown: false
    property real reveal: shown && !Lock.unlocking ? 1 : 0
    // Num Lock state, from Hyprland's main keyboard
    property bool numLock: true

    clip: true
    Component.onCompleted: shown = true

    Behavior on reveal {
        NumberAnimation {
            duration: Lock.unlocking ? 400 : 700
            easing.type: Easing.OutCubic
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.crust
    }

    // ── Wallpaper: sharp → blurred, darker, slowly zoomed in ──

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
        blur: root.reveal
        brightness: -0.25 * root.reveal
        scale: 1 + 0.06 * root.reveal
    }

    // ── Clock + dates ─────────────────────────────────────

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.verticalCenter
        anchors.bottomMargin: 40
        spacing: 0
        opacity: root.reveal
        transform: Translate {
            y: 30 * (1 - root.reveal)
        }

        Row {
            id: time
            readonly property string text: Qt.formatTime(clock.date, "HH:mm")
            anchors.horizontalCenter: parent.horizontalCenter

            RollingDigit {
                digit: time.text[0]
            }
            RollingDigit {
                digit: time.text[1]
            }
            Label {
                text: ":"
                font.pixelSize: 120
                font.weight: Font.Bold
                color: Theme.text
            }
            RollingDigit {
                digit: time.text[3]
            }
            RollingDigit {
                digit: time.text[4]
            }
        }

        // e.g. 木曜日 · 10月16日
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ["日", "月", "火", "水", "木", "金", "土"][clock.date.getDay()] + "曜日 · " + (clock.date.getMonth() + 1) + "月" + clock.date.getDate() + "日"
            font.family: "Noto Sans CJK JP"
            font.pixelSize: 36
            font.weight: Font.Light
            color: Theme.accent
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 6
            text: Qt.formatDate(clock.date, "dddd d MMMM")
            font.pixelSize: 24
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
        // Comes in a little after the clock
        opacity: Math.max(0, (root.reveal - 0.25) / 0.75)
        transform: Translate {
            y: 30 * (1 - root.reveal)
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.user.charAt(0).toUpperCase() + root.user.slice(1)
            font.pixelSize: 16
            font.weight: Font.Bold
            color: Theme.accent
        }

        // Same look as the launcher's search box: lock icon, left-aligned dots, thin border
        // (accent when focused, pulsing while checking, red after a wrong password)
        Rectangle {
            id: field
            width: parent.width
            height: 44
            radius: Theme.radius
            color: Qt.alpha(Theme.crust, 0.6)
            border.width: input.activeFocus || Lock.checking ? 2 : 1
            border.color: Lock.checking ? Qt.alpha(Theme.accent, 0.3 + 0.7 * pulse) : Lock.failed ? Theme.red : input.activeFocus ? Qt.alpha(Theme.accent, 0.7) : Theme.surface0

            property real pulse: 0

            transform: Translate {
                id: shakeOffset
            }

            Behavior on border.color {
                enabled: !Lock.checking
                ColorAnimation {
                    duration: Theme.animDuration
                }
            }

            // Checking: the border breathes
            SequentialAnimation on pulse {
                running: Lock.checking
                loops: Animation.Infinite
                NumberAnimation {
                    to: 1
                    duration: 450
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: 0
                    duration: 450
                    easing.type: Easing.InOutSine
                }
            }

            // Wrong password: a short shake
            SequentialAnimation {
                id: shake
                NumberAnimation { target: shakeOffset; property: "x"; to: -12; duration: 50 }
                NumberAnimation { target: shakeOffset; property: "x"; to: 12; duration: 60 }
                NumberAnimation { target: shakeOffset; property: "x"; to: -8; duration: 55 }
                NumberAnimation { target: shakeOffset; property: "x"; to: 8; duration: 55 }
                NumberAnimation { target: shakeOffset; property: "x"; to: -4; duration: 50 }
                NumberAnimation { target: shakeOffset; property: "x"; to: 0; duration: 50 }
            }

            Connections {
                target: Lock
                function onFailedChanged() {
                    if (Lock.failed)
                        shake.restart();
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

            // Handles typing and focus; its own text is invisible, the dots below show it
            TextInput {
                id: input
                anchors.left: lockIcon.right
                anchors.leftMargin: 12
                anchors.right: badges.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                echoMode: TextInput.Password
                color: "transparent"
                selectionColor: "transparent"
                selectedTextColor: "transparent"
                cursorDelegate: Item {}
                font.family: Theme.fontFamily
                font.pixelSize: 15
                focus: root.focused
                enabled: !Lock.checking
                clip: true

                // Shared with the other screens' fields through the Lock service
                text: Lock.password
                onTextChanged: {
                    Lock.password = text;
                    // One dot per character; only new ones animate in
                    while (dots.count < Math.min(text.length, dotsRow.max))
                        dots.append({});
                    while (dots.count > Math.min(text.length, dotsRow.max))
                        dots.remove(dots.count - 1);
                    numLockCheck.running = true;
                }
                onAccepted: Lock.submit()

                Component.onCompleted: if (root.focused) forceActiveFocus()

                Label {
                    visible: input.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: Lock.checking ? "Checking…" : "Password"
                    font.pixelSize: 15
                    color: Theme.overlay0
                }

                Row {
                    id: dotsRow
                    readonly property int max: Math.floor(input.width / 14)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Repeater {
                        model: ListModel {
                            id: dots
                        }

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: Lock.failed ? Theme.red : Theme.accent

                            NumberAnimation on scale {
                                from: 0
                                to: 1
                                duration: 160
                                easing.type: Easing.OutBack
                            }
                        }
                    }
                }
            }

            Row {
                id: badges
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                // Num Lock off: digits typed on the keypad wouldn't go in
                Label {
                    visible: !root.numLock
                    text: "NUM"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: Theme.yellow
                }

                // Keyboard layout, so a password typed in the wrong layout is obvious
                Label {
                    text: Keyboard.current.code
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: Theme.overlay1
                }
            }
        }

        // Wrong password, faillock lockout…, or Num Lock off
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            visible: text !== ""
            text: Lock.message || (root.numLock ? "" : "Num Lock is off")
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
            font.pixelSize: 12
            color: Lock.failed ? Theme.red : Lock.message ? Theme.subtext0 : Theme.yellow
        }
    }

    // Num Lock from Hyprland: on start, as you type, and every 2 s (pressing Num Lock alone
    // doesn't type anything)
    Process {
        id: numLockCheck
        command: ["hyprctl", "devices", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kb = JSON.parse(text).keyboards.find(k => k.main);
                    if (kb)
                        root.numLock = kb.numLock;
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 2000
        running: root.focused
        repeat: true
        onTriggered: numLockCheck.running = true
    }

    // ── Now playing, bottom centre ────────────────────────

    Row {
        readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? null

        visible: player !== null
        opacity: root.reveal
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

    // ── The rice, bottom left: stack, last change, palette ──

    RiceInfo {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 60
        anchors.bottomMargin: 50
        opacity: root.reveal
        transform: Translate {
            x: -20 * (1 - root.reveal)
        }
    }

    // ── "Activate Linux", bottom right ────────────────────

    ActivateLinux {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 60
        anchors.bottomMargin: 50
        opacity: root.reveal
        transform: Translate {
            x: 20 * (1 - root.reveal)
        }
    }
}
