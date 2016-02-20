@@ -1,385 +1,7 @@
require 'ev3dev'
local ev3 = {
	["Device"] = require "Device.lua",

function sleep(time)
	local timeStart = os.clock()
	while os.clock() - timeStart <= time end
end
	["Motor"] = require "Motor/Motor.lua"
}

function isConnected(device)
	return device.raw:connected()
end

function positionToDegrees(device, poition)
	return (360/device.raw:countPerRot())*position
end

function degreesToPosition(device, degrees)
	return (device.raw:countPerRot()/360)*degrees
end

local function notSupported(device, command, deviceType)
	error(command.. " is not supported on this "..deviceType or "device".." ("..self.type.." on port "..self.port..")")
end

local ev3 = {}

--Motor
ev3.Motor = class()

function ev3.Motor:init(port, motorType)
	self.raw = Motor(port, {motorType})

	self.port = self.raw._port
	self.type = self.raw._type
	self.currentStopCommand = ""

	--need to implement
	self.commands = {}

	self.stop_commands = {}
end

function ev3.Motor:command(command)
	if not isConnected(self) then
		error("The motor at port "..device.port.." is not connected")
	end

	if self.commands[command] then
		self.raw:setCommand(command)
	else
		notSupported(self, command, "motor")
	end

	return true
end

function ev3.newMotor:stop_command(command, default)
	if self.stop_commands[command] or command == nil then
		if (command or default) ~= self.currentStopCommand then
			self.raw:setStopCommand(command or default)
			self.currentStopCommand = command or mode
		end
	else
		notSupported(self, command, "motor")
	end

	return true
end

function ev3.newMotor:stop(brake)
	self:stop_command(brake, "brake")
	self.raw:setCommand("stop")
	return true
end

function ev3.newMotor:on(power)
	self.raw:setDutyCycleSP(power)
	self:command("run-forever")
	return true
end

function ev3.newMotor:on_for_seconds(power, seconds, brake, nonBlocking)
	self.motor:setDutyCycleSP(power)

	if nonBlocking then
		self:stop_command(brake, "brake")
		self.raw:setTimeSP(seconds*1000)
		self:command("run-timed")
	else
		self:on()
		sleep(seconds)
		self:off(brake)
	end

	return true
end

function ev3.newMotor:on_for_degrees(power, degrees, brake, nonBlocking)
	self.raw:setDutyCycleSP(power)

	if nonBlocking then
		self:stop_command(brake, "brake")
		self.raw:setPositionSP(degreesToPosition(degrees))
		self:command("run-to-rel-pos")
	else
		local targetPosition = self.raw:position() + degreesToPosition(self, degrees)
		self:on()

		if degrees >= 0 then
			while self.raw:position() < targetPosition do end
		else
			while self.raw:position() > targetPosition do end
		end

		self:off()
	end

	return true
end

function ev3.newMotor:on_for_rotations(power, rotations, brake, nonBlocking)
	return self:on_for_degrees(power, rotations*360, brake, nonBlocking)
end

function ev3.newMotor:reset()
	tryCommand(self, "reset")
	return true
end

--Large motor
function ev3.newLargeMotor(port)
	return ev3.newMotor(port, Motor.Large)
end

--Medium motor
function ev3.newMediumMotor(port)
	return ev3.newMotor(port, Motor.Medium)
end

--Tank
ev3.newTank = class()

function ev3.newTank:init(leftMotorPort, rightMotorPort)
	self.leftMotor = ev3.newMotor(leftMotorPort)
	self.rightMotor = ev3.newMotor(rightMotorPort)
end

function ev3.newTank:off(self, brake)
	self.leftMotor:off(brake)
	self.rightMotor:off(brake)
	return true
end

function ev3.newTank:on(leftPower, rightPower)
	self.leftMotor:on(leftPower)
	self.rightMotor:on(rightPower)
	return true
end

function ev3.newTank:on_for_seconds(leftPower, rightPower, seconds, brake, nonBlocking)
	self.leftMotor:on_for_seconds(leftPower, seconds, brake, true)
	self.rightMotor:on_for_seconds(rightPower, seconds, brake, nonBlocking)
	return true
end

function ev3.newTank:on_for_degrees(leftPower, rightPower, degrees, brake, nonBlocking)
	self.leftMotor:on_for_degrees(leftPower, degrees, brake, true)
	self.rightMotor:on_for_degrees(rightPower, degrees, brake, nonBlocking)
	return true
end

function ev3.newTank:on_for_rotations(leftPower, rightPower, rotations, brake, nonBlocking)
	self.leftMotor:on_for_rotations(leftPower, rotations, brake, true)
	self.rightMotor:on_for_rotations(rightPower, rotations, brake, nonBlocking)
	return true
end

function ev3.newTank:turn(power, direction, brake, nonBlocking)
	-- -90 to turn left, 90 to turn right
	return self:on_for_degrees(power, -power, direction/2, brake, nonBlocking)
