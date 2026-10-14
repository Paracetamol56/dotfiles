pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Grid carbon intensity and fossil share at your location, from Electricity Maps.
// Needs a (free) API token in ~/.config/quickshell/secrets/electricitymaps-token, which
// is git-ignored. Fetched when the performance panel opens, at most every 15 minutes.
// Uses the /home-assistant endpoint: the free tier only grants that one (the
// carbon-intensity and power-breakdown endpoints answer 401 for every zone).
Singleton {
    id: root

    readonly property string token: (tokenFile.loaded ? tokenFile.text() : "").trim()
    readonly property bool configured: token !== ""

    // gCO₂eq/kWh, the zone it's for, and when Electricity Maps measured it
    property real intensity: -1
    property string zone: ""
    property date measuredAt
    // % of the grid's power from fossil-free sources (renewables aren't in the free tier)
    property real renewable: -1
    property real fossilFree: -1
    property string error: ""
    property real lastFetch: 0

    function refresh() {
        if (!configured || !Sky.located || Date.now() - lastFetch < 15 * 60 * 1000)
            return;
        lastFetch = Date.now();
        // No -f: on errors the body holds Electricity Maps' explanation, shown in the panel
        request.command = ["curl", "-s", "--max-time", "10", "-H", `auth-token: ${token}`, `https://api.electricitymap.org/v3/home-assistant?lat=${Sky.lat}&lon=${Sky.lon}`];
        request.running = true;
    }

    FileView {
        id: tokenFile
        path: Quickshell.shellPath("secrets/electricitymaps-token")
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
    }

    // { status: "ok", countryCode, data: { datetime, carbonIntensity, fossilFuelPercentage } }
    Process {
        id: request
        stdout: StdioCollector {
            onStreamFinished: {
                let j = null;
                try {
                    j = JSON.parse(text);
                } catch (e) {}
                if (j?.status === "ok" && j.data) {
                    root.intensity = j.data.carbonIntensity;
                    root.zone = j.countryCode ?? "";
                    root.measuredAt = new Date(j.data.datetime);
                    root.fossilFree = j.data.fossilFuelPercentage !== undefined ? 100 - j.data.fossilFuelPercentage : -1;
                    root.error = "";
                } else {
                    root.error = "Electricity Maps: " + (j?.message ?? j?.error ?? "no response");
                    root.lastFetch = 0; // retry next time the panel opens
                }
            }
        }
    }
}
