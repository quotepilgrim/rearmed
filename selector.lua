local game = require("game")
local level = require("level")
local t = {}

t.enabled = false
t.tiles = {
	{ 1, 2, 3, 8 },
	{ 9, 32, 11, 16 },
	{ 17, 18, 19, 31 },
	{ 10, 25, 26, 27 },
	{ 46, 47, 55, 63 },
	{ 40, 39, 24, 64 },
	{ 45, 48, 50, 51 },
	{ 52, 53, 54, 58 },
	{ 59, 60, 61, 62 },
}

function t:draw()
	if self.hidden then
		return
	end
	love.graphics.setColor(0, 0, 0, 0.5)
	love.graphics.rectangle("fill", 0, 0, 256, 224)
	love.graphics.setColor(1, 1, 1, 1)
	for y, tbl in ipairs(self.tiles) do
		for x, i in ipairs(tbl) do
			local quad = level.tiles[i]
			if quad then
				love.graphics.draw(level.tileimage, quad, (x - 1) * level.tilesize, (y - 1) * level.tilesize)
			end
		end
	end
end

function t:mousepressed(x, y, button)
	if not game.debug then
		return
	end
	x = math.ceil((x - game.ox) / game.scale / 16)
	y = math.ceil((y - game.oy) / game.scale / 16)
	self.pick = self.tiles[y] and self.tiles[y][x]
	if button == 1 then
		self.hidden = true
	elseif button == 2 then
		if not self.pick then
			self.enabled = false
			return
		end
		print(self.pick)
	end
end

function t:mousereleased(x, y, button)
	if not game.debug then
		return
	end
	if button == 1 then
		self.enabled = false
		self.hidden = false
	end
end

return t
