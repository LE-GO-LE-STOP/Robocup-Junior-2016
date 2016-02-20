local class = require("class.lua")

local Device = class()

function Device:init(port)

end

return {
	--Constants
	INPUT_AUTO = nil,
	INPUT_1 = "in1",
	INPUT_2 = "in2",
	INPUT_3 = "in3",
	INPUT_4 = "in4",
	 
	OUTPUT_AUTO = nil,
	OUTPUT_A = "outA",
	OUTPUT_B = "outB",
	OUTPUT_C = "outC",
	OUTPUT_D = "outD",

	--Simple Devices
	Device = Device

	--Abstracted Devices

	--Sound and Display
}