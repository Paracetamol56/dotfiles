import QtQuick
import Quickshell

Rectangle {
    id: root
    required property var cfg
    required property var st

    width:  cfg.btnSize
    height: cfg.btnSize
    radius: cfg.pillR

    property bool hovered: ma.containsMouse

    color: st.idleInhibited
           ? Qt.rgba(166/255,227/255,161/255, 0.18)
           : (hovered ? Qt.rgba(1,1,1, 0.10) : Qt.rgba(1,1,1, 0.04))
    border.width: 1
    border.color: st.idleInhibited
                  ? Qt.rgba(166/255,227/255,161/255, 0.40)
                  : (hovered ? Qt.rgba(1,1,1, 0.18) : Qt.rgba(1,1,1, 0.08))
    Behavior on color        { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    Text {
        anchors.centerIn: parent
        text:           ""
        font.family:    "Iosevka Nerd Font"
        font.pixelSize: cfg.iconPx + 1
        color: st.idleInhibited ? "#a6e3a1"
             : root.hovered     ? "#cdd6f4"
             :                    "#7f849c"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: st.idleInhibited = !st.idleInhibited
    }
}
