local function sleep(time)
	local timeStart = os.clock()
	while os.clock() - timeStart <= time end
end

local ev3 = {
	["sleep"] = sleep,

	["Device"] = require "Device.lua",

	["Motor"] = require "Motor/Motor.lua"
}

return ev3