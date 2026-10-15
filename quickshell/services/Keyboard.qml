pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Keyboard layout: AZERTY (fr) or QWERTY (us), the two layouts set in hypr/hyprland/input.lua.
// Follows Hyprland's layout-change events, so it stays right however the layout is switched.
Singleton {
    id: root

    // Same order as kb_layout = "fr,us"
    readonly property var layouts: [{ code: "FR", name: "AZERTY (French)" }, { code: "US", name: "QWERTY (US)" }]
    property int index: 0
    readonly property var current: layouts[index] ?? layouts[0]

    function toggle() {
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"]);
    }

    function refresh() {
        query.running = true;
    }

    Component.onCompleted: refresh()

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout")
                root.refresh();
        }
    }

    // The main keyboard's active layout index
    Process {
        id: query
        command: ["sh", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main) | .active_layout_index'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const i = Number(text.trim());
                if (!isNaN(i))
                    root.index = i;
            }
        }
    }
}
