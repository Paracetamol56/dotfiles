pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Catppuccin colours from ~/.config/theme (the same source as Hyprland, kitty, starship…):
// catppuccin.json has every flavor, theme.json picks the flavor and accent. Editing
// theme.json (or running theme/apply.py) recolours the shell live. The fallbacks are Mocha.
Singleton {
    id: root

    readonly property string themeDir: Quickshell.env("HOME") + "/.config/theme"
    property var palettes: ({})
    property var choice: ({ flavor: "mocha", accent: "mauve" })
    readonly property var palette: palettes[choice.flavor] ?? ({})

    FileView {
        path: root.themeDir + "/catppuccin.json"
        onLoaded: {
            try {
                root.palettes = JSON.parse(text());
            } catch (e) {}
        }
    }

    FileView {
        path: root.themeDir + "/theme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.choice = JSON.parse(text());
            } catch (e) {}
        }
    }

    readonly property color rosewater: palette.rosewater ?? "#f5e0dc"
    readonly property color flamingo: palette.flamingo ?? "#f2cdcd"
    readonly property color pink: palette.pink ?? "#f5c2e7"
    readonly property color mauve: palette.mauve ?? "#cba6f7"
    readonly property color red: palette.red ?? "#f38ba8"
    readonly property color maroon: palette.maroon ?? "#eba0ac"
    readonly property color peach: palette.peach ?? "#fab387"
    readonly property color yellow: palette.yellow ?? "#f9e2af"
    readonly property color green: palette.green ?? "#a6e3a1"
    readonly property color teal: palette.teal ?? "#94e2d5"
    readonly property color sky: palette.sky ?? "#89dceb"
    readonly property color sapphire: palette.sapphire ?? "#74c7ec"
    readonly property color blue: palette.blue ?? "#89b4fa"
    readonly property color lavender: palette.lavender ?? "#b4befe"
    readonly property color text: palette.text ?? "#cdd6f4"
    readonly property color subtext1: palette.subtext1 ?? "#bac2de"
    readonly property color subtext0: palette.subtext0 ?? "#a6adc8"
    readonly property color overlay2: palette.overlay2 ?? "#9399b2"
    readonly property color overlay1: palette.overlay1 ?? "#7f849c"
    readonly property color overlay0: palette.overlay0 ?? "#6c7086"
    readonly property color surface2: palette.surface2 ?? "#585b70"
    readonly property color surface1: palette.surface1 ?? "#45475a"
    readonly property color surface0: palette.surface0 ?? "#313244"
    readonly property color base: palette.base ?? "#1e1e2e"
    readonly property color mantle: palette.mantle ?? "#181825"
    readonly property color crust: palette.crust ?? "#11111b"

    // The accent picked in theme.json (mauve by default)
    readonly property color accent: palette[choice.accent] ?? mauve
    readonly property color transparentBase: Qt.rgba(base.r, base.g, base.b, 0.9)

    readonly property string fontFamily: "FiraCode Nerd Font"
    readonly property int fontSize: 12
    readonly property int iconSize: 15
    // Corner radius shared by the bar and the windows it opens
    readonly property int radius: 6
    readonly property int barHeight: 32
    readonly property int padding: 8
    // Gap between pills, and between the bar edge and the outer pills
    readonly property int spacing: 8
    // Pills sit 5px inside the bar on every side
    readonly property int inset: 6
    readonly property int pillHeight: barHeight - inset * 2
    readonly property int animDuration: 180

    readonly property string scripts: Quickshell.shellDir + "/scripts"
}
