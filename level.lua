local level_io = require("level_io")
local tid = require("tile_ids")
local game = require("game")
local history = require("history")
local t = {}

t.moving_box = {
	active = false,
}

function t.moving_box:start(x, y, dir, max_dist)
	self.active = true
	self.x = x
	self.y = y
	self.startx = x
	self.starty = y
	self.dist = 0
	self.max_dist = max_dist or 1
	self.dir = dir
end

function t.moving_box:stop()
	self.active = false
	self.moving = false
end

t.data = {}
t.tiles = {}
t.list = {}
t.floors = {}
t.tilesize = 16
t.offset = -8

function t:swap_tiles()
	for y, row in ipairs(self.data.grid) do
		for x, col in ipairs(row) do
			if tid.swap_tiles[col] and not (y == self.player.y and x == self.player.x) then
				self.data.grid[y][x] = tid.swap_tiles[col]
			end
		end
	end
end

function t:update_holes()
	for y, row in ipairs(self.data.grid) do
		for x, col in ipairs(row) do
			if tid.floors[col] == "hole" then
				local above = self.data.grid[y - 1] and self.data.grid[y - 1][x]
				if tid.floors[above] == "hole" then
					self.data.grid[y][x] = 52
				elseif tid.floors[above] == "floor" then
					self.data.grid[y][x] = 53
				elseif tid.floors[above] == "box_top" then
					self.data.grid[y][x] = 54
				end
			end
		end
	end
end

function t:load(player)
	self.tileimage = love.graphics.newImage("assets/level_tiles.png")
	local width = self.tileimage:getWidth()
	local height = self.tileimage:getHeight()
	local rows = height / self.tilesize
	local cols = width / self.tilesize

	self.player = player

	local count = 1
	for i = 0, rows - 1 do
		for j = 0, cols - 1 do
			self.tiles[count] =
				love.graphics.newQuad(j * self.tilesize, i * self.tilesize, self.tilesize, self.tilesize, width, height)
			count = count + 1
		end
	end

	count = 1
	while true do
		local filename = "levels/level" .. tostring(count) .. ".txt"
		if love.filesystem.getInfo(filename) then
			self.list[count] = filename
		else
			break
		end
		count = count + 1
	end
	self:set(self.list[1])
	grid = self.data.gid
end

function t:draw()
	for y, row in ipairs(self.data.grid) do
		for x, tile in ipairs(row) do
			local quad = self.tiles[tile]
			if quad then
				love.graphics.draw(self.tileimage, quad, (x - 1) * self.tilesize, (y - 1) * self.tilesize)
			end
			if game.debug and love.keyboard.isDown("f1") and self.floors[y] and tid.one_ways[self.floors[y][x]] then
				love.graphics.draw(
					self.tileimage,
					self.tiles[self.floors[y][x]],
					(x - 1) * self.tilesize,
					(y - 1) * self.tilesize
				)
			end
		end
	end
	if self.moving_box.active then
		love.graphics.draw(
			self.tileimage,
			self.tiles[26],
			(self.moving_box.x - 1) * self.tilesize,
			(self.moving_box.y - 1) * self.tilesize
		)
	end
end

function t:update(dt)
	if self.moving_box.active then
		self.moving_box.dist =
			math.min(self.moving_box.max_dist, self.moving_box.dist + dt * self.player:get_speed(self.player.spring))
		self.moving_box.x = self.moving_box.startx + self.moving_box.dist * self.moving_box.dir[1]
		self.moving_box.y = self.moving_box.starty + self.moving_box.dist * self.moving_box.dir[2]
		if self.moving_box.dist == self.moving_box.max_dist then
			local bx, by = self.moving_box.x, self.moving_box.y
			local tile = self.data.grid[by][bx]
			self.data.grid[by][bx] = tid.floor_to_box[tile] or 26
			if tid.floors[tile] == "plate" then
				self:swap_tiles()
			elseif tid.floors[tile] == "hole" then
				self.data.grid[by][bx] = 58
				self.floors[by][bx] = 58
				self:update_holes()
			end
			self.moving_box:stop()
			self.player:unfreeze()
			self:has_cleared()
		end
	end
