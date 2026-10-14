import QtQuick
import "../bar"

// Pending package updates, with a button that runs the upgrade in a terminal.
// Opened from the package icon in the bar.
Modal {
    id: root

    name: "updates"
    cardWidth: 520
    cardHeight: list.y + list.height + 28

    readonly property int count: Stats.updateList.length

    title: count ? `<font color="${Theme.mauve}">${count}</font> update${count > 1 ? "s" : ""} available` : "Up to date"
    subtitle: (Stats.checkingUpdates ? "Checking…" : count ? `${count - Stats.aurUpdates} from the repos · ${Stats.aurUpdates} from the AUR` : "Nothing to upgrade") + (Stats.updatesCheckedAt.getTime() ? ` · checked at ${Qt.formatTime(Stats.updatesCheckedAt, "HH:mm")}` : "")

    // Refresh + update, top right next to the title
    Row {
        anchors.top: root.header.top
        anchors.right: root.header.right
        spacing: 8

        Button {
            icon: Icons.refreshCw
            enabled: !Stats.checkingUpdates
            onClicked: Stats.checkUpdates()
        }

        Button {
            icon: Icons.download
            text: "Update now"
            filled: true
            enabled: root.count > 0
            onClicked: {
                Panels.close();
                Stats.runUpgrade();
            }
        }
    }

    Widget {
        id: list
        blurSource: root.backdrop
        anchors.top: root.header.bottom
        anchors.topMargin: 24
        anchors.left: root.header.left
        anchors.right: root.header.right
        // One row per package, up to 10 before scrolling
        height: Math.max(1, Math.min(root.count, 10)) * 30 + padding * 2

        Label {
            visible: root.count === 0
            anchors.centerIn: parent
            text: Stats.checkingUpdates ? "Checking for updates…" : "Everything is up to date"
            color: Theme.overlay1
        }

        ListView {
            anchors.fill: parent
            clip: true
            model: Stats.updateList
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                required property var modelData
                width: ListView.view.width
                height: 30

                Label {
                    id: pkg
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, parent.width - versions.width - aur.width - 24)
                    text: modelData.name
                }

                // AUR tag
                Rectangle {
                    id: aur
                    visible: modelData.aur
                    anchors.left: pkg.right
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: visible ? aurLabel.implicitWidth + 10 : 0
                    height: 16
                    radius: 8
                    color: Qt.alpha(Theme.peach, 0.15)

                    Label {
                        id: aurLabel
                        anchors.centerIn: parent
                        text: "AUR"
                        font.pixelSize: 9
                        color: Theme.peach
                    }
                }

                Label {
                    id: versions
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    textFormat: Text.StyledText
                    text: `<font color="${Theme.overlay1}">${modelData.from}</font>  →  <font color="${Theme.green}">${modelData.to}</font>`
                    font.pixelSize: 11
                }
            }
        }
    }
}
