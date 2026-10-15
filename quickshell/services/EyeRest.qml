pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Eye-rest reminder: every 30 minutes of unlocked time, panels/eyerest/EyeRestWindow.qml
// covers the screens with a blurred overlay asking for a 20-second break (the 20-20-20
// rule). A click anywhere dismisses it. Locking counts as a break: the timer pauses while
// locked and starts over after unlocking.
// On/off from the dashboard (remembered across restarts).
//   qs ipc call eyerest show      show it now (to try it)
//   qs ipc call eyerest toggle    turn the reminders on/off
Singleton {
    id: root

    property bool enabled: true
    property int intervalMinutes: 30
    // How long the break lasts, for the countdown
    readonly property int breakSeconds: 20
    property bool shown: false
    property real shownAt: 0

    function toggle() {
        enabled = !enabled;
        state.setText(JSON.stringify({ enabled }));
    }

    function show() {
        shownAt = Date.now();
        shown = true;
    }

    // Clicks in the first second don't count: one that was already on its way when the
    // overlay appeared shouldn't dismiss it
    function dismiss() {
        if (Date.now() - shownAt < 1000)
            return;
        shown = false;
    }

    // Stops while locked or shown; starting again restarts it from zero
    Timer {
        interval: root.intervalMinutes * 60 * 1000
        running: root.enabled && !Lock.locked && !root.shown
        onTriggered: root.show()
    }

    FileView {
        id: state
        path: Quickshell.statePath("eyerest.json")
        printErrors: false
        onLoaded: {
            try {
                root.enabled = JSON.parse(text()).enabled !== false;
            } catch (e) {}
        }
    }

    IpcHandler {
        target: "eyerest"

        function toggle(): void {
            root.toggle();
        }

        function show(): void {
            root.show();
        }
    }
}
