pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// System data shared by every bar, so two monitors don't poll twice
Singleton {
    id: root

    // CPU
    property int cpuUsage: 0
    property string cpuModel: ""
    property int cpuTemp: 0
    property string cpuFreq: ""
    property var _lastCpu: null

    // Memory (GB)
    property real memUsed: 0
    property real memTotal: 0
    readonly property int memPercent: memTotal > 0 ? Math.round(memUsed / memTotal * 100) : 0

    // Wi-Fi, from the script carried over from waybar
    property string wifiIcon: "\u{f092e}"
    property string wifiTooltip: ""

    // Pending updates: [{ name, from, to, aur }]
    property var updateList: []
    readonly property bool checkingUpdates: updates.running
    property date updatesCheckedAt
    readonly property bool updatesAvailable: updateList.length > 0
    readonly property int aurUpdates: updateList.filter(u => u.aur).length
    readonly property string updatesTooltip: updatesAvailable ? `${updateList.length} update${updateList.length > 1 ? "s" : ""} available` : "Packages are up to date"

    // Idle inhibitor toggle ("presentation mode")
    property bool presentationMode: false

    function checkUpdates() {
        if (!updates.running)
            updates.running = true;
    }

    function runUpgrade() {
        upgrade.running = true;
    }

    // ── CPU + memory, every 5 s like waybar ──────────────

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            cpuinfo.reload();
            temp.running = true;
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4];
            const total = f.reduce((a, b) => a + b, 0);
            if (root._lastCpu) {
                const dt = total - root._lastCpu.total;
                if (dt > 0)
                    root.cpuUsage = Math.round(100 * (1 - (idle - root._lastCpu.idle) / dt));
            }
            root._lastCpu = { idle, total };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const kb = key => Number(text().match(new RegExp("^" + key + ":\\s+(\\d+)", "m"))[1]);
            const total = kb("MemTotal");
            root.memTotal = total / 1048576;
            root.memUsed = (total - kb("MemAvailable")) / 1048576;
        }
    }

    FileView {
        id: cpuinfo
        path: "/proc/cpuinfo"
        onLoaded: {
            const t = text();
            const mhz = (t.match(/^cpu MHz\s*:\s*[\d.]+/gm) || []).map(l => Number(l.split(":")[1]));
            const avg = mhz.length ? Math.round(mhz.reduce((a, b) => a + b, 0) / mhz.length) : 0;
            root.cpuFreq = avg + "/" + maxFreq.mhz + " MHz";
            if (!root.cpuModel) {
                const m = t.match(/^model name\s*:\s*(.*)$/m);
                if (m)
                    root.cpuModel = m[1].replace(/@.*/, "").replace(/\s*\((R|TM)\)/g, "").trim();
            }
        }
    }

    FileView {
        id: maxFreq
        readonly property int mhz: loaded ? Math.round(Number(text()) / 1000) : 0
        path: "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq"
    }

    // Package temperature from the coretemp hwmon (its index can change between boots)
    Process {
        id: temp
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do [ \"$(cat $h/name)\" = coretemp ] && cat $h/temp1_input && break; done"]
        stdout: StdioCollector {
            onStreamFinished: root.cpuTemp = Math.round(Number(text) / 1000)
        }
    }

    // ── Wi-Fi ─────────────────────────────────────────────

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: wifi.running = true
    }

    Process {
        id: wifi
        command: [Theme.scripts + "/wifi-status.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    root.wifiIcon = j.text;
                    root.wifiTooltip = j.tooltip;
                } catch (e) {}
            }
        }
    }

    // ── Updates: checkupdates is slow, so every 10 min ──

    Timer {
        interval: 600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.checkUpdates()
    }

    // Repo updates from checkupdates, AUR ones from paru, tagged; lines are "name old -> new"
    Process {
        id: updates
        command: ["sh", "-c", "checkupdates 2>/dev/null; paru -Qua 2>/dev/null | sed 's/$/ aur/'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.updateList = text.split("\n").map(l => /^(\S+) (\S+) -> (\S+)( aur)?$/.exec(l.trim())).filter(m => m).map(m => ({
                            name: m[1],
                            from: m[2],
                            to: m[3],
                            aur: !!m[4]
                        }));
                root.updatesCheckedAt = new Date();
            }
        }
    }

    // Opens a kitty window running the upgrade, then re-checks once it's closed
    Process {
        id: upgrade
        command: [Theme.scripts + "/system-update.sh", "up"]
        onExited: root.checkUpdates()
    }
}
