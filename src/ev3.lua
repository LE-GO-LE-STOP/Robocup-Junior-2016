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
String port - The port to look for. Constants provided for convenience.
String dType - The type of device to search for. See /sys/class for types.

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
String port - The port to look for. Constants provided for convenience.

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
String port - The port to look for. Constants provided for convenience.

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
String port - The port to look for. Constants provided for convenience.

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

--[[

Tank:
Provides easy tank-like controls for LEGO motors.

Parameters;
Motor leftMotor - The left motor in a tank
Motor rightMotor - The right motor in a tank

--]]

local Tank = class()

function Tank:init(leftMotor, rightMotor)
	if not leftMotor:is_a(Motor) or not rightMotor:is_a(Motor) then error("Invalid motor provided") end

	self.leftMotor = leftMotor
	self.rightMotor = rightMotor
end

function Tank:off(brake)
	self.leftMotor:off(brake)
	self.rightMotor:off(brake)
end

function Tank:on(leftPower, rightPower)
	self.leftMotor:on(leftPower)
	self.rightMotor:off(rightPower)
end

function Tank:on_for_seconds(leftPower, rightPower, seconds, brake, nonBlocking)
	self.leftMotor:on_for_seconds(leftPower, seconds, brake, true)
	self.rightMotor:on_for_seconds(rightPower, seconds, brake, nonBlocking)
end

function Tank:on_for_degrees(leftPower, rightPower, degrees, brake, nonBlocking)
	self.leftMotor:on_for_degrees(leftPower, degrees, brake, true)
	self.rightMotor:on_for_degrees(rightPower, degrees, brake, nonBlocking)
end

function Tank:on_for_rotations(leftPower, rightPower. rotations, brake, nonBlocking)
	local degrees = rotations*360
	self.leftMotor:on_for_degrees(leftPower, degrees, brake, true)
	self.rightMotor:on_for_degrees(rightPower, degrees, brake, nonBlocking)
end

function Tank:turn(power, direction, brake, nonBlocking)
	--direction from -90 to face left to 90 to face right
	self:on_for_degrees(power, -power, direction/2, brake, nonBlocking)
end

function Tank:turnLeft(power, brake, nonBlocking)
	self:turn(power, -90, brake, nonBlocking)
end

function Tank:turnRight(power, brake, nonBlocking)
	self:turn(power, 90, brake, nonBlocking)
end

--[[

Sensor:
The base class for all sensors.

Parameters:
String port - The port to look for. Constants provided for convenience.

--]]

local Sensor = class(Device)

function Sensor:init(port)
	Device.init(self, port, "sensor")

	self.modes = {}
	for _, v in pairs(stringSplit(self.attributes["modes"])) do
		self.modes[v] = true
	end
end

--[[

I2C Sensor:
Used to control a generic I2C sensor

Parameters:
String port - The port to look for. Constants provided for convenience.

--]]

local I2C_Sensor = class(Sensor)

function I2C_Sensor:init(port)
	Sensor.init(self, port)
end

--[[

Touch Sensor:
Used to control a NXT/EV3 touch sensor.

Parameters:
String port - The port to look for. Constants provided for convenience.

--]]

local Touch_Sensor = class(Sensor)

function Touch_Sensor:init(port)
	Sensor.init(self, port)

	self.attributes["mode"] = "TOUCH"
end

function Touch_Sensor:pressed()
	if self.attributes["is_pressed"] == "true" then
		return true
	else
		return false
	end
end

return {
	--Utills
	sleep = sleep,

	--Constants
	OUT_ANY = nil,
	OUT_A = "outA",
	OUT_B = "outB",
	OUT_C = "outC",
	OUT_D = "outD",

	IN_ANY = nil,
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
	Servo_Motor = Servo_Motor,

	--Tank
	Tank = Tank,

	--Generic Sensor
	Sensor = Sensor,

	--Sensors
	I2C_Sensor = I2C_Sensor,
	Touch_Sensor = Touch_Sensor

	--Sound and Display

	--Power

	--LED
}