import QtQuick
import Quickshell
import qs.common
import qs.components
import qs.services

// Performance: CPU / RAM / network graphs, per-core load, GPU, top processes, disks, and the
// carbon footprint of the running PC. Opened from the temperature, memory or CPU in the bar.
Modal {
    id: root

    name: "performance"
    cardWidth: 800
    cardHeight: disks.y + disks.height + 28

    // Power estimate (W), from 1-minute averages so the carbon figure doesn't jump around.
    // GPU: measured by nvidia-smi. CPU: Intel's energy counters are root-only, so it's
    // modelled from load for the i5-9600K (~8 W idle, ~95 W at full load).
    // Rest: motherboard, RAM, drives, fans; monitors not included.
    readonly property real gpuWatts: Math.max(0, Perf.gpuPowerAverage)
    readonly property real cpuWatts: 8 + Math.max(0, Perf.cpuAverage) * 87
    readonly property real restWatts: 30
    readonly property real watts: gpuWatts + cpuWatts + restWatts
    // g/h = kW × gCO₂/kWh
    readonly property real gramsPerHour: Carbon.intensity >= 0 ? watts / 1000 * Carbon.intensity : -1

    kanji: "性能"

    title: "Performance"
    subtitle: `${Stats.cpuModel} · ${Perf.cores.length} cores · load ${Perf.load}`

    onOpenChanged: {
        Perf.active = open;
        if (open)
            Carbon.refresh();
    }

    function bytes(b, perSecond) {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        while (b >= 1024 && i < units.length - 1) {
            b /= 1024;
            i++;
        }
        return `${b.toFixed(b < 10 && i > 0 ? 1 : 0)} ${units[i]}${perSecond ? "/s" : ""}`;
    }

    readonly property real columnWidth: (cardWidth - 56 - 32) / 3

    // ── Row 1: graphs ────────────────────────────────────

    GraphCard {
        id: cpuCard
        anchors.top: root.header.bottom
        anchors.topMargin: 24
        anchors.left: root.header.left
        icon: Icons.cpu
        iconColor: Theme.green
        label: "CPU"
        value: Math.round(Perf.cpu * 100) + "%"
        detail: `${Stats.cpuTemp}°C · ${Stats.cpuFreq}`
        graph.series: [{ values: Perf.cpuHistory, color: Theme.green }]
    }

    GraphCard {
        id: ramCard
        anchors.top: cpuCard.top
        anchors.left: cpuCard.right
        anchors.leftMargin: 16
        icon: Icons.memoryStick
        iconColor: Theme.blue
        label: "Memory"
        value: Math.round(Perf.ram * 100) + "%"
        detail: `${Perf.ramUsed.toFixed(1)} / ${Perf.ramTotal.toFixed(1)} GB · swap ${Perf.swapUsed.toFixed(1)} GB`
        graph.series: [{ values: Perf.ramHistory, color: Theme.blue }]
    }

    GraphCard {
        id: netCard
        anchors.top: cpuCard.top
        anchors.left: ramCard.right
        anchors.leftMargin: 16
        icon: Icons.activity
        iconColor: Theme.sapphire
        label: "Network"
        value: `<font color="${Theme.sapphire}">↓</font> ${root.bytes(Perf.rx, true)}`
        detail: `<font color="${Theme.peach}">↑</font> ${root.bytes(Perf.tx, true)} · scale ${root.bytes(Math.max(1, ...Perf.rxHistory, ...Perf.txHistory), true)}`
        // Download above the centre line, upload below it
        graph.max: 0
        graph.mirror: true
        graph.series: [{ values: Perf.rxHistory, color: Theme.sapphire }, { values: Perf.txHistory, color: Theme.peach }]
    }

    // ── Row 2: cores, GPU, top processes ─────────────────

    Widget {
        id: coresCard
        blurSource: root.backdrop
        anchors.top: cpuCard.bottom
        anchors.topMargin: 16
        anchors.left: root.header.left
        width: root.columnWidth
        height: 150

        CardTitle {
            id: coresTitle
            icon: Icons.gauge
            iconColor: Theme.green
            text: "Per core"
        }

        Row {
            anchors.top: coresTitle.bottom
            anchors.topMargin: 10
            anchors.bottom: parent.bottom
            width: parent.width
            spacing: 6

            Repeater {
                model: Perf.cores

                Item {
                    required property real modelData
                    required property int index
                    width: (parent.width - parent.spacing * (Perf.cores.length - 1)) / Math.max(1, Perf.cores.length)
                    height: parent.height

                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: coreLabel.top
                        anchors.bottomMargin: 4
                        width: parent.width
                        radius: Theme.radius
                        color: Qt.alpha(Theme.surface1, 0.5)

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: Math.max(2, parent.height * modelData)
                            radius: Theme.radius
                            color: modelData > 0.85 ? Theme.red : modelData > 0.6 ? Theme.peach : Theme.green

                            Behavior on height {
                                NumberAnimation {
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }

                    Label {
                        id: coreLabel
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Math.round(modelData * 100)
                        font.pixelSize: 9
                        color: Theme.overlay1
                    }
                }
            }
        }
    }

    Widget {
        id: gpuCard
        blurSource: root.backdrop
        anchors.top: coresCard.top
        anchors.left: coresCard.right
        anchors.leftMargin: 16
        width: root.columnWidth
        height: coresCard.height

        CardTitle {
            id: gpuTitle
            icon: Icons.gpu
            iconColor: Theme.peach
            text: Perf.gpu?.name ?? "GPU"
        }

        Column {
            anchors.top: gpuTitle.bottom
            anchors.topMargin: 12
            width: parent.width
            spacing: 9

            Meter {
                label: "Load"
                fraction: Perf.gpu?.util ?? 0
                value: Math.round((Perf.gpu?.util ?? 0) * 100) + "%"
                color: Theme.peach
            }

            Meter {
                label: "VRAM"
                fraction: Perf.gpu ? Perf.gpu.memUsed / Perf.gpu.memTotal : 0
                value: Perf.gpu ? `${(Perf.gpu.memUsed / 1024).toFixed(1)} / ${(Perf.gpu.memTotal / 1024).toFixed(0)} GB` : "–"
                color: Theme.accent
            }

            Meter {
                label: "Power"
                fraction: Perf.gpu ? Perf.gpu.power / Perf.gpu.powerLimit : 0
                value: Perf.gpu ? `${Perf.gpu.power.toFixed(0)} W · ${Perf.gpu.temp}°C` : "–"
                color: Theme.yellow
            }
        }
    }

    Widget {
        id: topCard
        blurSource: root.backdrop
        anchors.top: coresCard.top
        anchors.left: gpuCard.right
        anchors.leftMargin: 16
        width: root.columnWidth
        height: coresCard.height

        CardTitle {
            id: topTitle
            icon: Icons.list
            iconColor: Theme.lavender
            text: "Top processes"
        }

        Column {
            anchors.top: topTitle.bottom
            anchors.topMargin: 8
            width: parent.width
            spacing: 4

            Repeater {
                model: Perf.top

                Item {
                    required property var modelData
                    width: parent.width
                    height: 18

                    Label {
                        anchors.left: parent.left
                        anchors.right: cpuValue.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        font.pixelSize: 11
                    }

                    Label {
                        id: cpuValue
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: `${modelData.cpu.toFixed(0)}%`
                        font.pixelSize: 11
                        color: modelData.cpu > 50 ? Theme.peach : Theme.subtext0
                    }
                }
            }
        }
    }

    // ── Row 3: disks, carbon ─────────────────────────────

    Widget {
        id: disks
        blurSource: root.backdrop
        anchors.top: coresCard.bottom
        anchors.topMargin: 16
        anchors.left: root.header.left
        width: root.columnWidth * 1.5 + 8
        height: Math.max(170, diskColumn.implicitHeight + diskTitle.height + 38)

        CardTitle {
            id: diskTitle
            icon: Icons.hardDrive
            iconColor: Theme.yellow
            text: "Disks"
        }

        Column {
            id: diskColumn
            anchors.top: diskTitle.bottom
            anchors.topMargin: 12
            width: parent.width
            spacing: 9

            Repeater {
                model: Perf.disks

                Meter {
                    required property var modelData
                    label: modelData.mount
                    labelWidth: 80
                    fraction: modelData.used / modelData.size
                    value: `${root.bytes(modelData.used)} / ${root.bytes(modelData.size)}`
                    color: fraction > 0.9 ? Theme.red : fraction > 0.75 ? Theme.peach : Theme.yellow
                }
            }
        }
    }

    Widget {
        id: carbon
        blurSource: root.backdrop
        anchors.top: disks.top
        anchors.left: disks.right
        anchors.leftMargin: 16
        anchors.right: root.header.right
        height: disks.height

        CardTitle {
            id: carbonTitle
            icon: Icons.leaf
            iconColor: Theme.green
            text: Carbon.zone ? `Carbon · grid ${Carbon.zone}` : "Carbon"
        }

        // Without a token: how to set it up
        Label {
            visible: !Carbon.configured
            anchors.top: carbonTitle.bottom
            anchors.topMargin: 14
            width: parent.width
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
            textFormat: Text.StyledText
            font.pixelSize: 11
            color: Theme.subtext0
            text: `Add a free Electricity Maps API token to<br><font color="${Theme.lavender}">~/.config/quickshell/secrets/<br>electricitymaps-token</font><br><br>Get one at app.electricitymaps.com · it's picked up automatically.`
        }

        Column {
            visible: Carbon.configured
            anchors.top: carbonTitle.bottom
            anchors.topMargin: 10
            width: parent.width
            spacing: 6

            // Headline: grams of CO₂ per hour for the PC right now
            Row {
                spacing: 8

                Label {
                    id: grams
                    text: root.gramsPerHour >= 0 ? root.gramsPerHour.toFixed(root.gramsPerHour < 10 ? 1 : 0) : "–"
                    font.pixelSize: 30
                    font.weight: Font.Bold
                    color: Theme.green
                }

                Label {
                    anchors.baseline: grams.baseline
                    text: "g CO₂eq / hour"
                    color: Theme.subtext1
                }
            }

            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
                text: Carbon.error || (Carbon.intensity >= 0 ? `Grid ${Math.round(Carbon.intensity)} g/kWh${Carbon.renewable >= 0 ? ` · ${Math.round(Carbon.renewable)}% renewable` : ""}${Carbon.fossilFree >= 0 ? ` · ${Math.round(Carbon.fossilFree)}% fossil-free` : ""}` : "Fetching grid data…")
                font.pixelSize: 11
                color: Carbon.error ? Theme.red : Theme.subtext0
            }

            // Power behind it: total, then measured vs estimated parts
            Label {
                width: parent.width
                text: `≈ ${Math.round(root.watts)} W · 1-min average · monitors excluded`
                font.pixelSize: 10
                color: Theme.overlay1
            }

            Label {
                width: parent.width
                text: `GPU ${Math.round(root.gpuWatts)} W measured · CPU ${Math.round(root.cpuWatts)} + rest ${root.restWatts} W est.`
                font.pixelSize: 10
                color: Theme.overlay1
            }

            Label {
                width: parent.width
                visible: root.gramsPerHour >= 0
                text: `≈ ${(root.gramsPerHour * 24 / 1000).toFixed(2)} kg CO₂eq per day at this rate`
                font.pixelSize: 10
                color: Theme.overlay1
            }
        }
    }

    // ── Building blocks ──────────────────────────────────

    component CardTitle: Row {
        property string icon
        property color iconColor
        property string text

        spacing: 8

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.icon
            font.family: Icons.font
            font.pixelSize: 14
            color: parent.iconColor
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.text
            font.pixelSize: 11
            font.weight: Font.Bold
            color: Theme.subtext1
        }
    }

    // Graph with a title, the current value and a detail line
    component GraphCard: Widget {
        id: card

        property string icon
        property color iconColor
        property string label
        property string value
        property string detail
        property alias graph: graph

        blurSource: root.backdrop
        width: root.columnWidth
        height: 170

        CardTitle {
            id: title
            icon: card.icon
            iconColor: card.iconColor
            text: card.label
        }

        Label {
            id: big
            anchors.top: title.bottom
            anchors.topMargin: 4
            textFormat: Text.StyledText
            text: card.value
            font.pixelSize: 20
            font.weight: Font.Bold
        }

        Label {
            id: small
            anchors.top: big.bottom
            width: parent.width
            textFormat: Text.StyledText
            text: card.detail
            font.pixelSize: 10
            color: Theme.overlay1
        }

        Graph {
            id: graph
            anchors.top: small.bottom
            anchors.topMargin: 8
            anchors.bottom: parent.bottom
            width: parent.width
        }
    }

    // Label, bar and value on one line
    component Meter: Item {
        id: meter

        property string label
        property int labelWidth: 46
        property real fraction
        property string value
        property color color

        width: parent.width
        height: 16

        Label {
            id: meterLabel
            width: meter.labelWidth
            anchors.verticalCenter: parent.verticalCenter
            text: meter.label
            font.pixelSize: 10
            color: Theme.overlay1
        }

        Rectangle {
            anchors.left: meterLabel.right
            anchors.right: meterValue.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 5
            radius: 2.5
            color: Qt.alpha(Theme.surface1, 0.6)

            Rectangle {
                width: parent.width * Math.min(1, Math.max(0, meter.fraction))
                height: parent.height
                radius: parent.radius
                color: meter.color

                Behavior on width {
                    NumberAnimation {
                        duration: 300
                    }
                }
            }
        }

        Label {
            id: meterValue
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 118
            horizontalAlignment: Text.AlignRight
            text: meter.value
            font.pixelSize: 10
            color: Theme.subtext0
        }
    }
}
