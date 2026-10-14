pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Which modal is open (one at a time) and on which screen, shared by the bar and the modals
Singleton {
    id: root

    // Name of the open modal ("dashboard", "calendar", "updates", "power", "network", "bluetooth", "audio", "launcher", "performance"), or "" when none is
    property string current: ""
    property var screen: null

    function isOpen(name, s) {
        return current === name && screen === s;
    }

    function toggle(name, s) {
        if (isOpen(name, s))
            return close();
        current = name;
        screen = s;
    }

    function close() {
        current = "";
        screen = null;
    }

    // For keybinds: closes the modal wherever it's open, otherwise opens it on the focused monitor
    function toggleFocused(name) {
        if (current === name)
            return close();
        const monitor = Hyprland.focusedMonitor?.name;
        toggle(name, Quickshell.screens.find(s => s.name === monitor) ?? Quickshell.screens[0]);
    }

    // `qs ipc call dashboard|calendar|updates|power|network|bluetooth|audio|launcher|performance toggle`
    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            root.toggleFocused("dashboard");
        }
    }

    IpcHandler {
        target: "calendar"

        function toggle(): void {
            root.toggleFocused("calendar");
        }
    }

    IpcHandler {
        target: "updates"

        function toggle(): void {
            root.toggleFocused("updates");
        }
    }

    IpcHandler {
        target: "power"

        function toggle(): void {
            root.toggleFocused("power");
        }
    }

    IpcHandler {
        target: "network"

        function toggle(): void {
            root.toggleFocused("network");
        }
    }

    IpcHandler {
        target: "bluetooth"

        function toggle(): void {
            root.toggleFocused("bluetooth");
        }
    }

    IpcHandler {
        target: "audio"

        function toggle(): void {
            root.toggleFocused("audio");
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggleFocused("launcher");
        }
    }

    IpcHandler {
        target: "performance"

        function toggle(): void {
            root.toggleFocused("performance");
        }
    }
}
