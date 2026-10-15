pragma Singleton

import QtQuick
import Quickshell

// Audio changes go through wpctl, the same tool the volume keys use. Quickshell's own
// volume writes can get stuck on devices with hardware routes (like the USB card): they
// silently stop applying, and from then on Quickshell reports the value it tried to set
// instead of the real one. Reading through Quickshell stays accurate when it never writes.
Singleton {
    id: root

    // Latest requested volume per node id, sent in one batch so drags don't spawn a process per pixel
    property var pending: ({})

    function setVolume(node, volume) {
        if (!node)
            return;
        pending[node.id] = Math.max(0, Math.min(1.5, volume));
        if (!flush.running)
            flush.start();
    }

    function toggleMute(node) {
        if (node)
            Quickshell.execDetached(["wpctl", "set-mute", String(node.id), "toggle"]);
    }

    function setDefault(node) {
        if (node)
            Quickshell.execDetached(["wpctl", "set-default", String(node.id)]);
    }

    Timer {
        id: flush
        interval: 40
        onTriggered: {
            for (const id in root.pending)
                Quickshell.execDetached(["wpctl", "set-volume", id, root.pending[id].toFixed(2)]);
            root.pending = {};
        }
    }
}
