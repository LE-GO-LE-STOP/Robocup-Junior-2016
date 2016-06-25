local ev3 = require("ev3")
local class = require("class").class

local function normaliseAngle(angle)
	if angle >= 360 then
		angle = angle - 360
	else if angle < 0 then
		angle = angle + 360
	end

	return angle
end

local Tracker = class()

function Tracker:init(wheelRadius, vehicleRadius, leftMotor, rightMotor)
	self.wheelRadius = wheelRadius
	self.vehicleRadius = vehicleRadius
	self.leftMotor = leftMotor
	self.rightMotor = rightMotor

	self.x = 0
	self.y = 0
	self.angle = 0
	self.startPosition = nil

	self.wheelDistanceToDegrees = 180 / (pi * self.wheelRadius) -- Derived from "degrees to rotate wheel = (wheel circumference / turning circle circumference) * 360"
	self.wheelDegreesToRotations = self.vehicleRadius / self.wheelRadius -- Derived from "distance to move wheel = (angle / 360) * turning circle circumference"
end

function Tracker:set_position(x, y, angle)
	self.x = x
	self.y = y
	self.angle = angle
end

function Tracker:on(power)
	if not self.startPosition then
		self.startPosition = self:position()
	end

	leftMotor:on(power)
	rightMotor:on(power)
end

function Tracker:off(power)
	if self.startPosition then
		local endPosition = self:position()
		local distance = endPosition - self.startPosition

		local xOffset = math.deg(math.sin(math.rad(self.angle))) * distance
		local yOffset = math.deg(math.cos(math.rad(self.angle))) * distance

		self.x = self.x + xOffset
		self.y = self.y + yOffset

		self.startPosition = nil
	end

	leftMotor:off("hold")
	rightMotor:off("hold")
end

function Tracker:on_for_distance(power, distance)
	local d = distance * self.wheelDistanceToDegrees

	leftMotor:on_for_degrees(power, d, "hold", true)
	rightMotor:on_for_degrees(power, d, "hold", false)

	local xOffset = math.deg(math.sin(math.rad(self.angle))) * distance
	local yOffset = math.deg(math.cos(math.rad(self.angle))) * distance

	self.x = self.x + xOffset
	self.y = self.y + yOffset
end

function Tracker:rotate(power, brake)
	leftMotor:on(power)
	rightMotor:on(-power)
end

function Tracker:rotate_for_degrees(power, degrees)
	local d = degrees * self.wheelDegreesToRotations

	leftMotor:on_for_degrees(power, d, "hold", true)
	rightMotor:on_for_degrees(power, -d, "hold", false)

	self.angle = normaliseAngle(self.angle + degrees)
end

return Tracker