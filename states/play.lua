local game = require("game")
local level = require("level")
local player = require("player")
local selector = require("selector")
local input = require("input")
local history = require("history")
local list_menu = require("listmenu")

local state = game:add_state("play")

local play_menu = list_menu.new({
	x = 128,
	y = 80,
	center_x = true,
	center_y = true,
	items = {
		list_menu.default_items[1],
		{
			"Edit",
			function()
				game:set_state("edit")
			end,
		},
		list_menu.default_items[2],
	},
})

function state.update(dt)
	level:update(dt)
	player:update(dt)
end

function state.draw()
	love.graphics.push()
	love.graphics.translate(level.offset, level.offset)
	level:draw()
	player:draw()
	love.graphics.pop()
end

function state.input_on(key)
	if input.edit[key] then
		game:set_state("edit")
	elseif input.next_level[key] then
		level:next()
	elseif input.prev_level[key] then
		level:prev()
	elseif input.undo[key] then
		if player.moving then
			return
		end
		local grid = history:pop()
		if grid then
			level.data.grid = grid
			player.x = grid.playerx
			player.y = grid.playery
		else
			player.x, player.y = 9, 13
		end
	elseif input.reset[key] then
		if player.moving then
			return
		end
		local grid = history:get(1)
		if grid then
			level.data.grid = grid
			history:clear()
		end
		player.x, player.y = 9, 13
	elseif input.menu[key] then
		game:set_state("menu", play_menu)
	end
end

function state.keypressed(key)
	player:input_on(key)
	state.input_on(key)
end

function state.keyreleased(key)
	player:input_off(key)
end

function state.gamepadpressed(_, button)
	player:input_on(button)
end

function state.gamepadreleased(_, button)
	player:input_off(button)
end

function state.mousepressed(x, y, button)
	if selector.enabled then
		selector:mousepressed(x, y, button)
	elseif button == 3 and game.debug then
		local bx, by = math.ceil((game.mousex - level.offset) / 16), math.ceil((game.mousey - level.offset) / 16)
		selector.pick = level.data.grid[by][bx]
	elseif button == 2 and game.debug then
		game:set_state("edit")
		selector.enabled = true
	end
end

function state.mousereleased(x, y, button)
	if selector.enabled then
		selector:mousereleased(x, y, button)
	end
end
