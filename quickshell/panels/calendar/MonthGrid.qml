import QtQuick
import qs.common
import qs.components
import "../../lib/CalendarUtil.js" as Cal

// Month view: navigation, ISO week numbers and today
Widget {
    id: root

    // Any day in the month to show
    property date month: new Date()
    property date today: new Date()

    readonly property var days: Cal.monthGrid(month)
    readonly property real weekColumn: 36
    readonly property real cellWidth: (width - padding * 2 - weekColumn) / 7
    readonly property real cellHeight: 38

    function shift(months) {
        month = new Date(month.getFullYear(), month.getMonth() + months, 1);
    }

    // ── Navigation ───────────────────────────────────────

    Item {
        id: nav
        width: parent.width
        height: 26

        NavButton {
            anchors.left: parent.left
            text: "‹"
            onClicked: root.shift(-1)
        }

        Label {
            anchors.centerIn: parent
            text: Qt.formatDate(root.month, "MMMM yyyy")
            font.pixelSize: 14
            font.weight: Font.Bold
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            // Back to the current month, only when away from it
            NavButton {
                visible: root.month.getMonth() !== root.today.getMonth() || root.month.getFullYear() !== root.today.getFullYear()
                text: "Today"
                small: true
                onClicked: root.month = root.today
            }

            NavButton {
                text: "›"
                onClicked: root.shift(1)
            }
        }
    }

    // ── Weekday names ────────────────────────────────────

    Row {
        id: weekdays
        anchors.top: nav.bottom
        anchors.topMargin: 12

        Label {
            width: root.weekColumn
            text: "Wk"
            font.pixelSize: 10
            color: Theme.overlay0
        }

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

            Label {
                required property string modelData
                required property int index
                width: root.cellWidth
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                font.pixelSize: 10
                color: index >= 5 ? Theme.mauve : Theme.subtext0
            }
        }
    }

    // ── Days ─────────────────────────────────────────────

    Column {
        anchors.top: weekdays.bottom
        anchors.topMargin: 4

        Repeater {
            model: 6

            Row {
                id: week
                required property int index

                Label {
                    width: root.weekColumn
                    height: root.cellHeight
                    verticalAlignment: Text.AlignVCenter
                    text: Cal.isoWeek(root.days[week.index * 7])
                    font.pixelSize: 10
                    color: Theme.overlay0
                }

                Repeater {
                    model: 7

                    Item {
                        id: cell

                        required property int index
                        readonly property date day: root.days[week.index * 7 + index]
                        readonly property bool inMonth: day.getMonth() === root.month.getMonth()
                        readonly property bool isToday: Cal.sameDay(day, root.today)

                        width: root.cellWidth
                        height: root.cellHeight

                        Rectangle {
                            anchors.centerIn: parent
                            width: 30
                            height: 30
                            radius: 15
                            color: cell.isToday ? Theme.mauve : cellMouse.containsMouse ? Qt.alpha(Theme.surface1, 0.6) : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.animDuration
                                }
                            }
                        }

                        Label {
                            anchors.centerIn: parent
                            text: cell.day.getDate()
                            font.pixelSize: 12
                            font.weight: cell.isToday ? Font.Bold : Font.Normal
                            color: cell.isToday ? Theme.base : !cell.inMonth ? Theme.surface2 : cell.index >= 5 ? Theme.subtext0 : Theme.text
                        }

                        MouseArea {
                            id: cellMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }
        }
    }

    // Scroll anywhere on the grid to change month
    WheelHandler {
        onWheel: e => root.shift(e.angleDelta.y > 0 ? -1 : 1)
    }

    component NavButton: Rectangle {
        id: button

        property string text
        property bool small: false
        signal clicked

        width: small ? label.implicitWidth + 16 : 26
        height: 26
        radius: Theme.radius
        color: buttonMouse.containsMouse ? Qt.alpha(Theme.surface1, 0.6) : Qt.alpha(Theme.surface0, 0.6)

        Label {
            id: label
            anchors.centerIn: parent
            text: button.text
            font.pixelSize: button.small ? 10 : 16
            color: buttonMouse.containsMouse ? Theme.lavender : Theme.subtext1
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}
