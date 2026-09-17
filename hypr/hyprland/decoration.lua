-- Decoration configuration for Hyprland

hl.config({
	decoration = {
		-- Window Rounding
		rounding = 5,

		-- Opacity
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		fullscreen_opacity = 1.0,

		-- Dimming
		dim_inactive = false,
		dim_strength = 0.5,

		-- Blur
		blur = {
			enabled = false,
			size = 8,
			popups = false,
		},
	},
})
