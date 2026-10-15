pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Night light: warms the screen with hyprsunset while enabled; stopping it restores the
// normal colours. Needs the hyprsunset package.
//
// hyprsunset runs detached, not as a child of the shell: it survives Quickshell restarts, and
// the state is read from whether it's running (on start and after each toggle), so the button
// can't get out of sync with the screen.
Singleton {
    id: root

    property bool available: false
    property bool enabled: false
    // Kelvin; lower is warmer (6500 = neutral)
    property int temperature: 4000

    function toggle() {
        if (!available)
            return;
        enabled = !enabled;
        // Stop any running one first: only one hyprsunset can drive the screen
        Quickshell.execDetached(["sh", "-c", enabled
            ? `pkill -x hyprsunset; sleep 0.2; exec setsid hyprsunset --temperature ${temperature}`
            : "pkill -x hyprsunset"]);
        recheck.restart();
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v hyprsunset"]
        onExited: code => root.available = code === 0
    }

    // Is a hyprsunset running? (e.g. left on before a restart)
    Process {
        id: check
        running: true
        command: ["pgrep", "-x", "hyprsunset"]
        onExited: code => root.enabled = code === 0
    }

    // Confirms the state once the toggle has taken effect
    Timer {
        id: recheck
        interval: 1000
        onTriggered: check.running = true
    }
}
