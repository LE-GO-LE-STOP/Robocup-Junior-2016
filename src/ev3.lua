local lfs = require "lfs"
local class = require("class").class

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
		elseif directory ~= "." and directory ~= ".." then
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
		fileExists = string.find(err, "Not a directory")
	end

	lfs.chdir(currentPath)
	return {fileExists, isDir}
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
	if not exists(basePath)[1] then error("Type does not exist") end
	print(basePath)

	rawset(self.attributes, "_parent", self)

	local devices = listDir(basePath)
	local found = false
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

			found = true;
			break
		end
	end

	if not found then error("No device found") end
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
		if not exists(attributePath)[1] then error("Attribute '"..name.."' does not exist") end

		local readIO = io.open(attributePath, "r")
		local data = readIO:read("*a")
		readIO:close()

		return data
	end

	mt.__newindex = function(attrTable, name, value)
		local self = attrTable._parent

		if not self:connected() then error("Device not connected") end

		local attributePath = self._path..name
		if not exists(attributePath)[1] then error("Attribute '"..name.."' does not exist") end

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
	local basePath = "/sys/class/servo-motor/"

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

function Tank:on_for_rotations(leftPower, rightPower, rotations, brake, nonBlocking)
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

function Sensor:setMode(mode)
	if not self.modes[mode] then error(mode.." is not supported") end

	if self._mode ~= mode then
		self.attributes["mode"] = mode
		self._mode = mode
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

	self:setMode("TOUCH")
end

function Touch_Sensor:pressed()
	if self.attributes["value0"] == "true" then
		return true
	else
		return false
	end
end

--[[

Colour Sensor:
Used to control an EV3 colour sensor.

Parameters:
String port - The port to look for. Constants provided for convenience.

--]]

local Colour_Sensor = class(Sensor)
	
function Colour_Sensor:init(port)
	Sensor.init(self, port)
end

function Colour_Sensor:reflected()
	self:setMode("COL-REFLECT")
	return tonumber(self.attributes["value0"])
end

function Colour_Sensor:ambient()
	self:setMode("COL-AMBIENT")
	return tonumber(self.attributes["value0"])
end

function Colour_Sensor:colour()
	self:setMode("COL-COLOR")
	return tonumber(self.attributes["value0"])
end

local rgb_constant = 1020/256 --Used to convert the raw rgb value (0 - 1020) to the usual rgb range (0 - 255)
function Colour_Sensor:rgb()
	self:setMode("RGB-RAW")

	local r = math.floor(tonumber(self.attributes["value0"]) / rgb_constant)
	local g = math.floor(tonumber(self.attributes["value1"]) / rgb_constant)
	local b = math.floor(tonumber(self.attributes["value2"]) / rgb_constant)

	return {r, g, b}
end

--[[

Ultrasonic Sensor:
Used to control a NXT/EV3 ultrasonic sensor.

Parameters:
String port - The port to look for. Constants provided for convenience.

--]]

local Ultrasonic_Sensor = class(Sensor)

function Ultrasonic_Sensor:init(port)
	Sensor.init(self, port)
end

function Ultrasonic_Sensor:distance(mode)
	self:setMode(mode)
	return tonumber(self.attributes["value0"]) / 10
end

function Ultrasonic_Sensor:nearby()
	self:setMode("US-LISTEN")

	if self.attributes["value0"] == "true" then
		return true
	else
		return false
	end
end

--[[

Gyro Sensor:
Used to control an EV3 gyro sensor.

Parameters:
String port - The port to look for. Constants provided for convenience.

--]]

local Gyro_Sensor = class(Sensor)

function Gyro_Sensor:init(port)
	Sensor.init(self, port)
end

function Gyro_Sensor:angle()
	self:setMode("GYRO-ANG")
	return tonumber(self.attributes["value0"])
end

function Gyro_Sensor:rate()
	self:setMode("GYRO-RATE")
	return tonumber(self.attributes["value0"])
end

--[[

Infrared Sensor:
Used to control an EV3 gyro sensor.

Parameters:
String port - The port to look for. Constants provided for convenience.

--]]

local Infrared_Sensor = class(Sensor)

function Infrared_Sensor:init(port)
	Sensor.init(self, port)
end

function Infrared_Sensor:proximity()
	self:setMode("IR-PROX")
	return tonumber(self.attributes["value0"])
end

function Infrared_Sensor:seek(channel)
	if type(channel) ~= "number" or channel < 1 or channel > 4 then error("Invalid channel") end

	self:setMode("IR-SEEK")

	local valueOffset = (channel-1)*2
	local heading = tonumber(self.attributes["value"..tostring(valueOffset)])
	local distance = tonumber(self.attributes["value"..tostring(valueOffset + 1)])
	local detected = true

	if heading == 0 and distance == -128 then
		detected = false
	end

	return {detected, heading, distance}
