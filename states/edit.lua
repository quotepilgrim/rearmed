local game = require("game")
local level = require("level")
local selector = require("selector")
local input = require("input")
local tid = require("tile_ids")
local list_menu = require("listmenu")
local drawing = false
local mx, my, use_keyboard
local min, max, abs, ceil = math.min, math.max, math.abs, math.ceil
local repeat_keys = { up = false, down = false, left = false, right = false }
local repeat_timeout = 0

local state = game:add_state("edit")

local edit_menu = list_menu.new({
	x = 128,
	y = 80,
	center_x = true,
	center_y = true,
	items = {
		list_menu.default_items[1],
		{
			"Play",
			function()
				game:set_state("play")
			end,
		},
		list_menu.default_items[2],
	},
})

local doors_menu = list_menu.new({
	x = 128,
	items = {
		{ "north" },
		{ "east" },
		{ "south" },
		{ "west" },
	},
})

local cursor = {}

function cursor:draw()
	if not self.enabled then
		-- return
	end
	if selector.enabled then
		love.graphics.draw(self.sprite, (self.sx - 1) * 16 - 2, (self.sy - 1) * 16 - 2)
	else
		love.graphics.draw(self.sprite, (self.x - 1) * 16 - 10, (self.y - 1) * 16 - 10)
	end
end

local function level_select()
	local items = {}
	for _, i in pairs(level.list) do
		table.insert(items, { i })
	end
	game:set_state(
		"menu",
		list_menu.new({
			items = items,
			default_action = function(menu)
				level:set(menu.items[menu.selected][1])
				game:set_state("edit")
			end,
		})
	)
end

local function update_walls()
	local function get_neighbors(x, y)
		local neighbors = ""
		local id = level.data.grid[y][x]
		if tid.inner_walls[id] then
			if level.data.grid[y - 1] and tid.inner_walls[level.data.grid[y - 1][x]] then
				neighbors = neighbors .. "n"
			end
			if level.data.grid[x + 1] and tid.inner_walls[level.data.grid[y][x + 1]] then
				neighbors = neighbors .. "e"
			end
			if level.data.grid[y + 1] and tid.inner_walls[level.data.grid[y + 1][x]] then
				neighbors = neighbors .. "s"
			end
			if level.data.grid[x - 1] and tid.inner_walls[level.data.grid[y][x - 1]] then
				neighbors = neighbors .. "w"
			end
		end
		return neighbors
	end
	for y, row in ipairs(level.data.grid) do
		for x, _ in ipairs(row) do
			local neighbors = get_neighbors(x, y)
			if neighbors ~= "" then
				level.data.grid[y][x] = tid.neighbors_to_wall[neighbors]
			end
		end
	end
end

function state.load()
	cursor.sprite = love.graphics.newImage("assets/cursor.png")
	cursor.x = 2
	cursor.y = 2
	cursor.sx = 1
	cursor.sy = 4
	use_keyboard = true
end

function state.update(dt)
	level:update(dt)
	if use_keyboard then
		mx, my = cursor.x, cursor.y
	elseif selector.enabled then
		mx, my = ceil(game.mousex / 16), ceil(game.mousey / 16)
		if mx <= #selector.tiles[1] and my <= #selector.tiles then
			cursor.sx, cursor.sy = mx, my
		end
	else
		mx, my = ceil((game.mousex - level.offset) / 16), ceil((game.mousey - level.offset) / 16)
		cursor.x, cursor.y = mx, my
	end

	if not selector.enabled and selector.pick and drawing then
		if tid.floors[selector.pick] then
			level.floors[my] = level.floors[my] or {}
			level.floors[my][mx] = selector.pick
		elseif tid.boxes[selector.pick] ~= "box_on_one_way" and level.floors[my] then
			level.floors[my][mx] = nil
		elseif tid.boxes[selector.pick] == "box_on_one_way" then
			level.floors[my] = level.floors[my] or {}
			if not tid.one_ways[level.floors[my][mx]] then
				level.floors[my][mx] = 59
			end
		end
		level.data.grid[my][mx] = selector.pick
		update_walls()
		level:update_holes()
	end

	if repeat_timeout > 0 then
		repeat_timeout = repeat_timeout - dt
	else
		for k, v in pairs(repeat_keys) do
			if v then
				state.input_on(k)
				repeat_timeout = 0.1
				break
			end
		end
	end
