local t = {}

--[[ I'm putting this here so I don't confuse myself later:
The walls list is for things that block player movement and the floors list
for things that boxes can move into. A tile that is in both lists (24) will
stop the player from moving but allow boxes to go through, and a tile that is
in neither (51) will stop boxes but not the player.
]]

t.floors = {
	[10] = "floor",
	[24] = "cage",
	[25] = "goal",
	[40] = "tile",
	[45] = "plate",
	[50] = "button",
	[52] = "hole",
	[53] = "hole",
	[54] = "hole",
	[58] = "box_top",
	[59] = "one_way",
	[60] = "one_way",
	[61] = "one_way",
	[62] = "one_way",
}

t.boxes = {
	[26] = "box_on_floor",
	[27] = "box_on_goal",
	[46] = "box_on_plate",
	[47] = "box_on_tile",
	[55] = "box_on_button",
	[63] = "box_on_one_way",
	[64] = "box_on_cage", -- yes, not "in_cage", it needs to be consistent
}

t.walls = {
	[1] = "wall",
	[2] = "wall",
	[3] = "wall",
	[4] = "inner_wall",
	[5] = "inner_wall",
	[6] = "inner_wall",
	[7] = "inner_wall",
	[9] = "wall",
	[11] = "wall",
	[12] = "inner_wall",
	[13] = "inner_wall",
	[14] = "inner_wall",
	[15] = "inner_wall",
	[17] = "wall",
	[18] = "wall",
	[19] = "wall",
	[20] = "inner_wall",
	[21] = "inner_wall",
	[22] = "inner_wall",
	[23] = "inner_wall",
	[24] = "cage",
	[28] = "inner_wall",
	[29] = "inner_wall",
	[30] = "inner_wall",
	[31] = "inner_wall",
	[39] = "tile_up",
	[48] = "block",
	[52] = "hole",
	[53] = "hole",
	[54] = "hole",
	[64] = "box_on_cage",
}

t.inner_walls = {
	[4] = "es",
	[5] = "esw",
	[6] = "sw",
	[7] = "s",
	[12] = "nes",
	[13] = "nesw",
	[14] = "nsw",
	[15] = "ns",
	[20] = "ne",
	[21] = "new",
	[22] = "nw",
	[23] = "n",
	[28] = "e",
	[29] = "ew",
	[30] = "w",
	[31] = "_",
}

t.one_ways = {
	[59] = "up",
	[60] = "right",
	[61] = "down",
	[62] = "left",
}

function t:load()
	self.floor_to_box = {}
	self.box_to_floor = {}
	self.swap_tiles = {}
	self.neighbors_to_wall = {}
	self.all = {}
	for i, floor in pairs(self.floors) do
		for j, box in pairs(self.boxes) do
			local match = box:match("^box_on_(.*)$")
			if match == floor then
				self.floor_to_box[i] = j
				self.box_to_floor[j] = i
			end
		end
	end
	for i, wall in pairs(self.walls) do
		for j, floor in pairs(self.floors) do
			if wall == "tile_up" and floor == "tile" then
				self.swap_tiles[i] = j
				self.swap_tiles[j] = i
			end
		end
	end
	for k, v in pairs(self.inner_walls) do
		self.neighbors_to_wall[v] = k
	end
	for key, val in pairs(self) do
		if type(val) == "table" and key ~= "all" then
			for k, v in pairs(val) do
				self.all[k] = v
			end
		end
	end
end

return t
