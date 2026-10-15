import QtQuick
import Quickshell.Hyprland
import qs.common

// Active window title, rewritten with the same rules as waybar's hyprland/window.
// Lucide has no brand logos, so each app gets the closest generic icon.
Module {
    id: root

    required property HyprlandMonitor monitor

    // [pattern (full match), icon, icon colour, replacement ($1… = groups)]
    // First match wins, so specific rules come before their catch-alls.
    readonly property var rules: [
        [/^$/, Icons.layoutGrid, Theme.blue, "Hyprland"],
        // Terminal
        [/^(~|zsh|kitty)$/, Icons.terminal, Theme.text, "Terminal"],
        // Browser
        [/^(.*) — Mozilla Firefox$/, Icons.globe, Theme.red, "$1"],
        [/^(.*)Mozilla Firefox$/, Icons.globe, Theme.red, "Firefox"],
        [/^(.*) — Zen Browser$/, Icons.globe, Theme.text, "$1"],
        [/^(.*)Zen Browser$/, Icons.globe, Theme.text, "Zen Browser"],
        // Development
        [/^(.*) - Visual Studio Code$/, Icons.code, Theme.blue, "$1"],
        [/^(.*)Visual Studio Code$/, Icons.code, Theme.blue, "Visual Studio Code"],
        [/^nvim (.*)$/, Icons.codeXml, Theme.green, "Neovim"],
        [/^Godot Engine - (.*)$/, Icons.gamepad2, Theme.blue, "$1"],
        [/^(.*) - Godot Engine$/, Icons.gamepad2, Theme.blue, "$1"],
        [/^Godot$/, Icons.gamepad2, Theme.blue, "Godot Engine"],
        // Media
        [/^(.*)Spotify Premium$/, Icons.music, Theme.green, "Spotify Premium"],
        [/^(.*)Spotify$/, Icons.music, Theme.green, "Spotify"],
        [/^OBS(.*)$/, Icons.video, Theme.subtext0, "OBS Studio"],
        [/^(.*) - VLC media player$/, Icons.clapperboard, Theme.peach, "$1"],
        [/^VLC media player$/, Icons.clapperboard, Theme.peach, "VLC Media Player"],
        [/^GNU Image Manipulation Program$/, Icons.palette, Theme.subtext0, "GNU Image Manipulation Program"],
        [/^qView$/, Icons.image, Theme.text, "qView"],
        [/^(.*)\.(jpg|png|svg)$/, Icons.image, Theme.text, "$1.$2"],
        // Social
        [/^vesktop$/, Icons.messageCircle, Theme.blue, "Discord"],
        [/^• Discord(.*)$/, Icons.messageCircle, Theme.blue, "Discord$1"],
        [/^(.*)Discord(.*)$/, Icons.messageCircle, Theme.blue, "$1Discord$2"],
        // Documents
        [/^ONLYOFFICE Desktop Editors$/, Icons.fileText, Theme.red, "OnlyOffice Desktop"],
        [/^(.*)\.docx$/, Icons.fileText, Theme.blue, "$1.docx"],
        [/^(.*)\.xlsx$/, Icons.fileSpreadsheet, Theme.green, "$1.xlsx"],
        [/^(.*)\.pptx$/, Icons.presentation, Theme.peach, "$1.pptx"],
        [/^(.*)\.pdf$/, Icons.fileText, Theme.red, "$1.pdf"],
        [/^\/.*$/, Icons.folder, Theme.yellow, "File Manager"],
        // System
        [/^Timeshift-gtk$/, Icons.history, Theme.green, "Timeshift"],
        [/^Authenticate$/, Icons.shieldCheck, Theme.text, "Authenticate"]
    ]

    // Only show the focused window if it's on this bar's monitor
    readonly property string title: {
        const t = Hyprland.activeToplevel;
        return t && t.workspace && monitor && t.workspace === monitor.activeWorkspace ? t.title : "";
    }

    readonly property var match: {
        for (const [re, icon, color, repl] of rules) {
            if (re.test(title))
                return { icon, color, text: title.replace(re, repl) };
        }
        return { icon: Icons.appWindow, color: Theme.subtext0, text: title };
    }

    icon: match.icon
    iconColor: match.color
    text: match.text
    maxWidth: 400
}
