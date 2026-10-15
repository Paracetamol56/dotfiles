-- Miscellaneous configuration for Hyprland

hl.config({
	misc = {
		disable_hyprland_logo = true,
		animate_manual_resizes = true,
		force_default_wallpaper = 0,
		mouse_move_enables_dpms = 0,
		-- Lets a restarted Quickshell (or hyprlock, as a fallback) take over an existing lock
		allow_session_lock_restore = true,
	},
})
