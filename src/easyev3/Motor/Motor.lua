require "../ev3dev/class.lua"
require "../ev3dev/ev3dev.lua"

local EV3Device = require "../Device.lua"

local EV3Motor = class(EV3Device)

function EV3Motor:init(port, motorType)
	self.raw = Motor(port, {motorType})
	EV3Device.init(self)

	
end

function EV3Motor:positionToDegrees(poition)
	return (360/self.raw:countPerRot())*position
end

function EV3Motor:degreesToPosition(degrees)
	return (self.raw:countPerRot()/360)*degrees
end

return EV3Motor