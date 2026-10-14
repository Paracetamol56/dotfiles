import QtQuick
import Quickshell
import Quickshell.Io
import "../bar"

// Power menu, replacing the rofi one: lock, log out, suspend, hibernate, reboot, shut down.
// Opened from the bar's power button or SUPER + Backspace. Nothing is selected at first, so
// stray keys can't trigger anything: ↑/↓ or a letter selects, click/Enter activates, and
// everything but Lock needs a second click/Enter within 3 s to confirm.
Modal {
    id: root

    name: "power"
    // Right side, under the bar's power button
    align: "right"
    cardWidth: 340
    cardHeight: actions.y + actions.height + 28

    readonly property string user: Quickshell.env("USER") ?? ""
    property real uptime: 0 // seconds
    // Selected tile (-1 = none) and the tile waiting for confirmation (-1 = none)
    property int current: -1
    property int armed: -1

    readonly property var items: [
        { key: "L", label: "Lock", icon: Icons.lock, color: Theme.mauve, confirm: false, cmd: "hyprlock" },
        { key: "E", label: "Log out", icon: Icons.logOut, color: Theme.mauve, confirm: true, cmd: "command -v hyprshutdown >/dev/null && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'" },
        { key: "U", label: "Suspend", icon: Icons.moon, color: Theme.lavender, confirm: true, cmd: "systemctl suspend" },
        { key: "H", label: "Hibernate", icon: Icons.snowflake, color: Theme.sky, confirm: true, cmd: "systemctl hibernate" },
        { key: "R", label: "Reboot", icon: Icons.rotateCcw, color: Theme.peach, confirm: true, cmd: "systemctl reboot" },
        { key: "S", label: "Shut down", icon: Icons.power, color: Theme.red, confirm: true, cmd: "systemctl poweroff" }
    ]

    title: `See you, <font color="${Theme.mauve}">${user.charAt(0).toUpperCase() + user.slice(1)}</font>`
    subtitle: {
        const s = Math.floor(uptime), d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
        const up = (d ? `${d}d ` : "") + (d || h ? `${h}h ` : "") + `${m}m`;
        return `Up ${up} · since ${Qt.formatDateTime(new Date(Date.now() - s * 1000), "ddd HH:mm")}`;
    }

    // First activation of a disruptive action only arms it; the second runs it
    function activate(i) {
        if (i < 0)
            return;
        current = i;
        if (items[i].confirm && armed !== i) {
            armed = i;
            disarm.restart();
            return;
        }
        run(i);
    }

    function run(i) {
        armed = -1;
        Panels.close();
        // Let the modal close first (hyprlock, for one, shouldn't start under it)
        Quickshell.execDetached(["sh", "-c", `sleep 0.3; ${items[i].cmd}`]);
    }

    onOpenChanged: {
        if (open) {
            current = -1;
            armed = -1;
            uptimeFile.reload();
        }
    }

    onKeyPressed: e => {
        if (e.key === Qt.Key_Left || e.key === Qt.Key_Up)
            current = current < 0 ? items.length - 1 : (current + items.length - 1) % items.length;
        else if (e.key === Qt.Key_Right || e.key === Qt.Key_Down || e.key === Qt.Key_Tab)
            current = (current + 1) % items.length;
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
            activate(current);
        else {
            // Letters only select, they never run anything
            const i = items.findIndex(it => it.key === e.text.toUpperCase());
            if (i < 0)
                return;
            current = i;
        }
        if (armed !== current)
            armed = -1;
        e.accepted = true;
    }

    // An armed action goes back to normal if not confirmed in time
    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = -1
    }

    // /proc/uptime: "seconds-since-boot idle-seconds"
    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.uptime = Number(text().split(" ")[0])
    }

    // Keeps the uptime ticking while the menu is open
    Timer {
        interval: 30000
        repeat: true
        running: root.open
        onTriggered: uptimeFile.reload()
    }

    // One row per action, stacked
    Widget {
        id: actions
        blurSource: root.backdrop
        anchors.top: root.header.bottom
        anchors.topMargin: 24
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: column.implicitHeight + padding * 2
        padding: 8

        Column {
            id: column
            width: parent.width
            spacing: 4

            Repeater {
                model: root.items

                Rectangle {
                    id: row

                    required property var modelData
                    required property int index
                    readonly property bool active: root.current === index
                    readonly property bool isArmed: root.armed === index

                    width: parent.width
                    height: 40
                    radius: Theme.radius
                    color: isArmed ? Qt.alpha(modelData.color, 0.35) : active ? Qt.alpha(modelData.color, 0.18) : "transparent"
                    border.width: active || isArmed ? 1 : 0
                    border.color: Qt.alpha(modelData.color, 0.6)

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animDuration
                        }
                    }

                    Label {
                        id: icon
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.icon
                        font.family: Icons.font
                        font.pixelSize: 18
                        color: row.active || row.isArmed ? row.modelData.color : Theme.subtext1
                    }

                    Label {
                        anchors.left: icon.right
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.label
                        font.pixelSize: 12
                        color: row.active || row.isArmed ? Theme.text : Theme.subtext0
                    }

                    // Shortcut letter, or the confirmation prompt
                    Label {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.isArmed ? "Press again" : row.modelData.key
                        font.pixelSize: 10
                        color: row.isArmed ? row.modelData.color : Theme.overlay0
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.current = row.index
                        onClicked: root.activate(row.index)
                    }
                }
            }
        }
    }
}
