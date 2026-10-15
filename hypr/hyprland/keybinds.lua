-- Keybindings for Hyprland

-- --- Apps --- #
hl.bind("SUPER + Z", hl.dsp.exec_cmd("zen-browser"))
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("thunar"))
hl.bind("SUPER + O", hl.dsp.exec_cmd("obsidian"))

-- --- Quickshell panels --- #
hl.bind("SUPER + R", hl.dsp.exec_cmd("qs ipc call launcher toggle")) -- Quickshell app launcher
hl.bind("SUPER + V", hl.dsp.exec_cmd("qs ipc call clipboard toggle")) -- Quickshell clipboard history
hl.bind("SUPER + N", hl.dsp.exec_cmd("qs ipc call network toggle")) -- Quickshell Wi-Fi panel
hl.bind("SUPER + B", hl.dsp.exec_cmd("qs ipc call bluetooth toggle")) -- Quickshell Bluetooth panel
hl.bind("SUPER + S", hl.dsp.exec_cmd("qs ipc call emoji toggle")) -- Quickshell emoji picker
hl.bind("SUPER + A", hl.dsp.exec_cmd("qs ipc call audio toggle")) -- Quickshell sound panel
hl.bind("SUPER + Backspace", hl.dsp.exec_cmd("qs ipc call power toggle")) -- Quickshell power menu
hl.bind("SUPER + Tab", hl.dsp.exec_cmd("qs ipc call overview toggle")) -- Quickshell window overview

-- --- Hyprland --- #
hl.bind("SUPER + SHIFT + X", hl.dsp.window.close()) -- was killactive
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ action = "toggle" })) -- was fullscreen
hl.bind("SUPER + P", hl.dsp.window.float({ action = "toggle" })) -- was togglefloating

-- --- Screenshots --- #
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/screenshot.sh full"))
hl.bind("PRINT", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/screenshot.sh area"))

-- --- Color picker --- #
hl.bind("SUPER + I", hl.dsp.exec_cmd("hyprpicker -a"))

-- --- Move/Focus --- #
-- Move / focus windows: arrow keys or vim keys (H J K L)
local directions = {
	{ dir = "left", keys = { "left", "H" } },
	{ dir = "down", keys = { "down", "J" } },
	{ dir = "up", keys = { "up", "K" } },
	{ dir = "right", keys = { "right", "L" } },
}
for _, d in ipairs(directions) do
	for _, key in ipairs(d.keys) do
		hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ direction = d.dir }))
		hl.bind("SUPER + " .. key, hl.dsp.focus({ direction = d.dir }))
	end
end

-- Workspace binds for French keyboard layout
local workspace_keys = {
	"ampersand", -- 1
	"eacute", -- 2
	"quotedbl", -- 3
	"apostrophe", -- 4
	"parenleft", -- 5
	"minus", -- 6
	"egrave", -- 7
	"underscore", -- 8
	"ccedilla", -- 9
	"agrave", -- 10
}

for i = 1, 10 do
	local key = workspace_keys[i]
	-- Switch to workspace
	hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
	-- Move window to workspace
	hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Move Windows (mouse binds)
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Function Keys
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind(
	"XF86KbdBrightnessUp",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/set_keyboard_brightness.sh next"),
	{ locked = true }
)
hl.bind(
	"XF86KbdBrightnessDown",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/set_keyboard_brightness.sh prev"),
	{ locked = true }
)
hl.bind("code:211", hl.dsp.exec_cmd("~/.config/hypr/scripts/switch_profile.sh"), { locked = true })

-- Lock Session
hl.bind("SUPER + Escape", hl.dsp.exec_cmd("~/.config/hypr/scripts/lock.sh")) -- SUPER + L is focus right
