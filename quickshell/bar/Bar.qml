import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.common
import qs.components
import qs.services

// Port of the waybar config: launcher + workspaces + title on the left,
// stats / clock / tray in the centre, media + volume + power on the right.
// Plain Lucide icons and text, no buttons; groups are separated by wider gaps.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: 10
        left: 10
        right: 10
    }
    implicitHeight: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "quickshell-bar"

    function run(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    IdleInhibitor {
        window: bar
        enabled: Stats.presentationMode
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.transparentBase
    }

    // ── Left ─────────────────────────────────────────────

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.inset
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacing

        // Launcher
        Module {
            icon: Icons.rocket
            iconColor: Theme.mauve
            clickable: true
            tooltip: "Applications"
            onClicked: Panels.toggle("launcher", bar.modelData)
        }

        // Workspaces: the active one is mauve, with an underline that slides to it
        Item {
            implicitWidth: workspaces.implicitWidth
            implicitHeight: Theme.pillHeight

            Row {
                id: workspaces

                Repeater {
                    id: wsRepeater
                    model: 8

                    Module {
                        required property int index
                        readonly property int wsId: index + 1
                        readonly property bool active: bar.monitor?.activeWorkspace?.id === wsId
                        readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === wsId && w.toplevels.values.length > 0)

                        // Kanji numerals instead of digits
                        text: ["一", "二", "三", "四", "五", "六", "七", "八"][index]

                        label.font.family: "Noto Sans CJK JP"
                        padding: 8
                        minWidth: 26
                        clickable: !active
                        textColor: active ? Theme.mauve : occupied ? Theme.text : Theme.overlay0
                        onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${wsId} })`)
                        onScrolled: steps => {
                            const cur = bar.monitor?.activeWorkspace?.id ?? 1;
                            const next = Math.max(1, Math.min(8, cur - steps));
                            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${next} })`);
                        }
                    }
                }
            }

            Rectangle {
                // itemAt() isn't reactive; reading count re-evaluates once the buttons exist
                readonly property Item target: wsRepeater.count ? wsRepeater.itemAt((bar.monitor?.activeWorkspace?.id ?? 1) - 1) : null

                visible: target !== null
                width: 12
                height: 2
                radius: 1
                x: (target?.x ?? 0) + ((target?.width ?? 0) - width) / 2
                anchors.bottom: parent.bottom
                color: Theme.mauve

                Behavior on x {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        WindowTitle {
            monitor: bar.monitor
        }
    }

    // ── Centre ───────────────────────────────────────────
    // The Arch button is pinned to the exact middle; the stats hang off its
    // left edge and the clock / updates off its right, whatever their widths.

    // Arch button, the bar's only solid button: toggles the dashboard on this screen
    Rectangle {
        id: archButton

        readonly property bool active: Panels.isOpen("dashboard", bar.modelData)

        implicitWidth: 48
        implicitHeight: Theme.pillHeight
        anchors.centerIn: parent
        radius: height / 2
        color: active ? Theme.lavender : archMouse.containsMouse ? Qt.lighter(Theme.mauve, 1.08) : Theme.mauve

        Behavior on color {
            ColorAnimation {
                duration: Theme.animDuration
            }
        }

        MouseArea {
            id: archMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Panels.toggle("dashboard", bar.modelData)
        }

        BarText {
            anchors.centerIn: parent
            text: "\u{f303}" // nf-linux-archlinux
            color: Theme.base
            shadow: false
            font.pixelSize: 16
            font.weight: Font.Normal
        }
    }

    Group {
        anchors.right: archButton.left
        anchors.rightMargin: Theme.spacing
        anchors.verticalCenter: parent.verticalCenter
        // CPU temperature
        Module {
            readonly property int t: Stats.cpuTemp
            minWidth: 84
            icon: t >= 70 ? Icons.thermometerSun : Icons.thermometer
            iconColor: t >= 80 ? Theme.red : Theme.peach
            text: t + "°C"
            textColor: t >= 80 ? Theme.red : Theme.text
            tooltip: `Temperature: ${t}°C\nClock Speed: ${Stats.cpuFreq}`
            clickable: true
            onClicked: Panels.toggle("performance", bar.modelData)
        }

        // Memory
        Module {
            readonly property int p: Stats.memPercent
            minWidth: 76
            icon: p >= 90 ? Icons.triangleAlert : Icons.memoryStick
            iconColor: p >= 90 ? Theme.red : p >= 75 ? Theme.peach : Theme.blue
            text: p + "%"
            textColor: p >= 90 ? Theme.red : p >= 75 ? Theme.peach : Theme.text
            tooltip: `Memory Used: ${Stats.memUsed.toFixed(1)} GB / ${Stats.memTotal.toFixed(1)} GB`
            clickable: true
            onClicked: Panels.toggle("performance", bar.modelData)
        }

        // CPU usage
        Module {
            readonly property int u: Stats.cpuUsage
            minWidth: 76
            icon: u >= 80 ? Icons.triangleAlert : Icons.cpu
            iconColor: u >= 80 ? Theme.red : Theme.green
            text: u + "%"
            textColor: u >= 80 ? Theme.red : Theme.text
            tooltip: Stats.cpuModel + "\nCPU Usage: " + (u >= 80 ? "Critical" : u >= 60 ? "High" : u >= 25 ? "Moderate" : "Low")
            clickable: true
            onClicked: Panels.toggle("performance", bar.modelData)
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        anchors.left: archButton.right
        anchors.leftMargin: Theme.spacing
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacing

            Group {
                // Time
                Module {
                    icon: Icons.clock
                    iconColor: Theme.mauve
                    text: Qt.formatTime(clock.date, "HH:mm")
                    tooltip: "Standard Time: " + Qt.formatTime(clock.date, "hh:mm AP")
                }

                // Date: opens the calendar modal; lavender while it's open
                Module {
                    readonly property bool active: Panels.isOpen("calendar", bar.modelData)

                    icon: Icons.calendar
                    iconColor: Theme.lavender
                    text: Qt.formatDate(clock.date, "MM-dd")
                    textColor: active ? Theme.lavender : Theme.text
                    clickable: true
                    onClicked: Panels.toggle("calendar", bar.modelData)
                }
            }

            Group {
                // System updates: opens the updates modal
                Module {
                    icon: Stats.updatesAvailable ? Icons.packagePlus : Icons.packageCheck
                    iconColor: Panels.isOpen("updates", bar.modelData) ? Theme.lavender : Stats.updatesAvailable ? Theme.peach : Theme.green
                    clickable: true
                    tooltip: Stats.updatesTooltip
                    onClicked: Panels.toggle("updates", bar.modelData)
                }
            }
    }

    // ── Right ────────────────────────────────────────────

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Theme.inset
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacing

        // Media: the playing player, else the first one
        Module {
            id: media

            readonly property var players: Mpris.players.values
            readonly property MprisPlayer player: players.find(p => p.isPlaying) ?? players[0] ?? null
            readonly property string playerId: (player?.desktopEntry || player?.identity || "").toLowerCase()

            function esc(s) {
                return (s || "").replace(/&/g, "&amp;").replace(/</g, "&lt;");
            }

            visible: player !== null && player.trackTitle !== ""
            maxWidth: 400
            clickable: true
            icon: player?.isPlaying ? Icons.play : Icons.pause
            iconColor: !player?.isPlaying ? Theme.lavender : playerId.includes("spotify") ? Theme.green : playerId.includes("firefox") ? Theme.red : playerId.includes("jellyfin") ? Theme.sapphire : Theme.lavender
            textFormat: Text.StyledText
            label.font.weight: Font.Normal
            text: player ? "<b>" + esc(player.trackTitle) + "</b>" + (player.trackArtist ? " - " + esc(player.trackArtist) : "") : ""
            tooltip: player ? [player.identity, player.trackTitle, player.trackArtist, player.trackAlbum].filter(s => s).join("\n") : ""
            onClicked: player?.togglePlaying()
            onRightClicked: player?.next()
        }

        // Idle inhibitor: the coffee cup keeps the screen awake, peach while active
        Module {
            icon: Icons.coffee
            iconColor: Stats.presentationMode ? Theme.peach : Theme.overlay1
            iconLabel.font.pixelSize: Theme.iconSize + 2
            clickable: true
            tooltip: Stats.presentationMode ? "Presentation Mode" : "Idle Mode"
            onClicked: Stats.presentationMode = !Stats.presentationMode
        }

        Group {
            // Wi-Fi: wifi-status.sh reports the waybar glyph, mapped to Lucide here
            Module {
                readonly property var glyphs: ({
                        "\u{f0928}": Icons.wifi,
                        "\u{f0925}": Icons.wifiHigh,
                        "\u{f0922}": Icons.wifiLow,
                        "\u{f091f}": Icons.wifiZero
                    })
                readonly property bool online: Stats.wifiIcon in glyphs

                icon: glyphs[Stats.wifiIcon] ?? Icons.wifiOff
                iconColor: Panels.isOpen("network", bar.modelData) ? Theme.lavender : online ? Theme.sapphire : Theme.overlay1
                clickable: true
                tooltip: Stats.wifiTooltip
                onClicked: Panels.toggle("network", bar.modelData)
                onRightClicked: bar.run("kitty --title 'Network Manager TUI' bash -c nmtui")
            }

            // VPN: green shield while connected; opens the VPN panel
            Module {
                icon: Vpn.connected ? Icons.shieldCheck : Icons.shield
                iconColor: Panels.isOpen("vpn", bar.modelData) ? Theme.lavender : Vpn.connected ? Theme.green : Theme.overlay1
                clickable: true
                tooltip: Vpn.connected ? `VPN: ${Vpn.activeConnection.name}` : "VPN: off"
                onClicked: Panels.toggle("vpn", bar.modelData)
            }

            // Bluetooth
            Module {
                readonly property var adapter: Bluetooth.defaultAdapter
                readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)

                icon: !adapter?.enabled ? Icons.bluetoothOff : connected.length ? Icons.bluetoothConnected : Icons.bluetooth
                iconColor: Panels.isOpen("bluetooth", bar.modelData) ? Theme.lavender : !adapter?.enabled ? Theme.overlay1 : Theme.blue
                clickable: true
                tooltip: !adapter?.enabled ? "Bluetooth Disabled" : [`${connected.length} connected`].concat(connected.map(d => d.batteryAvailable ? `${d.name}: ${Math.round(d.battery * 100)}%` : d.name)).join("\n")
                onClicked: Panels.toggle("bluetooth", bar.modelData)
                onRightClicked: bar.run("kitty --title 'Bluetooth TUI' bash -c bluetui")
            }
        }

        Group {
            // Volume
            Module {
                id: volume

                readonly property PwNode sink: Pipewire.defaultAudioSink
                readonly property int vol: Math.round((sink?.audio?.volume ?? 0) * 100)
                readonly property bool muted: sink?.audio?.muted ?? false
                readonly property bool headphones: /head(phone|set)/i.test(sink?.properties["device.form-factor"] ?? sink?.description ?? "")

                PwObjectTracker {
                    objects: [volume.sink]
                }

                minWidth: 76
                clickable: true
                icon: muted ? Icons.volumeX : headphones ? Icons.headphones : vol === 0 ? Icons.volume : vol < 50 ? Icons.volume1 : Icons.volume2
                iconColor: Panels.isOpen("audio", bar.modelData) ? Theme.lavender : muted ? Theme.overlay1 : Theme.mauve
                text: vol + "%"
                textColor: muted ? Theme.overlay1 : Theme.text
                tooltip: "Device: " + (sink?.description ?? "none")
                // Click: sound panel; right-click: mute; scroll: volume
                onClicked: Panels.toggle("audio", bar.modelData)
                onRightClicked: Audio.toggleMute(sink)
                onScrolled: steps => {
                    Audio.setVolume(sink, (vol + steps * 2) / 100); // via wpctl, capped at 150% like the sound panel
                }
            }

            // Battery, only on machines that have one
            Module {
                id: battery

                readonly property var dev: UPower.displayDevice
                readonly property int pct: Math.round((dev?.percentage ?? 0) * 100)
                readonly property bool charging: dev?.state === UPowerDeviceState.Charging

                function duration(s) {
                    const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60);
                    return h ? `${h}h ${m}min` : `${m}min`;
                }

                visible: dev?.isLaptopBattery ?? false
                minWidth: 76
                icon: charging ? Icons.batteryCharging : pct <= 15 ? Icons.batteryWarning : pct <= 30 ? Icons.batteryLow : pct < 70 ? Icons.batteryMedium : Icons.batteryFull
                iconColor: charging ? Theme.yellow : pct >= 100 ? Theme.green : pct <= 15 ? Theme.red : pct <= 30 ? Theme.peach : Theme.mauve
                text: pct + "%"
                tooltip: charging ? "Charging: " + duration(dev.timeToFull) : "Discharging: " + duration(dev?.timeToEmpty ?? 0)
            }
        }

        // Power menu: opens the power modal (also SUPER + Backspace)
        Module {
            icon: Icons.power
            iconColor: Panels.isOpen("power", bar.modelData) ? Theme.lavender : Theme.red
            clickable: true
            tooltip: "Power"
            onClicked: Panels.toggle("power", bar.modelData)
        }
    }
}
