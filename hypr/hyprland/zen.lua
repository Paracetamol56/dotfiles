-- Zen mode (SUPER + SHIFT + Z): the focused window alone, floating in the middle of a black
-- screen; the bar, the wallpaper and the other monitors are hidden (Quickshell,
-- services/Zen.qml) and notifications held back (Do Not Disturb).
--
-- While in zen mode every shortcut is off (the "zen" submap) except:
--   SUPER + SHIFT + Z   leave zen mode (the window goes back where it was)
--   SUPER + Escape      lock the screen
-- Closing the window also leaves zen mode.

local zen = nil -- { address, workspace, floating, at, size } while active

local function selector()
	return "address:" .. zen.address
end

-- The monitor's size in layout pixels (rotated monitors swap width and height)
local function logical_size(monitor)
	local w, h = monitor.width / monitor.scale, monitor.height / monitor.scale
	if monitor.transform % 2 == 1 then
		w, h = h, w
	end
	return w, h
end

local function leave(window_gone)
	if not zen then
		return
	end
	local state = zen
	zen = nil

	hl.dispatch(hl.dsp.submap("reset"))
	hl.exec_cmd("qs ipc call zen exit")

	if window_gone then
		hl.dispatch(hl.dsp.focus({ workspace = state.workspace }))
		return
	end

	local window = "address:" .. state.address
	hl.dispatch(hl.dsp.window.move({ workspace = state.workspace, window = window }))
	if state.floating then
		-- Back to where it floated before
		hl.dispatch(hl.dsp.window.resize({ x = state.size[1], y = state.size[2], window = window }))
		hl.dispatch(hl.dsp.window.move({ x = state.at[1], y = state.at[2], window = window }))
	else
		hl.dispatch(hl.dsp.window.float({ action = "toggle", window = window }))
	end
	hl.dispatch(hl.dsp.focus({ window = window }))
end

local function enter()
	local window = hl.get_active_window()
	if zen or not window or not window.workspace or not window.monitor then
		return
	end
	zen = {
		address = window.address,
		workspace = window.workspace.id,
		floating = window.floating,
		at = { window.at[1] or window.at.x, window.at[2] or window.at.y },
		size = { window.size[1] or window.size.x, window.size[2] or window.size.y },
	}

	-- Quickshell first: black backdrop, bar hidden, DND
	hl.exec_cmd("qs ipc call zen enter " .. window.monitor.name)

	-- Alone on its own workspace, floating, 80% × 90% of the monitor, centred
	hl.dispatch(hl.dsp.window.move({ workspace = "name:zen", window = selector() }))
	if not zen.floating then
		hl.dispatch(hl.dsp.window.float({ action = "toggle", window = selector() }))
	end
	local w, h = logical_size(window.monitor)
	hl.dispatch(hl.dsp.window.resize({ x = math.floor(w * 0.8), y = math.floor(h * 0.9), window = selector() }))
	hl.dispatch(hl.dsp.window.center({ window = selector() }))
	hl.dispatch(hl.dsp.focus({ window = selector() }))

	hl.dispatch(hl.dsp.submap("zen"))
end

local function toggle()
	if zen then
		leave(false)
	else
		enter()
	end
end

hl.bind("SUPER + SHIFT + Z", toggle)

-- The only shortcuts while in zen mode
hl.define_submap("zen", function()
	hl.bind("SUPER + SHIFT + Z", toggle)
	hl.bind("SUPER + Escape", hl.dsp.exec_cmd("~/.config/hypr/scripts/lock.sh"))
end)

-- The zen window was closed: leave, back to the workspace it came from
hl.on("window.close", function(window)
	if zen and window and window.address == zen.address then
		leave(true)
	end
end)
