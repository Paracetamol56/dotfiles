import QtQuick
import Quickshell
import qs.common
import qs.components
import qs.services

// Dashboard: greeting, media, weather, theme + lighting, capture and astronomy.
// Opened from the Arch button in the bar.
Modal {
    id: root

    name: "dashboard"
    // Fits the widgets, with the same margin as the sides
    cardHeight: astronomy.y + astronomy.height + 28

    readonly property string user: Quickshell.env("USER") ?? ""
    readonly property int hour: clock.hours

    kanji: "計器盤"

    actions: headerActions
    title: (hour < 6 ? "Good night" : hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening") + `, <font color="${Theme.accent}">${user.charAt(0).toUpperCase() + user.slice(1)}</font>`
    subtitle: Qt.formatDate(clock.date, "dddd d MMMM yyyy")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Quick toggles, right of the date
    Row {
        id: headerActions
        anchors.top: root.header.top
        anchors.topMargin: root.subtitleRow.y + (root.subtitleRow.height - height) / 2
        anchors.right: root.header.right
        spacing: 8

        Button {
          icon: Icons.keyboard
          text: Keyboard.current.code
          tooltip: `Keyboard: ${Keyboard.current.name} · click to switch`
          onClicked: Keyboard.toggle()
        }

        Button {
            icon: Icons.moon
            tooltip: !NightLight.available ? "Night light · install hyprsunset" : NightLight.enabled ? "Night light: on" : "Night light: off"
            checked: NightLight.enabled
            enabled: NightLight.available
            onClicked: NightLight.toggle()
        }

        Button {
            icon: Icons.coffee
            tooltip: Stats.presentationMode ? "Stay awake: on (no idle, lock or sleep)" : "Stay awake: off"
            checked: Stats.presentationMode
            onClicked: Stats.presentationMode = !Stats.presentationMode
        }

        Button {
            icon: Notifications.dnd ? Icons.bellOff : Icons.bell
            tooltip: Notifications.dnd ? "Do Not Disturb: on" : "Do Not Disturb: off"
            checked: Notifications.dnd
            onClicked: Notifications.toggleDnd()
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

    ThemeWidget {
        id: themes
        blurSource: root.backdrop
        anchors.top: media.bottom
        anchors.topMargin: 16
        anchors.left: media.left
        width: media.width
        height: 120
    }

    Capture {
        blurSource: root.backdrop
        anchors.top: themes.top
        anchors.left: themes.right
        anchors.leftMargin: 16
        anchors.right: root.header.right
        height: themes.height
    }

    Astronomy {
        id: astronomy
        blurSource: root.backdrop
        anchors.top: themes.bottom
        anchors.topMargin: 16
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: 160
    }
}