end

function t:has_cleared()
	for _, row in ipairs(self.data.grid) do
		for _, col in ipairs(row) do
			if tid.floors[col] == "goal" then
				return false
			end
		end
	end
	self.player:set_state("idle")
	self.player:freeze()
	self:next()
	return true
end

function t:move_box(x, y, dir)
	local nx, ny = x + dir[1], y + dir[2]
	local box = self.data.grid[y][x]
	local floor = self.floors[y] and self.floors[y][x] or tid.box_to_floor[box]
	local target = self.data.grid[ny][nx]
	local dist = 1

	if tid.one_ways[target] then
		if
			dir[1] == 1 and tid.one_ways[target] ~= "right"
			or dir[1] == -1 and tid.one_ways[target] ~= "left"
			or dir[2] == 1 and tid.one_ways[target] ~= "down"
			or dir[2] == -1 and tid.one_ways[target] ~= "up"
		then
			return false
		end
	elseif not tid.floors[target] then
		return false
	end
	history:push(self.data.grid, self.player.x, self.player.y)
	if tid.boxes[box] == "box_on_plate" then
		self:swap_tiles()
		self.data.grid[ny][nx] = target
	end
	if self.player.spring then
		while true do
			local dx, dy = dist * dir[1], dist * dir[2]
			local old_target = target
			target = self.data.grid[ny + dy] and self.data.grid[ny + dy][nx + dx]
			if
				not tid.floors[target]
				or (tid.floors[old_target] == "plate" and tid.floors[target] == "tile")
				or (tid.floors[old_target] == "hole")
			then
				break
			end
			dist = dist + 1
		end
		self.player:freeze()
	end
	self.moving_box:start(x, y, dir, dist)
	if tid.one_ways[floor] then
		self.data.grid[y][x] = self.floors[y] and self.floors[y][x] or floor
	else
		self.data.grid[y][x] = floor
	end
	return true
end

function t:set(filename)
	self.player.x, self.player.y = 9, 13
	self.player:unfreeze()
	self.filename = filename
	self.data = level_io.load(filename)
	self.floors = {}
	for y, row in ipairs(self.data.grid) do
		for x, col in ipairs(row) do
			if tid.floors[col] then
				self.floors[y] = self.floors[y] or {}
				self.floors[y][x] = col
			end
		end
	end
	if self.data.one_ways then
		for _, v in pairs(self.data.one_ways) do
			local id, x, y = unpack(v)
			self.floors[y] = self.floors[y] or {}
			self.floors[y][x] = id
		end
	end
	if game.debug then
		print("Loaded " .. self.filename)
	end
	history:clear()
end

function t:save()
	if not game.debug then
		return
	end
	self.data.one_ways = nil
	for y, row in ipairs(self.data.grid) do
		for x, col in ipairs(row) do
			if col == 63 then
				self.data.one_ways = self.data.one_ways or {}
				local id = self.floors[y] and self.floors[y][x] or 59
				table.insert(self.data.one_ways, { id, x, y })
			end
		end
	end
	if level_io.save(self.data, self.filename) then
		history:clear()
	end
end

function t:generate(data)
	data = data or level_io.load("levels/template.txt")
	local filename = "levels/level" .. tostring(#self.list + 1) .. ".txt"
	level_io.save(data, filename)
	table.insert(self.list, filename)
	self:set(filename)
end

function t:next()
	if love.keyboard.isDown("lshift") then
		self:generate()
		return
	end
	for i, v in ipairs(self.list) do
		if v == self.filename then
			self:set(self.list[i + 1] or self.list[1])
			break
		end
	end
end

function t:prev()
	for i, v in ipairs(self.list) do
		if v == self.filename then
			self:set(self.list[i - 1] or self.list[#self.list])
			break
		end
	end
end

return t
