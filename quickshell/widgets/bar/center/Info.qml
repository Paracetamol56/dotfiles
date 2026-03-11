import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root
    required property var cfg
    required property var st

    height:        cfg.pillH
    implicitWidth: row.implicitWidth + 16
    radius:        cfg.pillR
    color:         Qt.rgba(1,1,1, 0.04)
    border.width:  1
    border.color:  Qt.rgba(1,1,1, 0.08)

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        // Time
        RowLayout {
            spacing: 4
            Text {
                text: "󰥔"; font.family: "Iosevka Nerd Font"
                font.pixelSize: cfg.iconPx; color: "#89b4fa"
            }
            Text {
                text: st.timeStr; font.family: "JetBrains Mono"
                font.pixelSize: cfg.labelPx; font.weight: Font.Bold; color: "#cdd6f4"
            }
        }

        Rectangle { width: 1; height: 14; color: Qt.rgba(1,1,1, 0.10) }

        // Date
        RowLayout {
            spacing: 4
            Text {
                text: "󰃭"; font.family: "Iosevka Nerd Font"
                font.pixelSize: cfg.iconPx; color: "#94e2d5"
            }
            Text {
                text: st.dateStr; font.family: "JetBrains Mono"
                font.pixelSize: cfg.labelPx; font.weight: Font.Bold; color: "#cdd6f4"
            }
        }

        Rectangle { width: 1; height: 14; color: Qt.rgba(1,1,1, 0.10) }

        // Wi-Fi
        Text {
            id: wifiIcon
            text: st.wifiIcon; font.family: "Iosevka Nerd Font"
            font.pixelSize: cfg.iconPx
            color: st.isWifiOn ? "#a6e3a1" : "#7f849c"
            Behavior on color { ColorAnimation { duration: 150 } }
            MouseArea {
                anchors.fill: parent
                onClicked: Quickshell.execDetached(["bash", "-c", "nm-connection-editor"])
            }
        }

        Rectangle { width: 1; height: 14; color: Qt.rgba(1,1,1, 0.10) }

        // Bluetooth
        Text {
            text: st.btIcon; font.family: "Iosevka Nerd Font"
            font.pixelSize: cfg.iconPx
            color: st.isBtOn ? "#89b4fa" : "#7f849c"
            Behavior on color { ColorAnimation { duration: 150 } }
            MouseArea {
                anchors.fill: parent
                onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/waybar/scripts/bluetooth-menu.sh"])
            }
        }

        // Updates – hidden when zero
        Rectangle {
            width: 1; height: 14; color: Qt.rgba(1,1,1, 0.10)
            visible: parseInt(st.updateCount) > 0
        }
        RowLayout {
            spacing: 4
            visible: parseInt(st.updateCount) > 0
            Text {
                text: "󰏗"; font.family: "Iosevka Nerd Font"
                font.pixelSize: cfg.iconPx; color: "#f9e2af"
            }
            Text {
                text: st.updateCount; font.family: "JetBrains Mono"
                font.pixelSize: cfg.labelPx; font.weight: Font.Bold; color: "#cdd6f4"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: Quickshell.execDetached(["bash","-c","~/.config/waybar/scripts/system-update.sh up"])
            }
        }
    }
}
