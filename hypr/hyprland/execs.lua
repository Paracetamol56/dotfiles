-- Auto-start commands for Hyprland

hl.on("hyprland.start", function()
	hl.exec_cmd("hypridle")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("nm-applet")
	hl.exec_cmd("blueman-applet")
	hl.exec_cmd("waybar")
	hl.exec_cmd("dunst")
	hl.exec_cmd("wl-paste --type text --watch cliphist store") -- Stores only text data
	hl.exec_cmd("wl-paste --type image --watch cliphist store") -- Stores only image data
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
	hl.exec_cmd("asusctl aura static -c 390B4D")
	hl.exec_cmd("~/.config/hypr/scripts/battery_low.sh")
end)
