local game = require("game")

local t = {
	up = { w = true, up = true, dpup = true },
	down = { s = true, down = true, dpdown = true },
	left = { a = true, left = true, dpleft = true },
	right = { d = true, right = true, dpright = true },
	action = { space = true, ["return"] = true },
	back = { escape = true, backspace = true },
	menu = { escape = true },
	reset = { r = true },
	undo = { z = true, backspace = true },
}

local d_t = {
	spring = { p = true },
	edit = { tab = true },
	next_level = { pagedown = true },
	prev_level = { pageup = true },
	next_page = { pagedown = true },
	prev_page = { pageup = true },
}

function t:load()
	if game.debug then
		for k, v in pairs(d_t) do
			self[k] = v
		end
	else
		for k, _ in pairs(d_t) do
			self[k] = {}
		end
	end
end

return t
