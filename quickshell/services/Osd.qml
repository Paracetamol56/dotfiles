pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// On-screen feedback when the volume, mute or keyboard layout changes, from anywhere (keys,
// headset buttons, the bar, the sound panel…). Shown as a notification-style card at the
// bottom of the screen (panels/notifications/OsdPopup.qml); hides after 1.5 s.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property string device: sink?.description || sink?.nickname || "Output"

    // What to show: "volume" or "layout"
    property string kind: "volume"
    property bool shown: false
    // Changes right after startup or a device switch aren't the user's
    property bool armed: false

    function show(what) {
        if (!armed)
            return;
        kind = what;
        shown = true;
        hide.restart();
    }

    PwObjectTracker {
        objects: [root.sink].filter(n => n)
    }

    onVolumeChanged: show("volume")
    onMutedChanged: show("volume")
    onSinkChanged: {
        armed = false;
        arm.restart();
    }

    Connections {
        target: Keyboard
        function onIndexChanged() {
            root.show("layout");
        }
    }

    Timer {
        id: arm
        interval: 1500
        running: true
        onTriggered: root.armed = true
    }

    Timer {
        id: hide
        interval: 1500
        onTriggered: root.shown = false
    }
}
