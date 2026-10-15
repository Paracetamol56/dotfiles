-- Animations configuration for Hyprland
-- Speeds are in tenths of a second (speed 4 = 400 ms).

-- Curves
-- Fast start, slight overshoot, settles: a soft spring for things appearing
hl.curve("spring", {
	type = "bezier",
	points = { { 0.05, 0.9 }, { 0.1, 1.05 } },
})
-- Smooth deceleration for movement (workspaces, windows moving)
hl.curve("easeOutQuint", {
	type = "bezier",
	points = { { 0.23, 1 }, { 0.32, 1 } },
})
-- Quick, no overshoot, for things leaving
hl.curve("easeInOut", {
	type = "bezier",
	points = { { 0.65, 0 }, { 0.35, 1 } },
})

-- Windows: pop in with the spring, leave with a quicker fade, slide when moved
hl.animation({
	leaf = "windowsIn",
	enabled = true,
	speed = 4,
	bezier = "spring",
	style = "popin 85%",
})

hl.animation({
	leaf = "windowsOut",
	enabled = true,
	speed = 3,
	bezier = "easeInOut",
	style = "popin 85%",
})

hl.animation({
	leaf = "windowsMove",
	enabled = true,
	speed = 4,
	bezier = "easeOutQuint",
})

hl.animation({
	leaf = "fade",
	enabled = true,
	speed = 3,
	bezier = "easeOutQuint",
})

hl.animation({
	leaf = "border",
	enabled = true,
	speed = 5,
	bezier = "default",
})

-- Workspaces slide sideways, like the bar's sliding underline; the special one slides up
hl.animation({
	leaf = "workspaces",
	enabled = true,
	speed = 4,
	bezier = "easeOutQuint",
	style = "slide",
})

hl.animation({
	leaf = "specialWorkspace",
	enabled = true,
	speed = 4,
	bezier = "easeOutQuint",
	style = "slidevert",
})

-- Other layers (launchers, notifications from other apps…) just fade
hl.animation({
	leaf = "layers",
	enabled = true,
	speed = 3,
	bezier = "easeOutQuint",
	style = "fade",
})

-- Quickshell's bar and panels animate themselves; don't animate them twice
hl.layer_rule({
	name = "Quickshell animates itself",
	match = { namespace = "^quickshell" },
	no_anim = true,
})