end

function ev3.newTank:turnLeft(power, brake, nonBlocking)
	return self:turn(power, -90, brake, nonBlocking)
end

function ev3.newTank:turnRight(power, brake, nonBlocking)
	return self:turn(power, 90, brake, nonBlocking)
end

--Generic sensor
ev3.newSensor = class()

function ev3.newSensor:init(port, sensorType)
	self.raw = Sensor(port, {sensorType})

	self.port = self.raw._port
	self.type = self.ray._type
	self.currentMode = ""

	--need to implement
	self.commands = {}

	self.modes = {}
end

function ev3.newSensor:command(command)
	if not isConnected(self) then
		error("The sensor at port "..device.port.." is not connected")
	end

	if self.commands[command] then
		self.raw:setCommand(command)
	else
		notSupported(self, command, "sensor")
	end

	return true
end

function ev3.newSensor:mode(mode, overide)
	if self.modes[mode] then
		if mode ~= self.currentMode or overide then
			self.raw:setStopCommand(command)
			self.currentMode = mode
		end
	else
		notSupported(self, mode, "sensor")
	end
end

--EV3 colour sensor
ev3.newColourSensor = class()

NOCOLOUR = 0
BLACK = 1
BLUE = 2
GREEN = 3
YELLOW = 4
RED = 5
WHITE = 6
BROWN = 7

function ev3.newColourSensor:init(port)
	self.sensor = ev3.newSensor(port, Sensor.EV3Color)
end

function ev3.newColourSensor:colour()
	self.sensor:mode("COL-COLOR")
	return self.sensor.raw:value(0)
end

function ev3.newColourSensor:reflect()
	self.sensor:mode("COL-REFLECT")
	return self.sensor.raw:value(0)
end

function ev3.newColourSensor:ambient()
	self.sensor:mode("COL-AMBIENT")
	return self.sensor.raw:value(0)
end

--EV3 infrared sensor
ev3.newInfraredSensor = class()

function ev3.newInfraredSensor:init(port)
	self.sensor = ev3.newSensor(port, Sensor.EV3Infrared)
end

function ev3.newInfraredSensor:proximity()
	self.sensor:mode("IR-PROX")
	return self.sensor.raw:value(0)
end

function ev3.newInfraredSensor:beacon(channel)
	self.sensor:mode("IR-SEEK")

	local valueOffset = (channel-1)*2
	local heading = self.sensor.raw:value(valueOffset)
	local distance = self.sensor.raw:value(valueOffset+1)
	local detected = true

	if heading == 0 and distance == -128 then
		detected = false
	end

	return {detected, heading, distance}
end

function ev3.newInfraredSensor:remote(channel)
	self.sensor:mode("IR-REMOTE")
	return self.sensor.raw:value(channel-1)
end

--EV3 touch sensor
ev3.newTouchSensor = class()

function ev3.newTouchSensor:init(port)
	self.sensor = ev3.newSensor(port, Sensor.EV3Touch)
	self.sensor:mode("TOUCH")
end

function ev3.newTouchSensor:pressed()
	if self.sensor.raw:value(0) == 0 then
		return false
	else
		return true
	end
end

--EV3 ultrasonic sensor
ev3.newUltrasonicSensor = class()

CM = false
INCHES = true

function ev3.newUltrasonicSensor:init(port)
	self.sensor = ev3.newSensor(port, Sensor.EV3Ultrasonic)
end

function ev3.newUltrasonicSensor:distance(units, continuos)
	if units then
		if continuos then
			self.sensor:mode("US-DIST-IN")
		else
			self.sensor:mode("US-SI-IN", true)
		end
	else
		if continuos then
			self.sensor:mode("US-DIST-CM")
		else
			self.sensor:mode("US-SI-SM", true)
		end
	end

	return self.sensor.raw:value(0)/10
end

function ev3.newUltrasonicSensor:listen()
	self.sensor:mode("US-LISTEN")

	if self.sensor.raw:value(0) == 0 then
		return false
	else
		return true
	end
end

--Buttons
ev3.buttons = {}

function ev3.buttons.get()
	local rawData = io.popen("python buttons.py")
	local output = {}
	for i in rawData:lines() do
		local data = stringSplit(i)
		local state = false
		if data[2] == "pressed" then
			state = true
		end
		output[data[1]] = state
	end
	return output
end

function ev3.buttons.waitPress(button)
	while not ev3.buttons.get()[button] do end
	return true
end

function ev3.buttons.waitRelease(button)
	while ev3.buttons.get()[button] do end
	return true
end

function ev3.buttons.waitToggle(button)
	ev3.buttons.waitPress(button)
	ev3.buttons.waitRelease(button)
	return true
end

--Sound
--See ev3dev.lua
ev3.sound = Sound

return ev3;
\ No newline at end of file
return ev3
\ No newline at end of file