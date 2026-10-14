pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Night light: warms the screen with hyprsunset while enabled; stopping it restores the
// normal colours. Needs the hyprsunset package.
Singleton {
    id: root

    property bool available: false
    property bool enabled: false
    // Kelvin; lower is warmer (6500 = neutral)
    property int temperature: 4000

    function toggle() {
        if (available)
            enabled = !enabled;
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v hyprsunset"]
        onExited: code => root.available = code === 0
    }

    Process {
        running: root.available && root.enabled
        command: ["hyprsunset", "--temperature", String(root.temperature)]
    }
}
