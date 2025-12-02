local player = require("player")
local game = require("game")
local level = require("level")
local input = require("input")
local tile_ids = require("tile_ids")
require("states.title")
require("states.play")
require("states.edit")
require("states.menu")

local root, full_root

if love.filesystem.isFused() then
	full_root = love.filesystem.getSourceBaseDirectory()
	love.filesystem.mount(full_root, "root")
	root = "root/"
else
	root = "/"
end

local items = love.filesystem.getDirectoryItems(root)

--[[ for _, val in pairs(items) do
	local info = love.filesystem.getDirectoryItems(root .. val)
	print(val)
	for k, v in pairs(info) do
		print(k, v)
	end
	print()
end ]]

function love.load()
	while #arg > 0 do
		local v = table.remove(arg)
		if v == "--debug" then
			game.debug = true
		end
	end

	love.graphics.setDefaultFilter("nearest", "nearest")
	local font = love.graphics.newFont("assets/awspring.otf", 14)
	love.graphics.setFont(font)

	tile_ids:load()
	level:load(player)
	player:load(level, 9, 13)
	game:set_state("title")
	game:resize(512, 448)

	input:load()
end

function love.draw()
	love.graphics.clear(0.1, 0.1, 0.1)
	love.graphics.push()
	love.graphics.translate(game.ox, game.oy)
	love.graphics.scale(game.scale, game.scale)
	love.graphics.setScissor(game.ox, game.oy, game.scale * 256, game.scale * 224)
	if game.current.draw then
		game.current.draw()
	end
	love.graphics.setScissor()
	love.graphics.pop()
end

function love.update(dt)
	if game.current.update then
		return game.current.update(dt)
	end
end

function love.keypressed(key)
	if game.current.keypressed then
		return game.current.keypressed(key)
	end
end

function love.keyreleased(key)
	if game.current.keyreleased then
		return game.current.keyreleased(key)
	end
end

function love.gamepadpressed(_, button)
	if game.current.gamepadpressed then
		return game.current.gamepadpressed(button)
	end
end

function love.gamepadreleased(_, button)
	if game.current.gamepadreleased then
		return game.current.gamepadreleased(button)
	end
end

function love.mousepressed(x, y, button)
	if game.current.mousepressed then
		return game.current.mousepressed(x, y, button)
	end
end

function love.mousereleased(x, y, button)
	if game.current.mousereleased then
		return game.current.mousereleased(x, y, button)
	end
end

function love.mousemoved(x, y, dx, dy)
	game.mousex, game.mousey = (x - game.ox) / game.scale, (y - game.oy) / game.scale
	if game.current.mousemoved then
		return game.current.mousemoved(game.mousex, game.mousey, dx, dy)
	end
end

function love.resize(w, h)
	game:resize(w, h)
end
