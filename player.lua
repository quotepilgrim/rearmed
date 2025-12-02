local input = require("input")
local tile_ids = require("tile_ids")

local timer = 0

local t = {}
local dist = 0
local start_x, start_y = 0, 0
local dirs = {
	up = { 0, -1 },
	down = { 0, 1 },
	left = { -1, 0 },
	right = { 1, 0 },
}
local dir, next_dir
local dir_queue = {}

function t:load(level, x, y)
	self.x = x
	self.y = y
	self.speed = 5
	self:set_state("idle")
	self.level = level
	self.frozen = false
	self.spring = false
	self.timeout = 0
	self.sheet = love.graphics.newImage("assets/char_normal.png")
	self.w = self.sheet:getWidth() / 4
	self.h = self.sheet:getHeight() / 4
	self.frame = 1
	local sprites = {}
	dir = dirs.up
	for i = 1, 4 do
		for j = 1, 4 do
			local ix = (i - 1) * 4 + j
			sprites[ix] =
				love.graphics.newQuad((j - 1) * self.w, (i - 1) * self.h, self.w, self.h, self.w * 4, self.h * 4)
		end
	end
	self.sprites = {
		[dirs.up] = { sprites[1], sprites[2], sprites[3], sprites[4] },
		[dirs.right] = { sprites[5], sprites[6], sprites[7], sprites[8] },
		[dirs.down] = { sprites[9], sprites[10], sprites[11], sprites[12] },
		[dirs.left] = { sprites[13], sprites[14], sprites[15], sprites[16] },
	}
end

t.states = {
	idle = {},
	moving = {},
}

function t:set_state(state)
	self.current = self.states[state]
end

function t:update(dt)
	if self.current.update then
		return self.current.update(self, dt)
	end
end

function t:draw()
	love.graphics.draw(self.sheet, self.sprites[dir][self.frame], (self.x - 1) * 16, (self.y - 1) * 16 - 8)
end

function t:get_speed(fast)
	fast = fast or false
	if (not self.moving and self.first_move) or fast then
		return self.speed * 8
	else
		return self.speed
	end
end

function t:freeze()
	self.frozen = true
end

function t:unfreeze()
	if not self.frozen then
		return
	end
	self.frozen = false
	self:set_state("idle")
end

function t:move(first_move)
	if not next_dir then
		self:set_state("idle")
		return
	end
	if self.timeout > 0 then
		return
	end
	dir = next_dir
	next_dir = nil
	local x, y = self.x + dir[1], self.y + dir[2]
	local target = self.level.data.grid[y] and self.level.data.grid[y][x]
	if not target then
		self.moving = false
		self:set_state("idle")
		return
	end
	if tile_ids.boxes[target] then
		if not self.level:move_box(x, y, dir) then
			self.moving = false
			self:set_state("idle")
			return
		elseif tile_ids.walls[target] then
			self.moving = false
			self:set_state("idle")
			return
		elseif self.spring then
			first_move = false
			self.moving = false
		end
	elseif tile_ids.walls[target] then
		self.moving = false
		self:set_state("idle")
		return
	end
	start_x, start_y = self.x, self.y
	self.first_move = first_move or false
	self.moving = true
	self:set_state("moving")
end

function t.states.idle.update(player, dt)
	player.frame = 1
	if player.timeout > 0 then
		player.timeout = player.timeout - dt
		if player.timeout < 0 then
			if #dir_queue > 0 then
				player:set_state("moving")
			end
			player.timeout = 0
		end
	end

	if next_dir then
		player:move(true)
	end
end

function t:input_on(key)
	for k, d in pairs(dirs) do
		if input[k][key] then
			next_dir = d
			break
		end
	end
	if next_dir then
		table.insert(dir_queue, next_dir)
	end
	if input.spring[key] then
		self.spring = not self.spring
	end
end

function t:input_off(key)
	local remove
	for k, d in pairs(dirs) do
		if input[k][key] then
			remove = d
			break
		end
	end
	for i, d in pairs(dir_queue) do
		if d == remove then
			table.remove(dir_queue, i)
			break
		end
	end
	next_dir = dir_queue[#dir_queue]
	if #dir_queue == 0 then
		self.moving = false
	end
end

function t.states.moving.update(player, dt)
	timer = timer + dt
	if player.frozen then
		return
	end
	dist = math.min(1, dist + dt * player:get_speed())
	player.x = start_x + dist * dir[1]
	player.y = start_y + dist * dir[2]
	if dist == 1 then
		dist = 0
		if #dir_queue > 0 then
			next_dir = dir_queue[#dir_queue]
			player:move()
		else
			player.moving = false
			player:set_state("idle")
		end
	end
	if timer > 0.2 then
		player.frame = player.frame % 4 + 1
		timer = 0
	end
end

return t
