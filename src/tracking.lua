local ev3 = require("ev3")
local class = require("class").class

local Tracker = class()

function Tracker:init(wheelRadius, vehicleRadius, leftMotor, rightMotor)
	self.wheelRadius = wheelRadius
	self.vehicleRadius = vehicleRadius
	self.leftMotor = leftMotor
	self.rightMotor = rightMotor

	self.x = 0
	self.y = 0
	self.angle = 0

	self.wheelDistanceToDegrees = 180 / (pi * self.wheelRadius) -- Derived from "degrees to rotate wheel = (wheel circumference / turning circle circumference) * 360"
	self.wheelDegreesToRotations = self.vehicleRadius / self.wheelRadius -- Derived from "distance to move wheel = (angle / 360) * turning circle circumference"
end

function Tracker:on(power)

end

function Tracker:off(power)

end

function Tracker:on_for_distance(power, distance, brake)
	local d = distance * self.wheelDistanceToDegrees

	leftMotor:on_for_degrees(power, d, brake, true)
	rightMotor:on_for_degrees(power, d, brake, false)
end

function Tracker:rotate(power, degrees, brake)
	local d = degrees * self.wheelDegreesToRotations

	leftMotor:on_for_degrees(power, d, brake, true)
	rightMotor:on_for_degrees(power, d, brake, false)
end

return Tracker