end

function state.draw()
	love.graphics.push()
	love.graphics.translate(level.offset, level.offset)
	level:draw()
	love.graphics.pop()
	if selector.enabled then
		selector:draw()
	elseif not selector.hidden and selector.pick then
		love.graphics.setColor(1, 1, 1, 0.6)
		love.graphics.draw(
			level.tileimage,
			level.tiles[selector.pick],
			(mx - 1) * 16 + level.offset,
			(my - 1) * 16 + level.offset
		)
		love.graphics.setColor(1, 1, 1, 1)
	end
	cursor:draw()
end

function state.input_on(key)
	use_keyboard = true
	for k, _ in pairs(repeat_keys) do
		repeat_keys[k] = input[k][key] or false
		repeat_timeout = 0.25
	end
	if input.edit[key] then
		selector.enabled = not selector.enabled
	elseif input.next_level[key] then
		level:next()
	elseif input.prev_level[key] then
		level:prev()
	elseif input.reset[key] then
		level:set(level.filename)
	elseif key == "s" then
		if love.keyboard.isDown("lshift") and love.keyboard.isDown("lctrl") then
			level:generate(level.data)
			return
		elseif love.keyboard.isDown("lctrl") then
			level:save()
			print("Saved " .. level.filename)
			return
		end
	elseif input.menu[key] then
		if selector.enabled then
			selector.enabled = false
		else
			game:set_state("menu", edit_menu)
		end
	elseif input.back[key] then
		game:set_state("play")
	elseif input.action[key] then
		if selector.enabled then
			local x = cursor.sx
			local y = cursor.sy
			selector.pick = selector.tiles[y] and selector.tiles[y][x]
			selector.enabled = false
		else
			drawing = true
		end
	elseif key == "'" then
		selector.pick = level.data.grid[my][mx]
	elseif key == "m" then
		level_select()
	end
	if input.up[key] then
		if selector.enabled then
			cursor.sy = max(cursor.sy - 1, 1)
		else
			cursor.y = max(cursor.y - 1, 1)
		end
	elseif input.right[key] then
		if selector.enabled then
			cursor.sx = min(cursor.sx + 1, #selector.tiles[1])
		else
			cursor.x = min(cursor.x + 1, #level.data.grid[1])
		end
	elseif input.down[key] then
		if selector.enabled then
			cursor.sy = min(cursor.sy + 1, #selector.tiles)
		else
			cursor.y = min(cursor.y + 1, #level.data.grid)
		end
	elseif input.left[key] then
		if selector.enabled then
			cursor.sx = max(cursor.sx - 1, 1)
		else
			cursor.x = max(cursor.x - 1, 1)
		end
	end
end

function state.input_off(key)
	if input.action[key] then
		drawing = false
	end
	for k, _ in pairs(repeat_keys) do
		if input[k][key] then
			repeat_keys[k] = false
		end
	end
end

function state.mousepressed(x, y, button)
	use_keyboard = false
	if selector.enabled then
		selector:mousepressed(x, y, button)
	elseif button == 3 and game.debug then
		selector.pick = level.data.grid[my][mx]
	elseif button == 2 and game.debug then
		selector.enabled = true
	elseif button == 1 then
		drawing = true
	end
end

function state.mousereleased(x, y, button)
	if selector.enabled then
		selector:mousereleased(x, y, button)
	elseif button == 1 then
		drawing = false
	end
end

function state.keypressed(key)
	return state.input_on(key)
end
function state.keyreleased(key)
	return state.input_off(key)
end
function state.gamepadpressed(_, button)
	return state.input_on(button)
end
function state.gamepadreleased(_, button)
	return state.input_off(button)
end

function state.mousemoved(_, _, dx, dy)
	if max(abs(dx), abs(dy)) > 5 then
		use_keyboard = false
	end
end
