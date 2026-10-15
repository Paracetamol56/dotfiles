import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs.common
import qs.components
import qs.services

// Audio panel: visualizer (waveform + spectrum), output volume and device, microphone
// volume / device / level, and a per-app mixer. Opened from the volume icon in the bar.
Modal {
    id: root

    name: "audio"
    align: "right"
    cardWidth: 420
    cardHeight: apps.y + apps.height + 28

    readonly property var nodes: Pipewire.nodes.values.filter(n => n.audio)
    readonly property var sinks: nodes.filter(n => !n.isStream && n.isSink)
    readonly property var sources: nodes.filter(n => !n.isStream && !n.isSink && (n.properties["media.class"] ?? "") === "Audio/Source")
    // Apps playing sound (output streams)
    readonly property var streams: nodes.filter(n => n.isStream && !n.isSink)
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    // Volume (and mute) are only live for tracked nodes
    PwObjectTracker {
        objects: [root.sink, root.source].concat(root.sinks, root.sources, root.streams).filter(n => n)
    }

    kanji: "音響"

    title: "Sound"
    subtitle: root.sink ? root.deviceName(root.sink) : "No output device"

    function deviceName(n) {
        return n?.description || n?.nickname || n?.name || "Unknown";
    }

    function deviceIcon(n) {
        const s = `${n.name} ${n.description} ${n.properties["device.form-factor"] ?? ""}`.toLowerCase();
        if (/bluez|headset|headphone/.test(s))
            return Icons.headphones;
        if (/hdmi|displayport|monitor/.test(s))
            return Icons.monitor;
        return Icons.speaker;
    }

    function percent(v) {
        return Math.round((v ?? 0) * 100) + "%";
    }

    // ── Visualizer ───────────────────────────────────────

    Visualizer {
        id: visualizer
        blurSource: root.backdrop
        anchors.top: root.header.bottom
        anchors.topMargin: 24
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: 150
        running: root.open
    }

    // ── Output ───────────────────────────────────────────

    Widget {
        id: output
        blurSource: root.backdrop
        anchors.top: visualizer.bottom
        anchors.topMargin: 12
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: outputColumn.implicitHeight + padding * 2

        Column {
            id: outputColumn
            width: parent.width
            spacing: 8

            VolumeRow {
                node: root.sink
                icon: root.sink?.audio?.muted ? Icons.volumeX : Icons.volume2
                accent: Theme.accent
                max: 1.5
            }

            DeviceList {
                devices: root.sinks
                current: root.sink
                onPicked: n => Audio.setDefault(n)
            }
        }
    }

    // ── Microphone ───────────────────────────────────────

    Widget {
        id: input
        blurSource: root.backdrop
        anchors.top: output.bottom
        anchors.topMargin: 12
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: inputColumn.implicitHeight + padding * 2

        // Live input level. Created only while the panel is open: with just `enabled: false`
        // its capture stream on the microphone stayed open all the time
        Loader {
            id: micLevelLoader
            active: root.open && root.source !== null
            sourceComponent: PwNodePeakMonitor {
                node: root.source
            }
        }
        readonly property real micPeak: micLevelLoader.item?.peak ?? 0

        Column {
            id: inputColumn
            width: parent.width
            spacing: 8

            VolumeRow {
                node: root.source
                icon: root.source?.audio?.muted ? Icons.micOff : Icons.mic
                accent: Theme.sapphire
                max: 1.5
            }

            // Level meter, under the slider
            Rectangle {
                x: 34
                width: parent.width - 34 - 48
                height: 3
                radius: 1.5
                color: Qt.alpha(Theme.surface1, 0.6)

                Rectangle {
                    width: parent.width * Math.min(1, input.micPeak)
                    height: parent.height
                    radius: parent.radius
                    color: input.micPeak > 0.9 ? Theme.red : Theme.green

                    Behavior on width {
                        NumberAnimation {
                            duration: 60
                        }
                    }
                }
            }

            DeviceList {
                devices: root.sources
                current: root.source
                onPicked: n => Audio.setDefault(n)
            }
        }
    }

    // ── Apps ─────────────────────────────────────────────

    Widget {
        id: apps
        blurSource: root.backdrop
        anchors.top: input.bottom
        anchors.topMargin: 12
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: Math.max(appsColumn.implicitHeight, 20) + padding * 2

        Label {
            visible: root.streams.length === 0
            anchors.centerIn: parent
            text: "No apps playing sound"
            font.pixelSize: 11
            color: Theme.overlay1
        }

        Column {
            id: appsColumn
            width: parent.width
            spacing: 10

            Repeater {
                model: root.streams

                Column {
                    id: app
                    required property PwNode modelData
                    readonly property string appName: modelData.properties["application.name"] || modelData.description || modelData.name
                    readonly property string iconName: modelData.properties["application.icon-name"] ?? ""

                    width: parent.width
                    spacing: 4

                    Row {
                        spacing: 8

                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 16
                            source: Quickshell.iconPath(app.iconName || app.appName.toLowerCase(), true)
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, appsColumn.width - 40)
                            text: app.appName + (app.modelData.properties["media.name"] ? `  ·  ${app.modelData.properties["media.name"]}` : "")
                            font.pixelSize: 11
                            color: Theme.subtext1
                        }
                    }

                    VolumeRow {
                        node: app.modelData
                        icon: app.modelData.audio?.muted ? Icons.volumeX : Icons.volume1
                        accent: Theme.lavender
                        max: 1.5
                    }
                }
            }
        }
    }

    // Mute button, slider and percentage for one node
    component VolumeRow: Item {
        id: volumeRow

        property PwNode node
        property string icon
        property color accent
        property real max: 1

        readonly property bool muted: node?.audio?.muted ?? false

        width: parent.width
        height: 26

        Rectangle {
            id: mute
            width: 26
            height: 26
            radius: Theme.radius
            color: muteMouse.containsMouse ? Qt.alpha(Theme.surface1, 0.7) : "transparent"

            Label {
                anchors.centerIn: parent
                text: volumeRow.icon
                font.family: Icons.font
                font.pixelSize: 15
                color: volumeRow.muted ? Theme.overlay1 : volumeRow.accent
            }

            MouseArea {
                id: muteMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Audio.toggleMute(volumeRow.node)
            }
        }

        Slider {
            anchors.left: mute.right
            anchors.leftMargin: 8
            anchors.right: value.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            value: volumeRow.node?.audio?.volume ?? 0
            max: volumeRow.max
            accent: volumeRow.accent
            muted: volumeRow.muted
            onMoved: v => Audio.setVolume(volumeRow.node, v)
        }

        Label {
            id: value
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            horizontalAlignment: Text.AlignRight
            text: root.percent(volumeRow.node?.audio?.volume)
            font.pixelSize: 11
            color: volumeRow.muted ? Theme.overlay1 : (volumeRow.node?.audio?.volume ?? 0) > 1 ? Theme.peach : Theme.text
        }
    }

    // Device choices; the current one is ticked. Hidden when there's only one.
    component DeviceList: Column {
        id: deviceList

        property var devices: []
        property PwNode current
        signal picked(PwNode node)

        visible: devices.length > 1
        width: parent.width
        spacing: 2

        Repeater {
            model: deviceList.devices

            Rectangle {
                id: device
                required property PwNode modelData
                readonly property bool active: modelData === deviceList.current

                width: deviceList.width
                height: 30
                radius: Theme.radius
                color: deviceMouse.containsMouse ? Qt.alpha(Theme.surface1, 0.5) : active ? Qt.alpha(Theme.surface0, 0.6) : "transparent"

                Label {
                    id: deviceIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.deviceIcon(device.modelData)
                    font.family: Icons.font
                    font.pixelSize: 13
                    color: device.active ? Theme.text : Theme.overlay1
                }

                Label {
                    anchors.left: deviceIcon.right
                    anchors.leftMargin: 10
                    anchors.right: tick.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.deviceName(device.modelData)
                    font.pixelSize: 11
                    color: device.active ? Theme.text : Theme.subtext0
                }

                Label {
                    id: tick
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    visible: device.active
                    text: Icons.check
                    font.family: Icons.font
                    font.pixelSize: 13
                    color: Theme.green
                }

                MouseArea {
                    id: deviceMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: deviceList.picked(device.modelData)
                }
            }
        }
    }
}
