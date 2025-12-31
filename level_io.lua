local t = {}

function t.load(filename)
	local level = {}
	local section
	local separator = "|"
	local split_pattern = "([^" .. separator .. "]+)"
	local file = assert(io.open(filename, "r"))

	local function strip(str)
		return str and str:match("^%s*(.-)%s*$") or ""
	end

	local function process_line(line)
		local key, value = line:match("^(.+):(.*)$")
		if key and value == "" then
			section = key
			level[section] = {}
			return true
		elseif key then
			section = nil
			level[key] = tonumber(value) or strip(value)
		end
		if section then
			local row = {}
			for item in line:gmatch(split_pattern) do
				table.insert(row, tonumber(item) or strip(item))
			end
			table.insert(level[section], row)
		end
		return true
	end

	for line in file:lines() do
		line = strip(line)
		if line ~= "" then
			if not process_line(line) then
				return
			end
		end
	end
	file:close()
	return level
end

function t.save(level, filename)
	local file = io.open(filename, "w+")
	if not file then
		return false
	end
	local keys = {}
	for k, _ in pairs(level) do
		table.insert(keys, k)
	end
	table.sort(keys)
	for _, k in ipairs(keys) do
		if type(level[k]) == "table" then
			file:write(k .. ":\n")
			for _, item in ipairs(level[k]) do
				file:write(table.concat(item, "|") .. "\n")
			end
		else
			file:write(k .. ": " .. level[k] .. "\n")
		end
	end
	file:close()
	return true
end

return t
