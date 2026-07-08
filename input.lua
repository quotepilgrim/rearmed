local game = require("game")

local M = {}

M.keyboard = {
	up = { w = true, up = true },
	down = { s = true, down = true },
	left = { a = true, left = true },
	right = { d = true, right = true },
	action = { space = true, ["return"] = true },
	back = { escape = true, backspace = true },
	menu = { escape = true },
	reset = { r = true },
	undo = { z = true, backspace = true },
	selector = { tab = true },
	pick = { ["'"] = true, p = true },
}

M.gamepad = {
	up = { dpup = true },
	down = { dpdown = true },
	left = { dpleft = true },
	right = { dpright = true },
	action = { a = true },
	back = { back = true },
	menu = { start = true },
	reset = {},
	undo = { back = true },
	selector = {},
	pick = {},
}

local debug_keyboard = {
	spring = { p = true },
	edit = { tab = true },
	next_level = { pagedown = true },
	prev_level = { pageup = true },
	next_page = { pagedown = true },
	prev_page = { pageup = true },
}

function M:load()
	if game.debug then
		for k, v in pairs(debug_keyboard) do
			self.keyboard[k] = v
		end
	else
		for k, _ in pairs(debug_keyboard) do
			self.keyboard[k] = {}
		end
	end
end

return M
