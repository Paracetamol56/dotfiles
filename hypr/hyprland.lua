--██╗░░██╗██╗░░░██╗██████╗░██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
--██║░░██║╚██╗░██╔╝██╔══██╗██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
--███████║░╚████╔╝░██████╔╝██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
--██╔══██║░░╚██╔╝░░██╔═══╝░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
--██║░░██║░░░██║░░░██║░░░░░██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
--╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

-- Import colors from hyprland/colors.lua
local colors = require("hyprland/colors")

-- Set colors as global variables (for backward compatibility)
for key, value in pairs(colors) do
	_G[key] = value
end

-- ------ Config ------ #
local hl_path = "~/.config/hypr/hyprland"

-- Load configuration files
require("hyprland/execs")
require("hyprland/env")
require("hyprland/input")
require("hyprland/monitors")
require("hyprland/decoration")
require("hyprland/animations")
require("hyprland/keybinds")
require("hyprland/general")
require("hyprland/misc")
require("hyprland/rules")
