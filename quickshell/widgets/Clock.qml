import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: clock
    width: 150
    height: 60

    property string time: "00:00"
    property string date: "Monday, January 1"

    Column {
        anchors.centerIn: parent
        spacing: -32
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: clock.time
            color: "#cdd6f4"
            opacity: 0.8
            font.pixelSize: 136
            font.bold: true
            font.family: "FiraCode Nerd Font"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: clock.date
            color: "#cdd6f4"
            opacity: 0.8
            font.pixelSize: 42
            font.bold: true
            font.family: "FiraCode Nerd Font"
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: updateTime()
    }

    function updateTime() {
        var now = new Date()
        clock.time = now.toLocaleTimeString(Qt.locale(), "HH:mm")
        clock.date = Qt.formatDate(now, "dddd dd-MM").toUpperCase()
    }

    Component.onCompleted: updateTime()
}
