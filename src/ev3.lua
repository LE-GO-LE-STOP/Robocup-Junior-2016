require "lfs"
local class = require("class.lua")

--Util functions
local function stringSplit(inputString)
	local output = {}
	for i in string.gmatch(inputString, "%S+") do
  		table.insert(output, i)
	end
	return output
end

local function sleep(time)
	local timeStart = os.clock()
	while os.clock() - timeStart <= time do end
end

local function listDir(dir)
	local output = {}
	local iterator, id = lfs.dir(dir)

	while true do
		local directory = iterator(id)
		if directory == nil then
			break
		else
			table.insert(output, directory)
		end
	end

	return output
end

--[[

Device:
The base class for all motors and sensors. Handles low level file system writes.

Parameters:
port - The port to look for. Constants provided for convenience.
dType - The type of device to search for. See /sys/class for types.

--]]
local Device = class()

function Device:init(port, dType)
	local basePath = "/sys/class/"..dType

end

--Attribute read/write
function Device:getAttribute(name)
	--Read attribute data as string
end

function Device:getAttributeList(name)

end

function Device:setAttribute(name, data)

end

return {
	--Utills
	sleep = sleep,

	--Constants
	OUT_A = "outA",
	OUT_B = "outB",
	OUT_C = "outC",
	OUT_D = "outD",

	IN_1 = "in1",
	IN_2 = "in2",
	IN_3 = "in3",
	IN_4 = "in4",

	NOCOLOUR = 0,
	BLACK = 1,
	BLUE = 2,
	GREEN = 3,
	YELLOW = 4,
	RED = 5,
	WHITE = 6,
	BROWN = 7,

	COLOUR = "COL-COLOR",
	REFLECT = "COL-REFLECT",
	AMBIENT = "COL-AMBIENT",

	PROXIMITY = "IR-PROX",
	BEACON = "IR-SEEK",
	REMOTE = "IR-REMOTE",

	CONTINUOS_CM = "US-DIST-CM",
	CONTINUOS_INCH = "US-DIST-IN",
	SINGLE_CM = "US-SI-CM",
	SINGLE_INCH = "US-SI-IN",
	LISTEN = "US-LISTEN",

	--Simple Devices
	Device = Device

	--Abstracted Devices

	--Sound and Display
}