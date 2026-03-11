import QtQuick
import Quickshell.Io

QtObject {
    id: root

    // ── Exposed state ────────────────────────────────────────────────
    property string timeStr:       "--:--"
    property string dateStr:       "--- --"
    property string cpuTemp:       "--°C"
    property string cpuUsage:      "--%"
    property string ramUsage:      "--%"
    property string volPercent:    "0%"
    property string volIcon:       "󰕿"
    property bool   isMuted:       false
    property string brightPercent: "0%"
    property string batPercent:    "0%"
    property string batIcon:       "󰁼"
    property bool   isCharging:    false
    property string wifiIcon:      "󰤭"
    property bool   isWifiOn:      false
    property string btIcon:        "󰂲"
    property bool   isBtOn:        false
    property string btDevice:      ""
    property string updateCount:   "0"
    property bool   idleInhibited: false
    property string windowTitle:   ""
    property var    workspaces:    []
    property int    activeWs:      1
    property var    musicData: ({
        status: "Stopped", title: "", artist: "", artUrl: ""
    })

    // ── Clock ────────────────────────────────────────────────────────
    property var _clock: Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            let d       = new Date()
            root.timeStr = Qt.formatDateTime(d, "HH:mm")
            root.dateStr = Qt.formatDateTime(d, "ddd dd")
        }
    }

    // ── CPU temp ─────────────────────────────────────────────────────
    property var _cpuTempProc: Process {
        id: cpuTempProc
        command: ["bash", "-c",
            "temp=$(cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -1); " +
            "[ -n \"$temp\" ] && echo \"$(( temp / 1000 ))°C\" || " +
            "sensors 2>/dev/null | awk '/^Core 0/{gsub(/[+°C]/,\"\",$3); printf \"%.0f°C\\n\",$3; exit}'"
        ]
        stdout: StdioCollector {
            onStreamFinished: { let v = text.trim(); if (v) root.cpuTemp = v }
        }
    }
    property var _cpuTempTimer: Timer {
        interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: cpuTempProc.running = true
    }

    // ── CPU usage ────────────────────────────────────────────────────
    property var _cpuUsageProc: Process {
        id: cpuUsageProc
        command: ["bash", "-c",
            "read cpu a b c idle _ < /proc/stat; sleep 0.4; " +
            "read cpu a2 b2 c2 idle2 _ < /proc/stat; " +
            "total=$(( (a2+b2+c2+idle2)-(a+b+c+idle) )); " +
            "used=$(( (a2+b2+c2)-(a+b+c) )); " +
            "echo \"$(( used*100/total ))%\""
        ]
        stdout: StdioCollector {
            onStreamFinished: { let v = text.trim(); if (v) root.cpuUsage = v }
        }
    }
    property var _cpuUsageTimer: Timer {
        interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: cpuUsageProc.running = true
    }

    // ── RAM ──────────────────────────────────────────────────────────
    property var _ramProc: Process {
        id: ramProc
        command: ["bash", "-c", "free | awk '/^Mem:/{printf \"%.0f%%\", $3/$2*100}'"]
        stdout: StdioCollector {
            onStreamFinished: { let v = text.trim(); if (v) root.ramUsage = v }
        }
    }
    property var _ramTimer: Timer {
        interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: ramProc.running = true
    }

    // ── Volume ───────────────────────────────────────────────────────
    property var _volProc: Process {
        id: volProc
        command: ["bash", "-c",
            "vol=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}' | head -1 | tr -d '%'); " +
            "muted=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}'); " +
            "echo \"$vol\"; echo \"$muted\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines       = text.trim().split("\n")
                let vol         = parseInt(lines[0]) || 0
                root.volPercent = vol + "%"
                root.volIcon    = vol === 0 ? "󰕿" : vol < 50 ? "󰖀" : "󰕾"
                root.isMuted    = lines[1]?.trim() === "yes"
            }
        }
    }
    property var _volTimer: Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: volProc.running = true
    }

    // ── Brightness ───────────────────────────────────────────────────
    property var _brightProc: Process {
        id: brightProc
        command: ["bash", "-c",
            "cur=$(brightnessctl g 2>/dev/null); max=$(brightnessctl m 2>/dev/null); " +
            "[ -n \"$cur\" ] && echo \"$(( cur*100/max ))%\" || echo '--'"
        ]
        stdout: StdioCollector {
            onStreamFinished: { let v = text.trim(); if (v) root.brightPercent = v }
        }
    }
    property var _brightTimer: Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: brightProc.running = true
    }

    // ── Battery ──────────────────────────────────────────────────────
    property var _batProc: Process {
        id: batProc
        command: ["bash", "-c",
            "cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1); " +
            "status=$(cat /sys/class/power_supply/BAT*/status   2>/dev/null | head -1); " +
            "echo \"${cap:-0}\"; echo \"${status:-Unknown}\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines      = text.trim().split("\n")
                let cap        = parseInt(lines[0]) || 0
                let st         = lines[1]?.trim() ?? "Unknown"
                root.batPercent = cap + "%"
                root.isCharging = st === "Charging"
                let icons = ["󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂"]
                root.batIcon = st === "Full"     ? "󱃌"
                             : st === "Charging" ? "󱘖"
                             : cap <= 15         ? "󱃍"
                             : cap <= 30         ? "󰁻"
                             : icons[Math.min(Math.floor(cap / 15), icons.length - 1)]
            }
        }
    }
    property var _batTimer: Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: batProc.running = true
    }

    // ── Wi-Fi ────────────────────────────────────────────────────────
    property var _wifiProc: Process {
        id: wifiProc
        command: ["bash", "-c",
            "ssid=$(iwgetid -r 2>/dev/null); " +
            "sig=$(awk 'NR==3{print int($3)}' /proc/net/wireless 2>/dev/null || echo 0); " +
            "echo \"${ssid:-}\"; echo \"$sig\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines    = text.trim().split("\n")
                root.isWifiOn = lines[0].trim() !== ""
                let sig      = parseInt(lines[1]) || 0
                root.wifiIcon = !root.isWifiOn ? "󰤭"
                              : sig > 60       ? "󰤨"
                              : sig > 40       ? "󰤥"
                              : sig > 20       ? "󰤢"
                              :                  "󰤟"
            }
        }
    }
    property var _wifiTimer: Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: wifiProc.running = true
    }

    // ── Bluetooth ────────────────────────────────────────────────────
    property var _btProc: Process {
        id: btProc
        command: ["bash", "-c",
            "powered=$(bluetoothctl show 2>/dev/null | awk '/Powered/{print $2}'); " +
            "device=$(bluetoothctl info 2>/dev/null | awk '/Name/{$1=\"\"; print substr($0,2); exit}'); " +
            "echo \"${powered:-no}\"; echo \"${device:-}\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines    = text.trim().split("\n")
                root.isBtOn  = lines[0].trim() === "yes"
                root.btDevice = lines[1]?.trim() ?? ""
                root.btIcon  = !root.isBtOn         ? "󰂲"
                             : root.btDevice !== ""  ? "󰂱"
                             :                        "󰂯"
            }
        }
    }
    property var _btTimer: Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: btProc.running = true
    }

    // ── Workspaces ───────────────────────────────────────────────────
    property var _wsProc: Process {
        id: wsProc
        command: ["bash", "-c",
            "hyprctl workspaces -j 2>/dev/null | " +
            "python3 -c \"import sys,json; ws=json.load(sys.stdin); " +
            "print(','.join(map(str,sorted([w['id'] for w in ws]))))\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let v = text.trim()
                if (v) root.workspaces = v.split(",").map(s => parseInt(s)).filter(n => !isNaN(n))
            }
        }
    }
    property var _activeWsProc: Process {
        id: activeWsProc
        command: ["bash", "-c",
            "hyprctl activeworkspace -j 2>/dev/null | " +
            "python3 -c \"import sys,json; d=json.load(sys.stdin); print(d.get('id',1))\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let v = parseInt(text.trim())
                if (!isNaN(v)) root.activeWs = v
            }
        }
    }
    property var _wsTimer: Timer {
        interval: 400; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { wsProc.running = true; activeWsProc.running = true }
    }

    // ── Window title ─────────────────────────────────────────────────
    property var _winProc: Process {
        id: winProc
        command: ["bash", "-c",
            "hyprctl activewindow -j 2>/dev/null | " +
            "python3 -c \"import sys,json\ntry:\n d=json.load(sys.stdin)\n print(d.get('title',''))\nexcept: print('')\""
        ]
        stdout: StdioCollector {
            onStreamFinished: { root.windowTitle = text.trim() }
        }
    }
    property var _winTimer: Timer {
        interval: 600; running: true; repeat: true; triggeredOnStart: true
        onTriggered: winProc.running = true
    }

    // ── Media ────────────────────────────────────────────────────────
    property var _mediaProc: Process {
        id: mediaProc
        command: ["bash", "-c",
            "status=$(playerctl status 2>/dev/null  || echo Stopped); " +
            "title=$(playerctl  metadata title  2>/dev/null || echo ''); " +
            "artist=$(playerctl metadata artist 2>/dev/null || echo ''); " +
            "arturl=$(playerctl metadata mpris:artUrl 2>/dev/null || echo ''); " +
            "echo \"$status\"; echo \"$title\"; echo \"$artist\"; echo \"$arturl\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let l = text.split("\n")
                root.musicData = {
                    status: l[0]?.trim() || "Stopped",
                    title:  l[1]?.trim() || "",
                    artist: l[2]?.trim() || "",
                    artUrl: l[3]?.trim() || ""
                }
            }
        }
    }
    property var _mediaTimer: Timer {
        interval: 1500; running: true; repeat: true; triggeredOnStart: true
        onTriggered: mediaProc.running = true
    }

    // ── Updates ──────────────────────────────────────────────────────
    property var _updateProc: Process {
        id: updateProc
        command: ["bash", "-c", "checkupdates 2>/dev/null | wc -l || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: { let v = text.trim(); root.updateCount = v || "0" }
        }
    }
    property var _updateTimer: Timer {
        interval: 60000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: updateProc.running = true
    }
}
