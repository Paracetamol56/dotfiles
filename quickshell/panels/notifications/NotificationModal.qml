import QtQuick
import qs.common
import qs.components
import qs.services

// Notification center: the history (newest first, grouped by app), Do Not Disturb and
// Clear all. Opened from the bell in the bar. Opening it marks everything as read.
Modal {
    id: root

    name: "notifications"
    align: "right"
    cardWidth: 420
    cardHeight: list.y + list.height + 28

    readonly property int count: Notifications.history.length
    property bool confirmClear: false
    property real armedAt: 0

    kanji: "通知"

    actions: headerActions
    title: "Notifications"
    subtitle: Notifications.dnd ? `Do Not Disturb · ${count} in history` : count ? `${count} notification${count > 1 ? "s" : ""}` : "All caught up"

    onOpenChanged: {
        if (open) {
            Notifications.markRead();
            confirmClear = false;
        }
    }

    // Do Not Disturb + Clear all, right of the subtitle
    Row {
        id: headerActions
        anchors.top: root.header.top
        anchors.topMargin: root.subtitleRow.y + (root.subtitleRow.height - height) / 2
        anchors.right: root.header.right
        spacing: 8

        Button {
            icon: Notifications.dnd ? Icons.bellOff : Icons.bell
            checked: Notifications.dnd
            tooltip: Notifications.dnd ? "Do Not Disturb: on (only critical ones pop up)" : "Do Not Disturb: off"
            onClicked: Notifications.toggleDnd()
        }

        // Same double-click-safe confirm as the clipboard: the second click must come after a pause
        Button {
            icon: Icons.trash2
            text: root.confirmClear ? "Click again" : ""
            checked: root.confirmClear
            enabled: root.count > 0
            tooltip: "Clear all notifications"
            onClicked: {
                if (!root.confirmClear) {
                    root.confirmClear = true;
                    root.armedAt = Date.now();
                    confirmTimer.restart();
                    return;
                }
                if (Date.now() - root.armedAt < 600)
                    return;
                root.confirmClear = false;
                Notifications.clearAll();
            }
        }
    }

    Timer {
        id: confirmTimer
        interval: 4000
        onTriggered: root.confirmClear = false
    }

    // Straight on the panel, no card around it
    Item {
        id: list
        anchors.top: root.header.bottom
        anchors.topMargin: 24
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: Math.min(Math.max(view.contentHeight, 90), 520)

        Column {
            visible: root.count === 0
            anchors.centerIn: parent
            spacing: 6

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Icons.bellOff
                font.family: Icons.font
                font.pixelSize: 24
                color: Theme.overlay0
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No notifications"
                color: Theme.overlay1
            }
        }

        ListView {
            id: view
            anchors.fill: parent
            clip: true
            spacing: 6
            model: Notifications.history
            boundsBehavior: Flickable.StopAtBounds

            // Grouped by app
            section.property: "appName"
            section.delegate: Label {
                required property string section
                width: ListView.view.width
                leftPadding: 6
                topPadding: 8
                bottomPadding: 4
                text: section || "Other"
                font.pixelSize: 10
                font.weight: Font.Bold
                color: Theme.overlay1
            }

            delegate: NotificationCard {
                required property var modelData
                notification: modelData
                width: ListView.view.width
            }
        }
    }
}
