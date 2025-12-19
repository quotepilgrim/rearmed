local game = require("game")
local list_menu = require("listmenu")
local title
local title_x, title_y
local title_menu

local state = game:add_state("title")

function state.load()
	title_menu = list_menu.new({
		x = 128,
		y = 144,
		center_x = true,
		items = {
			{
				"New Game",
				function()
					game:set_state("play")
				end,
			},
			{ "Continue" },
			{ "Options" },
			{ "Exit game", love.event.quit },
		},
	})
	title = love.graphics.newImage("assets/title.png")
	title_x = 128 - title:getWidth() / 2
	title_y = 16
end

function state.draw()
	love.graphics.draw(title, title_x, title_y)
	list_menu.draw(title_menu)
end

function state.keypressed(key)
	list_menu.input_on(title_menu, key)
end
