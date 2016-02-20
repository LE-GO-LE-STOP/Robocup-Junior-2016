require "lfs"
local class = require("class.lua")

--Util functions
local function stringSplit(inputstr, sep)
	--http://stackoverflow.com/a/7615129/3404868
    if sep == nil then
            sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            t[i] = str
            i = i + 1
    end
    return t
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
	if not {exists(basePath)}[1] then error("Type does not exist") end

	rawset(self.attributes, "_parent", self)

	local devices = listDir(basePath)
	for _, v in pairs(devices) do
		local devicePath = basePath..v.."/"

		local deviceIO = io.open(devicePath.."address", "r")
		local devicePort = deviceIO:read("*l")
		deviceIO:close()
		if not port or devicePort == port then
			--Found device on port requested
			--Set device info
			self._path = devicePath
			self._port = devicePort
			self._type = self.attributes["driver_name"]

			self.commands = {}
			for _, v in pairs(stringSplit(self.attributes["commands"])) do
				self.commands[v] = true
			end

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

--[[

Motor:
Used to control official LEGO motors.

Parameters:
port - The port to look for. Constants provided for convenience.

--]]

local Motor = class(Device)

function Motor:init(port)
	Device.init(self, port, "tacho-motor")

	self.stop_commands = {}
	for _, v in pairs(stringSplit(self.attributes["stop_commands"])) do
		self.stop_commands[v] = true
	end
end

function 

function Motor:positionToDegrees(position)
	return (360/self.attributes["count_per_rot"])*position
end

function Motor:degreesToPosition(degrees)
	return (self.attributes["count_per_rot"]/360)*degrees
end

function Motor:setBrake(brake)
	if brake then
		if not self.stop_commands[brake] then error(brake.." is not supported on this motor") end

		self.attributes["stop_command"] = brake
	end
end

function Motor:off(brake)
	self:setBrake(brake)
	self.attributes["command"] = "stop"
end

function Motor:on(power)
	if type(power) ~= "number" then error("power is not a number!") end

	if self.commands["run-forever"] then
		self.attributes["duty_cycle_sp"] = power
		self.attributes["command"] = "run-forever"
	else
		error("run-forever is not supported on this motor")
	end
end

function Motor:on_for_seconds(power, seconds, brake, nonBlocking)
	if type(seconds) ~= "number" then error("seconds is not a number!") end

	if type(power) ~= "number" then error("power is not a number!") end
	self.attributes["duty_cycle_sp"] = power

	if nonBlocking then
		if self.commands["run-timed"] then
			self:setBrake(brake)

			self.attributes["time_sp"] = seconds*1000
			self.attributes["command"] = "run-timed"
		else
			error("run-timed is not supported on this motor")
		end
	else
		self:on(power)
		sleep(seconds)
		self:off(brake)
	end
end

function Motor:on_for_degrees(power, degrees, brake, nonBlocking)
	if type(degrees) ~= "number" then error("degrees is not a number!") end
	local position = self:degreesToPosition(degrees)

	if type(power) ~= "number" then error("power is not a number!") end
	self.attributes["duty_cycle_sp"] = power

	if nonBlocking then
		if self.commands["run-to-rel-pos"] then
			self:setBrake(brake)

			self.attributes["position_sp"] = position
			self.attributes["command"] = "run-to-rel-pos"
		else
			error("run-to-rel-pos is not supported on this motor")
		end
	else
		local targetPosition = tonumber(self.attributes["position"]) + position

		self:on(power)

		if degrees >= 0 then
			while tonumber(self.attributes["position"]) < targetPosition do end
		else
			while tonumber(self.attributes["position"]) > targetPosition do end
		end

		self:off(brake)
	end
end

function Motor:on_for_rotations(power, rotations, brake, nonBlocking)
	self:on_for_degrees(power, rotations*360, brake, nonBlocking)
end

function Motor:reset()
	if self.commands["reset"] then
		self.attributes["command"] = "reset"
	else
		error("reset is not supported on this motor")
	end
end

--[[

DC Motor:
Used to control a generic DC Motor.

Parameters;
port - The port to look for. Constants provided for convenience.

--]]

local DC_Motor = class(Device)

function DC_Motor:init(port)
	Device.init(self, port, "dc-motor")

	self.stop_commands = {}
	for _, v in pairs(stringSplit(self.attributes["stop_commands"])) do
		self.stop_commands[v] = true
	end
end

--[[

Server Motor:
Used to control a generic servo motor.

Parameters;
port - The port to look for. Constants provided for convenience.

--]]

local Servo_Motor = class(Device)

function Servo_Motor:init(port)
	--Command discovery code is ommited, because servo motors do not have the commands attribute
	local basePath = "/sys/class/servo-motor"

	rawset(self.attributes, "_parent", self)

	local devices = listDir(basePath)
	for _, v in pairs(devices) do
		local devicePath = basePath..v.."/"

		local deviceIO = io.open(devicePath.."address", "r")
		local devicePort = deviceIO:read("*l")
		deviceIO:close()
		if not port or devicePort == port then
			--Found device on port requested
			--Set device info
			self._path = devicePath
			self._port = devicePort
			self._type = self.attributes["driver_name"]

			self.commands = {run = true, float = true}

			break
		end
	end
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

	CONTINUOUS_CM = "US-DIST-CM",
	CONTINUOUS_INCH = "US-DIST-IN",
	SINGLE_CM = "US-SI-CM",
	SINGLE_INCH = "US-SI-IN",
	LISTEN = "US-LISTEN",

	--Generic Device
	Device = Device,

	--Motors
	Motor = Motor,
	DC_Motor = DC_Motor,
	Servo_Motor = Servo_Motor

	--Motor Controller

	--Generic Sensor

	--Sensors

	--Sound and Display

	--Power

	--LED
}