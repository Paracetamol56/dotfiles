pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The desktop wallpaper (replaces hyprpaper): one image for every screen, remembered across
// restarts. Change it with `qs ipc call wallpaper set /path/to/image`.
Singleton {
    id: root

    readonly property string fallback: Quickshell.env("HOME") + "/Pictures/Wallpapers/walls-catppuccin-mocha/train-sideview.png"
    property string path: fallback

    function set(newPath) {
        path = newPath;
        state.setText(JSON.stringify({ path: newPath }));
    }

    FileView {
        id: state
        path: Quickshell.statePath("wallpaper.json")
        printErrors: false
        onLoaded: {
            try {
                const p = JSON.parse(text()).path;
                if (p)
                    root.path = p;
            } catch (e) {}
        }
    }

    IpcHandler {
        target: "wallpaper"

        function set(path: string): void {
            root.set(path);
        }

        function get(): string {
            return root.path;
        }
    }
}
