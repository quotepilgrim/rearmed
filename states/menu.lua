local game = require("game")
local list_menu = require("listmenu")
local input = require("input")
local menu

game:add_state("menu")
local state = game.states.menu

function state.switch(arg)
	menu = arg or list_menu.new()
end

function state.draw()
	game.prev.draw()
	love.graphics.setColor(0, 0, 0, 0.6)
	love.graphics.rectangle("fill", 0, 0, 256, 224)
	love.graphics.setColor(1, 1, 1, 1)
	list_menu.draw(menu)
end

function state.update(dt)
	--
end

function state.keypressed(key)
	list_menu.input_on(menu, key)
	if input.back[key] then
		game:set_state(game.prev.id)
	end
end
