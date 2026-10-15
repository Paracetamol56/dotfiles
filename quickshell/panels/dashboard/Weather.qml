import QtQuick
import qs.common
import qs.components
import qs.services

// Current weather + 3-day forecast from wttr.in (location from IP, metric), via Sky
Widget {
    id: root

    readonly property var data: Sky.weather
    readonly property bool failed: Sky.weatherFailed

    readonly property var now: data?.current_condition?.[0] ?? null
    readonly property var days: data?.weather ?? []
    readonly property string place: data?.nearest_area?.[0]?.areaName?.[0]?.value ?? ""

    // wttr.in (WorldWeatherOnline) condition codes → [Lucide icon, colour]
    function look(code, night) {
        code = Number(code);
        if (code === 113)
            return night ? [Icons.moon, Theme.lavender] : [Icons.sun, Theme.yellow];
        if (code === 116)
            return night ? [Icons.cloudMoon, Theme.lavender] : [Icons.cloudSun, Theme.yellow];
        if ([119, 122].includes(code))
            return [Icons.cloud, Theme.overlay2];
        if ([143, 248, 260].includes(code))
            return [Icons.cloudFog, Theme.overlay2];
        if ([200, 386, 389, 392, 395].includes(code))
            return [Icons.cloudLightning, Theme.yellow];
        if ([176, 263, 266, 281, 284, 293, 296, 353].includes(code))
            return [Icons.cloudDrizzle, Theme.sapphire];
        if ([299, 302, 305, 308, 311, 314, 356, 359].includes(code))
            return [Icons.cloudRain, Theme.blue];
        return [Icons.cloudSnow, Theme.sky];
    }

    readonly property bool night: {
        const h = new Date().getHours();
        return h < 7 || h >= 20;
    }

    Label {
        visible: root.now === null
        anchors.centerIn: parent
        text: root.failed ? "Weather unavailable" : "Loading weather…"
        color: Theme.overlay1
        font.pixelSize: 11
    }

    Column {
        visible: root.now !== null
        anchors.fill: parent
        spacing: 2

        Row {
            spacing: 10

            Label {
                readonly property var l: root.look(root.now?.weatherCode, root.night)
                anchors.verticalCenter: parent.verticalCenter
                text: l[0]
                color: l[1]
                font.family: Icons.font
                font.pixelSize: 30
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: (root.now?.temp_C ?? "") + "°"
                font.pixelSize: 30
                font.weight: Font.Bold
            }
        }

        Label {
            width: parent.width
            text: root.now?.weatherDesc?.[0]?.value ?? ""
            color: Theme.subtext1
        }

        Label {
            width: parent.width
            text: `Feels ${root.now?.FeelsLikeC ?? ""}° · ${root.place}`
            font.pixelSize: 10
            color: Theme.overlay1
        }
    }

    // 3-day forecast along the bottom
    Row {
        visible: root.now !== null
        anchors.bottom: parent.bottom
        width: parent.width

        Repeater {
            model: root.days.slice(0, 3)

            Column {
                required property var modelData
                required property int index
                readonly property var l: root.look(modelData.hourly?.[4]?.weatherCode, false)

                width: parent.width / 3
                spacing: 3

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: index === 0 ? "Today" : Qt.formatDate(new Date(modelData.date), "ddd")
                    font.pixelSize: 10
                    color: Theme.subtext0
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: l[0]
                    color: l[1]
                    font.family: Icons.font
                    font.pixelSize: 15
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: `${modelData.maxtempC}°<font color="${Theme.overlay1}"> ${modelData.mintempC}°</font>`
                    textFormat: Text.StyledText
                    font.pixelSize: 10
                }
            }
        }
    }
}