end

local remote_buttons = {
	["262"] = {red={up=false,down=false},blue={up=false,down=false}},
	["384"] = {red={up=false,down=false},blue={up=false,down=false}},
	["287"] = {red={up=true,down=false},blue={up=false,down=false}},
	["300"] = {red={up=false,down=true},blue={up=false,down=false}},
	["309"] = {red={up=true,down=true},blue={up=false,down=false}},
	["330"] = {red={up=false,down=false},blue={up=true,down=false}},
	["339"] = {red={up=true,down=false},blue={up=true,down=false}},
	["352"] = {red={up=false,down=true},blue={up=true,down=false}},
	["377"] = {red={up=true,down=true},blue={up=true,down=false}},
	["390"] = {red={up=false,down=false},blue={up=false,down=true}},
	["415"] = {red={up=true,down=false},blue={up=false,down=true}},
	["428"] = {red={up=false,down=true},blue={up=false,down=true}},
	["437"] = {red={up=true,down=true},blue={up=false,down=true}},
	["458"] = {red={up=false,down=false},blue={up=true,down=true}},
	["467"] = {red={up=true,down=false},blue={up=true,down=true}},
	["480"] = {red={up=false,down=true},blue={up=true,down=true}},
	["505"] = {red={up=true,down=true},blue={up=true,down=true}},
}
function Infrared_Sensor:remote()
	return remote_buttons[self.attributes["value0"]]
end

--[[

Sound Sensor:
Used to control a NXT sound sensor.

Parameters:
String port - The port to look for. Constants provided for convenience.

--]]

local Sound_Sensor = class(Sensor)

function Sound_Sensor:init(port)
	Sensor.init(self, port)
end

function Sound_Sensor:pressure()
	self:setMode("DB")
	return tonumber(self.attributes["value0"]) / 10
end

function Sound_Sensor:pressure_low()
	self:setMode("DBA")
	return tonumber(self.attributes["value0"]) / 10
end

--[[

Light Sensor:
Used to control a NXT light sensor.

Parameters:
String port - The port to look for. Constants provided for convenience.

--]]

local Light_Sensor = class(Sensor)

function Light_Sensor:init(port)
	Sensor.init(self, port)
end

function Light_Sensor:reflected()
	self:setMode("REFLECT")
	return tonumber(self.attributes["value0"]) / 10
end

function Light_Sensor:ambient()
	self:setMode("AMBIENT")
	return tonumber(self.attributes["value0"]) / 10
end

--[[

Power Suppy:
Get information on the power state.

Parameters:


--]]

local PowerSupply = class(Device)

function PowerSupply:init()
	--Command discovery code is ommited, because power supplies do not have the commands attribute
	local basePath = "/sys/class/power_supply/"

	rawset(self.attributes, "_parent", self)

	local devicePath = basePath..listDir(basePath)[0].."/"

	--Set device info
	self._path = devicePath
	self.port = nil
	self._type = self.attributes["driver_name"]
end

function PowerSupply:current()
	return tonumber(self.attributes["measured_current"]) / 1000000
end

function PowerSupply:voltage()
	return tonumber(self.attributes["measured_voltage"]) / 1000000
end

return {
	--Utills
	sleep = sleep,

	--Constants
	OUTPUT_AUTO = nil,
	OUTPUT_A = "outA",
	OUTPUT_B = "outB",
	OUTPUT_C = "outC",
	OUTPUT_D = "outD",

	INPUT_AUTO = nil,
	INPUT_1 = "in1",
	INPUT_2 = "in2",
	INPUT_3 = "in3",
	INPUT_4 = "in4",

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
	RGB = "RGB-RAW",

	CONTINUOUS_CM = "US-DIST-CM",
	CONTINUOUS_INCH = "US-DIST-IN",
	SINGLE_CM = "US-SI-CM",
	SINGLE_INCH = "US-SI-IN",
	LISTEN = "US-LISTEN",

	ANGLE = "GYRO-ANG",
	RATE = "GYRO-RATE",

	PROXIMITY = "IR-PROX",
	BEACON = "IR-SEEK",
	REMOTE = "IR-REMOTE",

	SOUND_PRESSURE = "DB",
	SOUND_PRESSURE_LOW = "DBA",

	NXT_REFLECT = "REFLECT",
	NXT_AMBIENT = "AMBIENT",

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
	Touch_Sensor = Touch_Sensor,
	Colour_Sensor = Colour_Sensor,
	Ultrasonic_Sensor = Ultrasonic_Sensor,
	Gyro_Sensor = Gyro_Sensor,
	Infrared_Sensor = Infrared_Sensor,
	Sound_Sensor = Sound_Sensor,
	Light_Sensor = Light_Sensor,

	--Sound

	--Power
	PowerSupply = PowerSupply

	--LED

	--Buttons
}