import QtQuick
import QtQuick.Layouts

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
        spacing: 10

        // Temperature
        RowLayout {
            spacing: 4
            Text {
                text: ""; font.family: "Iosevka Nerd Font"
                font.pixelSize: cfg.iconPx; color: "#f38ba8"
            }
            Text {
                text: st.cpuTemp; font.family: "JetBrains Mono"
                font.pixelSize: cfg.labelPx; font.weight: Font.Bold; color: "#cdd6f4"
            }
        }

        Rectangle { width: 1; height: 14; color: Qt.rgba(1,1,1, 0.10) }

        // RAM
        RowLayout {
            spacing: 4
            Text {
                text: "󰍛"; font.family: "Iosevka Nerd Font"
                font.pixelSize: cfg.iconPx; color: "#cba6f7"
            }
            Text {
                text: st.ramUsage; font.family: "JetBrains Mono"
                font.pixelSize: cfg.labelPx; font.weight: Font.Bold; color: "#cdd6f4"
            }
        }

        Rectangle { width: 1; height: 14; color: Qt.rgba(1,1,1, 0.10) }

        // CPU
        RowLayout {
            spacing: 4
            Text {
                text: ""; font.family: "Iosevka Nerd Font"
                font.pixelSize: cfg.iconPx; color: "#fab387"
            }
            Text {
                text: st.cpuUsage; font.family: "JetBrains Mono"
                font.pixelSize: cfg.labelPx; font.weight: Font.Bold; color: "#cdd6f4"
            }
        }
    }
}
