local t = {}

t.states = {}

t.w = 256
t.h = 224
t.scale = 1
t.ox, t.oy = 0, 0
t.mousex, t.mousey = 0, 0

t.test_string =
	"The quick brown fox jumps\nover the lazy dog.\nJACKDAWS LOVE MY\nBIG SPHINX OF QUARTZ.\n1234567890!?@#$%&{[()]};:"

function t:add_state(id)
	self.states[id] = { id = id }
end

function t:resize(w, h)
	self.scale = math.min(w / self.w, h / self.h)
	self.ox = (w - self.w * self.scale) * 0.5
	self.oy = (h - self.h * self.scale) * 0.5
end

function t:set_state(state, arg)
	local new = self.states[state]
	if new == self.current then
		return
	end
	self.prev = self.current

	if new.load and not new.loaded then
		new.load()
		new.loaded = true
	end

	if new.switch then
		new.switch(arg)
	end

	self.current = new
end

return t
