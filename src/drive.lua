local class = require("class").class
local trig = require("trig")

-- General algorithms for a holonomic drive
local Holonomic = class()

function Holonomic:init(front, back, left, right)
	self.front = front
	self.back = back
	self.left = left
	self.right = right
end

function Holonomic:off(brake)
	self.front:off(brake)
	self.back:off(brake)
	self.left:off(brake)
	self.right:off(brake)
end

-- 4 wheeled holonimic drive controller
local Holonimic4 = class(Holonimic)

function Holonimic4:init(...)
	Holonomic.init(self, ...)
end

function Holonimic4:move(angle, power)
	while angle < 0 then angle = angle + 360 end
	while angle > 360 then angle = angle - 360 end

	local frontbackPower = trig.sin[angle] * power
	local leftrightPower = trig.cos[angle] * power

	self.front:on(frontbackPower)
	self.back:on(frontbackPower)

	self.left:on(leftrightPower)
	self.right:on(leftrightPower)
end

-- 3 wheeled holonomic drive controller
local Holonomic3 = class(Holonimic)


return {
	
}