-- Window rules for Hyprland

hl.window_rule({
	name = "Fade animation",
	match = { class = "(hyprpaper|selection)" },
	animation = "fade",
})

-- Apps (browsers, Electron…) ask to be maximised when they open, which made new windows
-- fill the screen even next to others. Ignore those requests and let tiling decide; the
-- maximise / fullscreen keybinds still work.
hl.window_rule({
	name = "Ignore maximise requests",
	match = { class = ".*" },
	suppress_event = "maximize",
})

