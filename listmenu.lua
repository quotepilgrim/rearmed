local game = require("game")
local input = require("input")
local t = {}
local font, line_height, x, y

function t.new(arg)
	local newt = {}
	arg = arg or newt
	font = love.graphics.getFont()
	newt.x = arg and arg.x or 10
	newt.y = arg and arg.y or 10
	newt.center_x = arg and arg.center_x or false
	newt.center_y = arg and arg.center_y or false
	newt.first = arg and arg.first or 1
	newt.selected = arg and arg.selected or 1
	newt.visible_items = arg and arg.visible_items or 10
	newt.items = arg and arg.items or t.default_items
	newt.last = math.min(#newt.items, newt.visible_items)
	newt.default_action = arg.default_action
	line_height = font:getHeight()
	newt.height = line_height * #newt.items
	return newt
end

local function scroll_down(menu, amount)
	for _ = 1, amount do
		if menu.selected == #menu.items then
			return
		end
		menu.selected = math.min(menu.selected + 1, #menu.items)
		if menu.selected > menu.first + math.floor(menu.visible_items * 0.5) then
			menu.last = math.min(menu.last + 1, #menu.items)
			menu.first = math.max(menu.last - menu.visible_items + 1, 1)
		end
	end
end

local function scroll_up(menu, amount)
	for _ = 1, amount do
		if menu.selected == 1 then
			return
		end
		menu.selected = math.max(menu.selected - 1, 1)
		if menu.selected < menu.first + math.floor(menu.visible_items * 0.5) then
			menu.first = math.max(menu.first - 1, 1)
			menu.last = math.min(menu.first - 1 + menu.visible_items, #menu.items)
		end
	end
end

function t.draw(menu)
	if menu.center_y then
		y = menu.y - math.floor(menu.height * 0.5)
	else
		y = menu.y
	end
	if menu.first > 1 then
		love.graphics.print("^", menu.x - 6, y - 10)
	end
	for i = menu.first, menu.last do
		local width = font:getWidth(menu.items[i][1])
		if menu.center_x then
			x = menu.x - math.floor(width * 0.5)
		else
			x = menu.x
		end
		love.graphics.print(menu.items[i][1], x, y)
		if menu.selected == i then
			love.graphics.print("*", x - 6, y)
			love.graphics.print("*", x + font:getWidth(menu.items[i][1]), y)
		end
		y = y + line_height
	end
	if menu.last < #menu.items then
		love.graphics.print("ˇ", menu.x - 6, y - 4)
	end
end

function t.not_implemented(menu)
	print('"' .. menu.items[menu.selected][1] .. '" has no implemented action.')
end

t.default_items = {
	{
		"Return",
		function()
			game:set_state(game.prev.id)
		end,
	},
	{ "Quit", love.event.quit },
}

function t.input_on(menu, key)
	if input.down[key] then
		scroll_down(menu, 1)
	elseif input.next_page[key] then
		scroll_down(menu, menu.visible_items - 1)
	elseif input.up[key] then
		scroll_up(menu, 1)
	elseif input.prev_page[key] then
		scroll_up(menu, menu.visible_items - 1)
	elseif input.action[key] then
		local _, action = unpack(menu.items[menu.selected])
		action = action or menu.default_action
		if action then
			action(menu)
		else
			t.not_implemented(menu)
		end
	end
end

return t
