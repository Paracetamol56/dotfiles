-- Animations configuration for Hyprland

-- Bezier curve definition
hl.curve("myBezier", {
	type = "bezier",
	points = { { 0.10, 0.9 }, { 0.1, 1.05 } },
})

-- Animation definitions
hl.animation({
	leaf = "windows",
	enabled = true,
	speed = 1,
	bezier = "myBezier",
	style = "popin",
})

hl.animation({
	leaf = "windowsOut",
	enabled = true,
	speed = 1,
	bezier = "myBezier",
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
	bezier = "myBezier",
	style = "slidefade",
})
