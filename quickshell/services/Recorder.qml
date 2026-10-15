pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// Screen recording state, shared so it survives the dashboard closing
// (and so the bar can show it). Runs scripts/record.sh, stopped with SIGINT.
Singleton {
    id: root

    property bool available: false
    readonly property bool recording: proc.running
    property int elapsed: 0

    function start() {
        if (!available || proc.running)
            return;
        elapsed = 0;
        // Give the dashboard time to close before slurp asks for an area
        proc.command = ["sh", "-c", `sleep 0.35; exec "${Theme.scripts}/record.sh"`];
        proc.running = true;
    }

    function stop() {
        proc.signal(2); // SIGINT: record.sh tells wf-recorder to finish the file
    }

    function toggle() {
        recording ? stop() : start();
    }

    // wf-recorder isn't installed by default
    Process {
        running: true
        command: ["sh", "-c", "command -v wf-recorder"]
        onExited: code => root.available = code === 0
    }

    Process {
        id: proc
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.elapsed++
    }
}
