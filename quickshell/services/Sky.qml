pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Online data for the Weather and Astronomy widgets, fetched once for both:
//   wttr.in (location from IP): weather, forecast, coordinates, moonrise/set, cloud cover
//   NOAA SWPC: planetary Kp index (geomagnetic activity → aurora chances)
Singleton {
    id: root

    property var weather: null
    property bool weatherFailed: false
    property real kp: -1

    readonly property var area: weather?.nearest_area?.[0] ?? null
    readonly property real lat: Number(area?.latitude ?? 0)
    readonly property real lon: Number(area?.longitude ?? 0)
    readonly property bool located: area !== null
    readonly property var today: weather?.weather?.[0] ?? null
    readonly property var astronomy: today?.astronomy?.[0] ?? null

    // Average cloud cover (%) over tonight's 21:00 slot and tomorrow's 00:00 and 03:00 slots
    readonly property int nightClouds: {
        const days = weather?.weather ?? [];
        const at = (d, t) => Number(days[d]?.hourly?.find(h => h.time === t)?.cloudcover ?? NaN);
        const v = [at(0, "2100"), at(1, "0"), at(1, "300")].filter(x => !isNaN(x));
        return v.length ? Math.round(v.reduce((a, b) => a + b, 0) / v.length) : -1;
    }

    Process {
        id: wttr
        command: ["curl", "-sf", "--max-time", "10", "https://wttr.in/?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.weather = JSON.parse(text);
                    root.weatherFailed = false;
                } catch (e) {
                    root.weatherFailed = root.weather === null;
                }
            }
        }
        onExited: code => {
            if (code !== 0 && root.weather === null)
                root.weatherFailed = true;
        }
    }

    // Latest entry of NOAA's 3-hourly planetary K-index
    Process {
        id: kpFetch
        command: ["curl", "-sf", "--max-time", "10", "https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const rows = JSON.parse(text);
                    root.kp = Number(rows[rows.length - 1].Kp);
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            wttr.running = true;
            kpFetch.running = true;
        }
    }
}
