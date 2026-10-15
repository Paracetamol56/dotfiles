-- Auto-start commands for Hyprland

hl.on("hyprland.start", function()
	hl.exec_cmd("hypridle")
	hl.exec_cmd("nm-applet")
	hl.exec_cmd("blueman-applet")
	hl.exec_cmd("qs")
	hl.exec_cmd("wl-paste --type text --watch cliphist store") -- Stores only text data
	hl.exec_cmd("wl-paste --type image --watch cliphist store") -- Stores only image data
	hl.exec_cmd("python3 ~/.config/theme/apply.py --rgb") -- RGB lighting in the theme accent (OpenRGB)
	hl.exec_cmd("~/.config/hypr/scripts/battery_low.sh")
end)
