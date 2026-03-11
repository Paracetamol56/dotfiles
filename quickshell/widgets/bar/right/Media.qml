import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root
    required property var cfg
    required property var st

    property bool isActive:  st.musicData.status !== "Stopped" && st.musicData.title !== ""
    property bool isPlaying: st.musicData.status === "Playing"

    visible:       isActive
    height:        cfg.pillH
    implicitWidth: isActive ? inner.implicitWidth + 16 : 0
    radius:        cfg.pillR
    color:         Qt.rgba(203/255,166/255,247/255, 0.06)
    border.width:  1
    border.color:  Qt.rgba(203/255,166/255,247/255, 0.14)
    clip:          true

    Behavior on implicitWidth { NumberAnimation { duration: 260; easing.type: Easing.OutExpo } }

    RowLayout {
        id: inner
        anchors.centerIn: parent
        spacing: 8

        // Album art
        Rectangle {
            width: cfg.btnSize - 6; height: width
            radius: 5; color: "#313244"; clip: true
            Image {
                anchors.fill: parent
                source:       st.musicData.artUrl || ""
                fillMode:     Image.PreserveAspectCrop
            }
            Text {
                anchors.centerIn: parent
                visible:       st.musicData.artUrl === ""
                text:          ""; font.family: "Iosevka Nerd Font"
                font.pixelSize: 13; color: "#cba6f7"
            }
        }

        // Title + Artist
        ColumnLayout {
            spacing: 0
            Layout.preferredWidth: 120
            Text {
                text:           st.musicData.title
                font.family:    "JetBrains Mono"; font.pixelSize: cfg.labelPx
                font.weight:    Font.Black; color: "#cba6f7"
                elide:          Text.ElideRight; Layout.fillWidth: true
            }
            Text {
                text:           st.musicData.artist
                font.family:    "JetBrains Mono"; font.pixelSize: 9
                color:          "#7f849c"
                elide:          Text.ElideRight; Layout.fillWidth: true
            }
        }

        // Controls
        RowLayout {
            spacing: 1
            Repeater {
                model: [
                    { icon: "",                                   cmd: "previous"    },
                    { icon: root.isPlaying ? "" : "", cmd: "play-pause"  },
                    { icon: "",                                   cmd: "next"        }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: cfg.btnSize - 4; height: width; radius: cfg.pillR - 2
                    color: ctrlMa.containsMouse ? Qt.rgba(203/255,166/255,247/255, 0.22) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent
                        text:           modelData.icon
                        font.family:    "Iosevka Nerd Font"; font.pixelSize: 12
                        color: ctrlMa.containsMouse ? "#cba6f7" : "#9399b2"
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    MouseArea {
                        id: ctrlMa; anchors.fill: parent; hoverEnabled: true
                        onClicked: Quickshell.execDetached(["playerctl", modelData.cmd])
                    }
                }
            }
        }
    }
}
