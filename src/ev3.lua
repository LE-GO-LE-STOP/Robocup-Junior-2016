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

local function exists(path)
	local currentPath = lfs.currentdir()

	local isDir, err = lfs.chdir(path)

	local fileExists = true
	if err then
		fileExists = string.find(err, "Invalid argument")
	end

	lfs.chdir(currentPath)

	return fileExists, isDir
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
	local basePath = "/sys/class/"..dType.."/"
	local e = {exists(basePath)}
	if !e[1] then error("Type does not exist") end

	rawset(self.attributes, "_parent", self)

	local devices = listDir(basePath)
	self._path = nil
	for _, v in pairs(devices) do
		local devicePath = basePath..v.."/"

		local deviceIO = io.open(devicePath.."port_name", "r")
		local devicePort = deviceIO:read("*l")
		deviceIO:close()
		if not port or devicePort == port then
			--Found device on port requested
			--Set device info
			self._path = devicePath
			self._port = devicePort
			self._type = self.attributes["driver_name"]
			break
		end
	end
end

function Device:connected()
	return self._path ~= nil
end

--Attribute read/write
Device.attributes = {}
do
	local mt = {}

	mt.__index = function(attrTable, name)
		local self = attrTable._parent

		if not self:connected() then error("Device not connected") end

		local attributePath = self._path..name
		if not {exists(attributePath)}[1] then error("Attribute does not exist") end

		local readIO = io.open(attributePath, "r")
		local data = readIO:read("*a")
		readIO:close()

		return data
	end

	mt.__newindex = function(attrTable, name, value)
		local self = attrTable._parent

		if not self:connected() then error("Device not connected") end

		local attributePath = self._path..name
		if not {exists(attributePath)}[1] then error("Attribute does not exist") end

		local writeIO = io.open(attributePath, "w")
		writeIO:write(value)
		writeIO:close()
	end

	setmetatable(Device.attributes, mt)
end

function Device:type()
	return self._type
end

function Device:port()
	return self._port
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