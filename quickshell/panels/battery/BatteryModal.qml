import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.common
import qs.components
import qs.services

// Battery panel: charge level, charge/discharge rate, time left, health, and the fans.
// Opened from the battery in the bar.
Modal {
    id: root

    name: "battery"
    align: "right"
    cardWidth: 380
    cardHeight: fansCard.y + fansCard.height + 28

    // Same device as the bar; the composite display device has no design capacity, so health
    // comes from the laptop battery itself
    readonly property var dev: UPower.displayDevice
    readonly property var cell: UPower.devices.values.find(d => d.isLaptopBattery) ?? null
    readonly property int pct: Math.round((dev?.percentage ?? 0) * 100)
    readonly property int state: dev?.state ?? UPowerDeviceState.Unknown
    readonly property bool charging: state === UPowerDeviceState.Charging
    readonly property bool discharging: state === UPowerDeviceState.Discharging
    readonly property real rate: Math.abs(dev?.changeRate ?? 0)
    readonly property color levelColor: charging ? Theme.yellow : pct <= 15 ? Theme.red : pct <= 30 ? Theme.peach : Theme.green

    // Charge level over the last hour, one point a minute (0..100), from UPower's own history
    property var history: []
    // [{ label, rpm }] from every hwmon fan
    property var fans: []
    // Fan modes, through power-profiles-daemon: it sets the ACPI platform profile, which is
    // the fan curve on ASUS (power-saver is "quiet")
    readonly property var modes: [
        { profile: PowerProfile.PowerSaver, icon: Icons.leaf, text: "Quiet", color: Theme.green },
        { profile: PowerProfile.Balanced, icon: Icons.gauge, text: "Balanced", color: Theme.accent },
        { profile: PowerProfile.Performance, icon: Icons.rocket, text: "Performance", color: Theme.red }
    ]
    readonly property int modeIndex: modes.findIndex(m => m.profile === PowerProfiles.profile)

    kanji: "電池"

    title: "Battery"
    subtitle: ({
            [UPowerDeviceState.Charging]: "Charging",
            [UPowerDeviceState.Discharging]: "On battery",
            [UPowerDeviceState.FullyCharged]: "Fully charged",
            [UPowerDeviceState.PendingCharge]: "Plugged in, not charging",
            [UPowerDeviceState.PendingDischarge]: "Plugged in, not charging",
            [UPowerDeviceState.Empty]: "Empty"
        })[state] ?? "Unknown state"

    function duration(s) {
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60);
        return h ? `${h}h ${m}min` : `${m}min`;
    }

    // "cpu_fan" → "CPU fan"
    function fanName(label) {
        const words = label.replace(/_/g, " ");
        return words.replace(/^(cpu|gpu)\b/i, w => w.toUpperCase()).replace(/^./, c => c.toUpperCase());
    }

    // Fans only change while the panel is open, so only poll then
    Timer {
        interval: 2000
        running: root.open
        repeat: true
        triggeredOnStart: true
        onTriggered: fanReader.running = true
    }

    // History on opening, then every minute and whenever the level changes
    onPctChanged: if (open) historyReader.running = true

    Timer {
        interval: 60000
        running: root.open
        repeat: true
        triggeredOnStart: true
        onTriggered: historyReader.running = true
    }

    // UPower only logs a point when the level or state changes, so ask for a day to know the
    // level at the start of the hour too. Prints entries like (uint32 1793126005, 98.0, uint32 2)
    Process {
        id: historyReader
        command: ["sh", "-c", "p=$(upower -e | grep -m1 /battery_) && gdbus call --system --dest org.freedesktop.UPower --object-path \"$p\" --method org.freedesktop.UPower.Device.GetHistory charge 86400 1000"]
        stdout: StdioCollector {
            onStreamFinished: {
                // [time, level], oldest first; state 0 ("unknown") entries carry no level
                const entries = [];
                const re = /\((?:uint32 )?(\d+), ([\d.]+), (?:uint32 )?(\d+)\)/g;
                let m;
                while ((m = re.exec(text)) !== null)
                    if (m[3] !== "0")
                        entries.push([parseInt(m[1]), parseFloat(m[2])]);
                entries.sort((a, b) => a[0] - b[0]);

                // Each minute takes the last level logged before it; minutes before the first
                // entry are left out, and the newest point is the live level
                const now = Date.now() / 1000;
                const points = [];
                let e = 0, level = -1;
                for (let i = 60; i > 0; i--) {
                    const t = now - i * 60;
                    while (e < entries.length && entries[e][0] <= t)
                        level = entries[e++][1];
                    if (level >= 0)
                        points.push(level);
                }
                points.push(root.pct);
                root.history = points;
            }
        }
    }

    // label:rpm per fan (hwmon indexes change between boots, so glob them)
    Process {
        id: fanReader
        command: ["sh", "-c", `
            for f in /sys/class/hwmon/hwmon*/fan*_input; do
              [ -e "$f" ] || continue
              l="\${f%_input}_label"
              printf '%s:%s\\n' "$(cat "$l" 2>/dev/null || basename "\${f%_input}")" "$(cat "$f")"
            done`]
        stdout: StdioCollector {
            onStreamFinished: {
                root.fans = text.split("\n").filter(l => l).map(l => {
                    const i = l.lastIndexOf(":");
                    return { label: root.fanName(l.slice(0, i)), rpm: parseInt(l.slice(i + 1)) || 0 };
                });
            }
        }
    }

    // ── Level ───────────────────────────────────────────

    Widget {
        id: levelCard
        blurSource: root.backdrop
        anchors.top: root.header.bottom
        anchors.topMargin: 24
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: 170

        Label {
            id: big
            text: root.pct + "%"
            font.pixelSize: 28
            font.weight: Font.Bold
            color: root.levelColor
        }

        Label {
            anchors.right: parent.right
            anchors.baseline: big.baseline
            font.pixelSize: 11
            color: Theme.subtext0
            text: root.charging && root.dev.timeToFull > 0 ? `${root.duration(root.dev.timeToFull)} to full` : root.discharging && root.dev.timeToEmpty > 0 ? `${root.duration(root.dev.timeToEmpty)} left` : ""
        }

        // Last hour, newest on the right
        Graph {
            id: levelGraph
            anchors.top: big.bottom
            anchors.topMargin: 8
            anchors.bottom: graphCaption.top
            anchors.bottomMargin: 4
            width: parent.width
            max: 100
            length: 61
            series: [{ values: root.history, color: root.levelColor }]
        }

        Label {
            id: graphCaption
            anchors.bottom: parent.bottom
            width: parent.width
            text: "1 h ago"
            font.pixelSize: 9
            color: Theme.overlay1

            Label {
                anchors.right: parent.right
                text: "now"
                font.pixelSize: 9
                color: Theme.overlay1
            }
        }
    }

    // ── Power ───────────────────────────────────────────

    Widget {
        id: powerCard
        blurSource: root.backdrop
        anchors.top: levelCard.bottom
        anchors.topMargin: 12
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: powerColumn.implicitHeight + padding * 2

        Column {
            id: powerColumn
            width: parent.width
            spacing: 8

            Reading {
                labelWidth: 100
                icon: Icons.zap
                iconColor: root.charging ? Theme.yellow : root.discharging ? Theme.peach : Theme.overlay1
                label: root.charging ? "Charge rate" : root.discharging ? "Discharge rate" : "Power draw"
                value: root.charging || root.discharging ? `${root.rate.toFixed(1)} W` : "–"
            }

            Reading {
                labelWidth: 100
                icon: Icons.batteryFull
                iconColor: Theme.green
                label: "Energy"
                value: `${(root.dev?.energy ?? 0).toFixed(1)} / ${(root.dev?.energyCapacity ?? 0).toFixed(1)} Wh`
            }

            Reading {
                visible: (root.cell?.healthPercentage ?? 0) > 0
                labelWidth: 100
                icon: Icons.heartPulse
                iconColor: Theme.red
                label: "Health"
                value: `${Math.round(root.cell?.healthPercentage ?? 0)}% of design capacity`
            }
        }
    }

    // ── Fans ────────────────────────────────────────────

    Widget {
        id: fansCard
        blurSource: root.backdrop
        anchors.top: powerCard.bottom
        anchors.topMargin: 12
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: fansColumn.implicitHeight + padding * 2

        Column {
            id: fansColumn
            width: parent.width
            spacing: 8

            // Fan mode: segmented buttons, the highlight slides to the active one
            Item {
                width: parent.width
                height: 32

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius
                    color: Qt.alpha(Theme.surface0, 0.8)
                }

                Rectangle {
                    readonly property var mode: root.modes[Math.max(0, root.modeIndex)]
                    visible: root.modeIndex >= 0
                    x: root.modeIndex * width
                    width: parent.width / root.modes.length
                    height: parent.height
                    radius: Theme.radius
                    color: Qt.alpha(mode.color, 0.25)
                    border.width: 1
                    border.color: Qt.alpha(mode.color, 0.6)

                    Behavior on x {
                        NumberAnimation {
                            duration: 260
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 260
                        }
                    }
                    Behavior on border.color {
                        ColorAnimation {
                            duration: 260
                        }
                    }
                }

                Row {
                    anchors.fill: parent

                    Repeater {
                        model: root.modes

                        Item {
                            id: segment

                            required property var modelData
                            required property int index
                            readonly property bool active: root.modeIndex === index
                            readonly property bool available: modelData.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile

                            width: parent.width / root.modes.length
                            height: parent.height
                            opacity: available ? 1 : 0.4

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                // Small press bounce
                                scale: segmentMouse.pressed ? 0.92 : 1

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 120
                                    }
                                }

                                Label {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: segment.modelData.icon
                                    font.family: Icons.font
                                    font.pixelSize: 13
                                    color: segment.active ? segment.modelData.color : segmentMouse.containsMouse ? Theme.text : Theme.overlay1

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Theme.animDuration
                                        }
                                    }
                                }

                                Label {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: segment.modelData.text
                                    font.pixelSize: 11
                                    font.weight: segment.active ? Font.Bold : Font.Normal
                                    color: segment.active ? Theme.text : segmentMouse.containsMouse ? Theme.subtext1 : Theme.overlay1

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Theme.animDuration
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: segmentMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: segment.available ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: if (segment.available && !segment.active) PowerProfiles.profile = segment.modelData.profile
                            }
                        }
                    }
                }
            }

            Repeater {
                model: root.fans

                Reading {
                    id: fanReading

                    required property var modelData
                    labelWidth: 100
                    iconColor: modelData.rpm > 0 ? Theme.sapphire : Theme.overlay1
                    label: modelData.label
                    value: modelData.rpm > 0 ? `${modelData.rpm} RPM` : "Off"

                    // Spinning fan in place of the static icon, faster with the RPM (one turn
                    // per second at 2500 RPM); speed changes don't restart the spin
                    Label {
                        id: fanIcon
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14
                        horizontalAlignment: Text.AlignHCenter
                        text: Icons.fan
                        font.family: Icons.font
                        font.pixelSize: 12
                        color: fanReading.iconColor

                        FrameAnimation {
                            running: root.open && fanReading.modelData.rpm > 0
                            onTriggered: fanIcon.rotation = (fanIcon.rotation + frameTime * fanReading.modelData.rpm * 360 / 2500) % 360
                        }
                    }
                }
            }

            Reading {
                visible: root.fans.length === 0
                labelWidth: 100
                icon: Icons.fan
                iconColor: Theme.overlay1
                label: "Fans"
                value: "No fan sensor found"
            }
        }
    }
}
