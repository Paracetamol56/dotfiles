pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Data for the performance panel. Nothing runs while it's closed: when it opens (`active`),
// history and averages start fresh. CPU, cores, RAM and network are sampled every second,
// GPU and top processes every 2 s, disks every 30 s. CPU load and GPU power are also kept as
// 1-minute averages for the carbon estimate.
Singleton {
    id: root

    property bool active: false
    readonly property int historyLength: 60

    // 0..1
    property real cpu: 0
    property var cores: []
    property var cpuHistory: []
    property real ram: 0
    property var ramHistory: []
    // GB
    property real ramUsed: 0
    property real ramTotal: 0
    property real swapUsed: 0
    property real swapTotal: 0
    // bytes/s
    property real rx: 0
    property real tx: 0
    property var rxHistory: []
    property var txHistory: []
    property string load: ""

    // { name, util, memUsed, memTotal (MiB), temp, power, powerLimit (W) } or null
    property var gpu: null
    // [{ mount, size, used }] in bytes
    property var disks: []
    // [{ name, cpu, mem }] in %
    property var top: []

    // 1-minute exponential moving averages (CPU load 0..1, GPU power in W), -1 = no sample yet
    readonly property real averageWindow: 60
    property real cpuAverage: -1
    property real gpuPowerAverage: -1
    property real _lastGpuSample: 0

    property var _lastCpu: null
    property var _lastNet: null

    // Each opening starts from scratch rather than from a stale history
    onActiveChanged: {
        if (!active)
            return;
        cpuHistory = [];
        ramHistory = [];
        rxHistory = [];
        txHistory = [];
        cpuAverage = -1;
        gpuPowerAverage = -1;
        _lastGpuSample = 0;
        _lastCpu = null;
        _lastNet = null;
    }

    // Each new sample pulls the average towards it by a share that grows with the time since
    // the last one, so irregular sampling (1 s, 2 s, 15 s) still averages over ~1 minute
    function ema(average, value, seconds) {
        if (average < 0)
            return value;
        const k = 1 - Math.exp(-seconds / averageWindow);
        return average + (value - average) * k;
    }

    function push(list, v) {
        const next = list.concat([v]);
        return next.length > historyLength ? next.slice(next.length - historyLength) : next;
    }

    Timer {
        interval: 1000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            netdev.reload();
            loadavg.reload();
        }
    }

    // "cpu" and "cpuN" lines: busy share since the last sample
    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const now = {};
            for (const line of text().split("\n")) {
                if (!line.startsWith("cpu"))
                    continue;
                const f = line.trim().split(/\s+/);
                const v = f.slice(1).map(Number);
                now[f[0]] = { idle: v[3] + v[4], total: v.reduce((a, b) => a + b, 0) };
            }
            const prev = root._lastCpu;
            if (prev) {
                const usage = k => {
                    const dt = now[k].total - prev[k].total;
                    return dt > 0 ? 1 - (now[k].idle - prev[k].idle) / dt : 0;
                };
                root.cpu = usage("cpu");
                root.cores = Object.keys(now).filter(k => k !== "cpu").sort((a, b) => Number(a.slice(3)) - Number(b.slice(3))).map(usage);
                root.cpuHistory = root.push(root.cpuHistory, root.cpu);
                root.cpuAverage = root.ema(root.cpuAverage, root.cpu, 1);
            }
            root._lastCpu = now;
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const kb = key => Number(text().match(new RegExp("^" + key + ":\\s+(\\d+)", "m"))?.[1] ?? 0);
            const gb = 1048576;
            root.ramTotal = kb("MemTotal") / gb;
            root.ramUsed = (kb("MemTotal") - kb("MemAvailable")) / gb;
            root.swapTotal = kb("SwapTotal") / gb;
            root.swapUsed = (kb("SwapTotal") - kb("SwapFree")) / gb;
            root.ram = root.ramTotal > 0 ? root.ramUsed / root.ramTotal : 0;
            root.ramHistory = root.push(root.ramHistory, root.ram);
        }
    }

    // Physical interfaces only: loopback, Docker, VM bridges and veths would double-count
    FileView {
        id: netdev
        path: "/proc/net/dev"
        onLoaded: {
            let rx = 0, tx = 0;
            for (const line of text().split("\n").slice(2)) {
                const m = /^\s*([^:]+):\s*(.*)$/.exec(line);
                if (!m || /^(lo|docker|br-|veth|virbr)/.test(m[1]))
                    continue;
                const f = m[2].trim().split(/\s+/).map(Number);
                rx += f[0];
                tx += f[8];
            }
            const now = { rx, tx, t: Date.now() };
            const prev = root._lastNet;
            if (prev && now.t > prev.t) {
                const dt = (now.t - prev.t) / 1000;
                root.rx = Math.max(0, (now.rx - prev.rx) / dt);
                root.tx = Math.max(0, (now.tx - prev.tx) / dt);
                root.rxHistory = root.push(root.rxHistory, root.rx);
                root.txHistory = root.push(root.txHistory, root.tx);
            }
            root._lastNet = now;
        }
    }

    FileView {
        id: loadavg
        path: "/proc/loadavg"
        onLoaded: root.load = text().split(" ").slice(0, 3).join(" ")
    }


    Timer {
        interval: 2000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            gpuProc.running = true;
            topProc.running = true;
        }
    }

    Timer {
        interval: 30000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: dfProc.running = true
    }

    Process {
        id: gpuProc
        command: ["nvidia-smi", "--query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,power.limit", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(/,\s*/);
                const now = Date.now();
                if (f.length >= 7) {
                    root.gpuPowerAverage = root.ema(root.gpuPowerAverage, Number(f[5]), root._lastGpuSample ? (now - root._lastGpuSample) / 1000 : 1);
                    root._lastGpuSample = now;
                }
                root.gpu = f.length >= 7 ? {
                    name: f[0].replace(/^NVIDIA GeForce /, ""),
                    util: Number(f[1]) / 100,
                    memUsed: Number(f[2]),
                    memTotal: Number(f[3]),
                    temp: Number(f[4]),
                    power: Number(f[5]),
                    powerLimit: Number(f[6])
                } : null;
            }
        }
    }

    // top's second frame: CPU use over the last half second, not since each process started
    Process {
        id: topProc
        command: ["sh", "-c", "top -b -n 2 -d 0.5 -o %CPU -w 512 | awk '/^top -/{f++} f==2' | sed -n '8,12p'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.top = text.trim().split("\n").filter(l => l.trim()).map(l => {
                    const f = l.trim().split(/\s+/);
                    return { name: f.slice(11).join(" "), cpu: Number(f[8].replace(",", ".")), mem: Number(f[9].replace(",", ".")) };
                });
            }
        }
    }

    Process {
        id: dfProc
        command: ["df", "-B1", "--output=target,size,used", "-x", "tmpfs", "-x", "devtmpfs", "-x", "efivarfs", "-x", "overlay"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.disks = text.trim().split("\n").slice(1).map(l => {
                    const f = l.trim().split(/\s+/);
                    return { mount: f[0], size: Number(f[1]), used: Number(f[2]) };
                }).filter(d => d.size > 0);
            }
        }
    }
}
