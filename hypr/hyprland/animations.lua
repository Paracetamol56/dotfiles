-- Animations configuration for Hyprland

-- Bezier curve definition
hl.curve("easeOutSine", {
	type = "bezier",
	points = { { 0.61, 1 }, { 0.88, 1 } },
})

-- Animation definitions
hl.animation({
	leaf = "windows",
	enabled = true,
	speed = 1,
	bezier = "easeOutSine",
	style = "popin",
})

hl.animation({
	leaf = "windowsOut",
	enabled = true,
	speed = 1,
	bezier = "easeOutSine",
	style = "popin",
})

hl.animation({
	leaf = "border",
	enabled = true,
	speed = 1,
	bezier = "default",
})

hl.animation({
	leaf = "fade",
	enabled = true,
	speed = 1,
	bezier = "default",
})

hl.animation({
	leaf = "workspaces",
	enabled = true,
	speed = 1,
	bezier = "easeOutSine",
	style = "slidefade",
})
