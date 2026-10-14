pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Which popups are open, shared by the bar and the windows it opens
Singleton {
    // Screen the dashboard is open on, or null when closed
    property var dashboardScreen: null

    function toggleDashboard(screen) {
        dashboardScreen = dashboardScreen === screen ? null : screen;
    }

    function closeDashboard() {
        dashboardScreen = null;
    }

    // `qs ipc call dashboard toggle`, e.g. from a Hyprland keybind: closes it wherever
    // it's open, otherwise opens it on the focused monitor
    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            if (dashboardScreen !== null)
                return closeDashboard();
            const name = Hyprland.focusedMonitor?.name;
            const screen = Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0];
            toggleDashboard(screen);
        }
    }
}
