pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Zen mode, Quickshell's part (Hyprland's is hypr/hyprland/zen.lua, SUPER + SHIFT + Z): black
// behind the zen window and over the other monitors (panels/zen/ZenWindow.qml), no bar, and
// Do Not Disturb, restored to what it was on the way out.
Singleton {
    id: root

    property bool active: false
    // The zen window's monitor
    property string monitor: ""
    property bool dndBefore: false

    function enter(monitorName) {
        if (active)
            return;
        Panels.close();
        monitor = monitorName;
        dndBefore = Notifications.dnd;
        if (!Notifications.dnd)
            Notifications.toggleDnd();
        active = true;
    }

    function exit() {
        if (!active)
            return;
        active = false;
        if (Notifications.dnd !== dndBefore)
            Notifications.toggleDnd();
    }

    IpcHandler {
        target: "zen"

        function enter(monitor: string): void {
            root.enter(monitor);
        }

        function exit(): void {
            root.exit();
        }
    }
}
