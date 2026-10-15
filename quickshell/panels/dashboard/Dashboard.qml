import QtQuick
import Quickshell
import qs.common
import qs.components
import qs.services

// Dashboard: greeting, media, weather, quick launch, capture and astronomy.
// Opened from the Arch button in the bar.
Modal {
    id: root

    name: "dashboard"
    // Fits the widgets, with the same margin as the sides
    cardHeight: astronomy.y + astronomy.height + 28

    readonly property string user: Quickshell.env("USER") ?? ""
    readonly property int hour: clock.hours

    title: (hour < 6 ? "Good night" : hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening") + `, <font color="${Theme.mauve}">${user.charAt(0).toUpperCase() + user.slice(1)}</font>`
    subtitle: Qt.formatDate(clock.date, "dddd d MMMM yyyy")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Quick toggles, top right next to the greeting
    Row {
        anchors.top: root.header.top
        anchors.right: root.header.right
        spacing: 8

        Button {
            icon: Icons.moon
            tooltip: !NightLight.available ? "Night light · install hyprsunset" : NightLight.enabled ? "Night light: on" : "Night light: off"
            checked: NightLight.enabled
            enabled: NightLight.available
            onClicked: NightLight.toggle()
        }

        // Keyboard layout, shown as FR / US
        Button {
            icon: Icons.keyboard
            text: Keyboard.current.code
            tooltip: `Keyboard: ${Keyboard.current.name} · click to switch`
            onClicked: Keyboard.toggle()
        }

        // Same inhibitor as the coffee cup in the bar
        Button {
            icon: Icons.coffee
            tooltip: Stats.presentationMode ? "Stay awake: on (no idle, lock or sleep)" : "Stay awake: off"
            checked: Stats.presentationMode
            onClicked: Stats.presentationMode = !Stats.presentationMode
        }
    }

    // Widgets, three rows: wide ones on the left, narrow ones filling the right
    MediaPlayer {
        id: media
        blurSource: root.backdrop
        anchors.top: root.header.bottom
        anchors.topMargin: 24
        anchors.left: root.header.left
        width: 460
        height: 170
    }

    Weather {
        blurSource: root.backdrop
        anchors.top: media.top
        anchors.left: media.right
        anchors.leftMargin: 16
        anchors.right: root.header.right
        height: media.height
    }

    QuickLaunch {
        id: launch
        blurSource: root.backdrop
        anchors.top: media.bottom
        anchors.topMargin: 16
        anchors.left: media.left
        width: media.width
        height: 104
    }

    Capture {
        blurSource: root.backdrop
        anchors.top: launch.top
        anchors.left: launch.right
        anchors.leftMargin: 16
        anchors.right: root.header.right
        height: launch.height
    }

    Astronomy {
        id: astronomy
        blurSource: root.backdrop
        anchors.top: launch.bottom
        anchors.topMargin: 16
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: 160
    }
}
