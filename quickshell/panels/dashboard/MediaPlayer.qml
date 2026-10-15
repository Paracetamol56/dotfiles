import QtQuick
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.common
import qs.components

// Now playing: artwork, track info, a seekable progress bar and transport controls.
// Follows the playing player (like the bar); click the player name to cycle through others.
Widget {
    id: root

    readonly property var players: Mpris.players.values
    // Player picked by clicking its name; -1 = follow whatever is playing
    property int pickedIndex: -1
    readonly property MprisPlayer player: players[pickedIndex] ?? players.find(p => p.isPlaying) ?? players[0] ?? null

    readonly property bool canSeek: (player?.canSeek ?? false) && (player?.lengthSupported ?? false) && player.length > 0
    // Position shown on the bar, overridden while dragging
    property real dragRatio: -1
    readonly property real ratio: dragRatio >= 0 ? dragRatio : player && player.length > 0 ? Math.min(1, player.position / player.length) : 0

    onPlayersChanged: if (pickedIndex >= players.length) pickedIndex = -1

    function time(s) {
        if (!isFinite(s) || s < 0)
            return "0:00";
        s = Math.floor(s);
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    // MPRIS doesn't push position updates while playing; ask for them once a second
    Timer {
        interval: 1000
        repeat: true
        running: root.visible && (root.player?.isPlaying ?? false)
        onTriggered: root.player.positionChanged()
    }

    // ── Nothing playing ──────────────────────────────────

    Column {
        visible: !root.player
        anchors.centerIn: parent
        spacing: 8

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Icons.music
            font.family: Icons.font
            font.pixelSize: 28
            color: Theme.overlay0
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Nothing playing"
            color: Theme.overlay1
        }
    }

    // ── Player ───────────────────────────────────────────

    Row {
        visible: root.player !== null
        anchors.fill: parent
        spacing: 16

        // Artwork, with a disc icon while it loads or when the player has none
        ClippingRectangle {
            id: art
            width: height
            height: parent.height
            radius: Theme.radius
            color: Theme.surface0

            Label {
                anchors.centerIn: parent
                visible: cover.status !== Image.Ready
                text: Icons.disc3
                font.family: Icons.font
                font.pixelSize: 36
                color: Theme.overlay0
            }

            Image {
                id: cover
                anchors.fill: parent
                // Some players (jellyfin-tui) report "file://" with no path when they have no artwork
                readonly property string url: root.player?.trackArtUrl ?? ""
                source: /^file:\/\/\/?$/.test(url) ? "" : url
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: width * 2
                sourceSize.height: height * 2
            }
        }

        Column {
            width: parent.width - art.width - parent.spacing
            height: parent.height
            spacing: 2

            // Player name; cycles through players when there are several
            Item {
                implicitWidth: nameRow.implicitWidth
                implicitHeight: nameRow.implicitHeight

                Row {
                    id: nameRow
                    spacing: 6
                    opacity: playerMouse.containsMouse ? 1 : 0.8

                    Label {
                        text: Icons.audioLines
                        font.family: Icons.font
                        font.pixelSize: 12
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Label {
                        text: (root.player?.identity ?? "") + (root.players.length > 1 ? `  ·  ${root.players.indexOf(root.player) + 1}/${root.players.length}` : "")
                        font.pixelSize: 11
                        color: playerMouse.containsMouse && root.players.length > 1 ? Theme.lavender : Theme.subtext0
                    }
                }

                MouseArea {
                    id: playerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.players.length > 1
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pickedIndex = (root.players.indexOf(root.player) + 1) % root.players.length
                }
            }

            Item {
                width: 1
                height: 4
            }

            Label {
                width: parent.width
                text: root.player?.trackTitle || "Unknown title"
                font.pixelSize: 15
                font.weight: Font.Bold
                color: Theme.text
            }

            Label {
                width: parent.width
                text: root.player?.trackArtist ?? ""
                color: Theme.subtext1
            }

            Label {
                width: parent.width
                visible: text !== ""
                text: root.player?.trackAlbum ?? ""
                font.pixelSize: 11
                color: Theme.overlay1
            }
        }
    }

    // Progress + controls, pinned to the bottom of the text column
    Column {
        visible: root.player !== null
        x: art.width + 16
        width: parent.width - x
        anchors.bottom: parent.bottom
        spacing: 6

        // Seek bar: click or drag to seek, if the player supports it
        Item {
            width: parent.width
            height: 12

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Theme.surface1

                Rectangle {
                    width: parent.width * root.ratio
                    height: parent.height
                    radius: parent.radius
                    color: Theme.accent
                }
            }

            Rectangle {
                visible: root.canSeek && (seek.containsMouse || seek.pressed)
                x: track.width * root.ratio - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: 10
                height: 10
                radius: 5
                color: Theme.lavender
            }

            MouseArea {
                id: seek
                anchors.fill: parent
                enabled: root.canSeek
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                function ratioAt(x) {
                    return Math.max(0, Math.min(1, x / width));
                }

                onPressed: m => root.dragRatio = ratioAt(m.x)
                onPositionChanged: m => {
                    if (pressed)
                        root.dragRatio = ratioAt(m.x);
                }
                onReleased: {
                    root.player.position = root.dragRatio * root.player.length;
                    root.dragRatio = -1;
                }
            }
        }

        Item {
            width: parent.width
            height: controls.height

            Label {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.time(root.ratio * (root.player?.length ?? 0))
                font.pixelSize: 11
                color: Theme.overlay1
            }

            Row {
                id: controls
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14

                ControlButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: Icons.skipBack
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: root.player.previous()
                }

                // Play / pause: the one filled button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: playMouse.containsMouse ? Theme.lavender : Theme.accent

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animDuration
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        // Nudge the play triangle right so it looks centred
                        anchors.horizontalCenterOffset: root.player?.isPlaying ? 0 : 1
                        text: root.player?.isPlaying ? Icons.pause : Icons.play
                        font.family: Icons.font
                        font.pixelSize: 15
                        color: Theme.base
                    }

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.player?.canTogglePlaying ?? false
                        onClicked: root.player.togglePlaying()
                    }
                }

                ControlButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: Icons.skipForward
                    enabled: root.player?.canGoNext ?? false
                    onClicked: root.player.next()
                }
            }

            Label {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.time(root.player?.length ?? 0)
                font.pixelSize: 11
                color: Theme.overlay1
            }
        }
    }

    component ControlButton: Label {
        id: btn

        property string icon
        property bool enabled: true
        signal clicked

        text: icon
        font.family: Icons.font
        font.pixelSize: 17
        color: !enabled ? Theme.surface2 : btnMouse.containsMouse ? Theme.lavender : Theme.text

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            enabled: btn.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
