import QtQuick

Rectangle {
    id: root
    required property var cfg
    required property var st

    height:        cfg.pillH
    implicitWidth: Math.min(titleText.implicitWidth + 18, 260)
    radius:        cfg.pillR
    color:         Qt.rgba(1,1,1, 0.03)
    border.width:  1
    border.color:  Qt.rgba(1,1,1, 0.06)
    clip:          true
    visible:       st.windowTitle !== ""

    Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutExpo } }

    Text {
        id: titleText
        anchors {
            verticalCenter: parent.verticalCenter
            left:  parent.left;  leftMargin:  9
            right: parent.right; rightMargin: 9
        }
        text:           st.windowTitle
        font.family:    "JetBrains Mono"
        font.pixelSize: cfg.labelPx
        color:          "#a6adc8"
        elide:          Text.ElideRight
    }
}
