require 'lfs'

ev3 = {}

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

local function setValue(path, value)
	local setValueIO = io.open(path, "w")
	setValueIO:write(value)
	setValueIO:close()
end

local function getValue(path, value)
	local getValueIO = io.open(device.raw.path.."duty_cycle", "r")
	local getValueResult = getValueIO:read("*a")
	getValueIO:close()
	return getValueResult
end

local function setBrake(device, brake)
	if brake == "coast" then
		if self.stop_commands["coast"] then
			self.raw:stop_command("coast")
		else
			return nil, "coast is not supported on this motor"
		end
	elseif brake == "hold" then
		if self.stop_commands["hold"] then
			self.raw:stop_command("hold")
		else
			return nil, "hold is not supported on this motor"
		end
	elseif brake == "brake" or brake == nil then
		if self.stop_commands["brake"] then
			self.raw:stop_command("brake")
		else
			return nil, "break is not supported on this motor"
		end
	else
		return nil, brake.." is an invalid stop command"
	end
	return true
end

local function positionToDegrees(device, poition)
	return (360/device.raw.count_per_rot)*position
end

local function degreesToPosition(device, degrees)
	return (device.raw.count_per_rot/360)*degrees
end

local function getDevices(type)
	return listDir("/sys/class/"..type)
end

--Constants
OUT_A = "outA"
OUT_B = "outB"
OUT_C = "outC"
OUT_D = "outD"

IN_1 = "in1"
IN_2 = "in2"
IN_3 = "in3"
IN_4 = "in4"

NOCOLOUR = 0
BLACK = 1
BLUE = 2
GREEN = 3
YELLOW = 4
RED = 5
WHITE = 6
BROWN = 7

COLOUR = "COL-COLOR"
REFLECT = "COL-REFLECT"
AMBIENT = "COL-AMBIENT"

PROXIMITY = "IR-PROX"
BEACON = "IR-SEEK"
REMOTE = "IR-REMOTE"

CONTINUOS_CM = "US-DIST-CM"
CONTINUOS_INCH = "US-DIST-IN"
SINGLE_CM = "US-SI-CM"
SINGLE_INCH = "US-SI-IN"
LISTEN = "US-LISTEN"

--Motors
ev3.newMotor = function(port)
	local devices = getDevices("tacho-motor")
	local device = {["raw"] = {}}

	for k, v in pairs(devices) do
		local portIO = io.open("/sys/class/tacho-motor/"..v.."/port_name", "r")
		local portName = portIO:read("*a")
		if (portName == port) or port == nil then
			device.raw.path = "/sys/class/tacho-motor/"..v.."/"
			device.raw.port_name = portName
			break
		end
		portIO:close()
	end

	if not device.raw.path then
		return nil, "no motor on "..port
	end

	--The default API
	device.raw.command = function(self, command, value)
		setValue(self.raw.path.."command", value)
	end

	device.raw.commands = stringSplit(getValue(device.raw.path.."commands"))

	device.raw.count_per_rot = getValue(device.raw.path.."count_per_rot")

	device.raw.driver_name = getValue(device.raw.path.."driver_name")

	device.raw.duty_cycle = function(self)
		return getValue(self.raw.path.."duty_cycle")
	end

	device.raw.duty_cycle_sp = function(self, value)
		if value then
			setValue(self.raw.path.."duty_cycle", value)
		else
			return getValue(self.raw.path.."duty_cycle_sp")
		end
	end

	device.raw.encoder_polarity = function(self, value)
		if value then
			setValue(self.raw.path.."encoder_polarity", value)
		else
			return getValue(self.raw.path.."encoder_polarity")
		end
	end

	device.raw.polarity = function(self, value)
		if value then
			setValue(self.raw.path.."polarity", value)
		else
			return getValue(self.raw.path.."polarity")
		end
	end

	--port_name is defined above in the device finding loop

	device.raw.position = function(self, value)
		if value then
			setValue(self.raw.path.."position", value)
		else
			return getValue(self.raw.path.."position")
		end
	end

	device.raw.hold_pid_Kd = function(self, value)
		if value then
			setValue(self.raw.path.."hold_pid_Kd", value)
		else
			return getValue(self.raw.path.."hold_pid_Kd")
		end
	end

	device.raw.hold_pid_Ki = function(self, value)
		if value then
			setValue(self.raw.path.."hold_pid_Ki", value)
		else
			return getValue(self.raw.path.."hold_pid_Ki")
		end
	end

	device.raw.hold_pid_Kp = function(self, value)
		if value then
			setValue(self.raw.path.."hold_pid_Kp", value)
		else
			return getValue(self.raw.path.."hold_pid_Kp")
		end
	end

	device.raw.position_sp = function(self, value)
		if value then
			setValue(self.raw.path.."position_sp", value)
		else
			return getValue(self.raw.path.."position_sp")
		end
	end

	device.raw.speed_pid_Kp = function(self, value)
		if value then
			setValue(self.raw.path.."speed_pid_Kp", value)
		else
			return getValue(self.raw.path.."speed_pid_Kp")
		end
	end

	device.raw.speed = function(self)
		return getValue(self.raw.path.."speed")
	end

	device.raw.speed_sp = function(self, value)
		if value then
			setValue(self.raw.path.."speed_sp", value)
		else
			return getValue(self.raw.path.."speed_sp")
		end
	end

	device.raw.ramp_up_sp = function(self, value)
		if value then
			setValue(self.raw.path.."ramp_up_sp", value)
		else
			return getValue(self.raw.path.."ramp_up_sp")
		end
	end

	device.raw.ramp_down_sp = function(self, value)
		if value then
			setValue(self.raw.path.."ramp_down_sp", value)
		else
			return getValue(self.raw.path.."ramp_down_sp")
		end
	end

	device.raw.speed_regulation = function(self, value)
		if value then
			setValue(self.raw.path.."speed_regulation", value)
		else
			return getValue(self.raw.path.."speed_regulation")
		end
	end

	device.raw.speed_pid_Kd = function(self, value)
		if value then
			setValue(self.raw.path.."speed_pid_Kd", value)
		else
			return getValue(self.raw.path.."speed_pid_Kd")
		end
	end

	device.raw.speed_pid_Ki = function(self, value)
		if value then
			setValue(self.raw.path.."speed_pid_Ki", value)
		else
			return getValue(self.raw.path.."speed_pid_Ki")
		end
	end

	device.raw.speed_pid_Kp = function(self, value)
		if value then
			setValue(self.raw.path.."speed_pid_Kp", value)
		else
			return getValue(self.raw.path.."speed_pid_Kp")
		end
	end

	device.raw.state = function(self, value)
		return stringSplit(getValue(self.raw.path.."state"))
	end

	device.raw.stop_command = function(self, value)
		if value then
			setValue(self.raw.path.."stop_command", value)
		else
			return getValue(self.raw.path.."stop_command")
		end
	end

	device.raw.stop_commands = stringSplit(getValue(device.raw.path.."stop_commands"))

	device.raw.time_sp = function(self, value)
		if value then
			setValue(self.raw.path.."time_sp", value)
		else
			return getValue(self.raw.path.."time_sp")
		end
	end

	--Start abstraction layer
	device.commands = {}
	for k, v in pairs(device.raw.commands) do
		device.commands[v] = true
	end

	device.stop_commands = {}
	for k, v in pairs(device.raw.stop_commands) do
		device.stop_commands[v] = true
	end

	device.off = function(self, brake)
		local result, err = setBrake(self, brake)
		if not result then return nil, err end

		self.raw:command("stop")
		return true
	end

	device.on = function(self, power)
		if self.commands["run-forever"] then
			self.raw:duty_cycle_sp(tonumber(power))
			self.raw:command("run-forever")
		else
			return nil, "run-forever is not supported on this motor"
		end
		return true
	end

	device.on_for_seconds = function(self, power, seconds, brake, nonBlocking)
		self.raw:duty_cycle_sp(tonumber(power))

		if nonBlocking then
			if self.commands["run-timed"] then
				local result, err = setBrake(self, brake)
				if not result then return nil, err end

				self.raw:time_sp(tonumber(seconds)*1000)
				self.raw:command("run-timed")
			else
				return nil, "run-timed is not supported on this motor"
			end
		else
			local result, err = self:on()
			if not result then return nil, err end
			sleep(seconds)
			local result, err = self:off(brake)
			if not result then return nil, err end
		end
		return true
	end

	device.on_for_degrees = function(self, power, degrees, brake, nonBlocking)
		self.raw:duty_cycle_sp(tonumber(power))

		if nonBlocking then
			if self.commands["run-to-rel-pos"] then
				local result, err = setBrake(self, brake)
				if not result then return nil, err end

				self.raw:position_sp(degreesToPosition(degrees))
				self.raw:command("run-to-rel-pos")
			else
				return nil, "run-to-rel-pos is not supported on this motor"
			end
		else
			local targetPosition = self.raw:position() + degreesToPosition(self, degrees)
			local result, err = self:on()
			if not result then return nil, err end

			if degrees => 0 then
				while self.raw:position() < targetPosition then end
			else
				while self.raw:position() > targetPosition then end
			end

			local result, err = self:off()
			if not result then return nil, err end
		end
		return true
	end

	device.on_for_rotations = function(self, power, rotations, brake, nonBlocking)
		return self:on_for_degrees(power, rotations*360, brake, nonBlocking)
	end

	device.reset = function(self)
		self.raw:command("reset")
		return true
	end

	return device
end

ev3.newTank = function(leftMotor, rightMotor)
	local device = {["leftMotor"] = leftMotor, ["rightMotor"] = rightMotor}

	device.off = function(self, brake)
		local result, err = self.leftMotor:off(brake)
		if not result then return nil, err end

		local result, err = self.rightMotor:off(brake)
		if not result then return nil, err end

		return true
	end

	device.on = function(self, leftPower, rightPower)
		local result, err = self.leftMotor:on(leftPower)
		if not result then return nil, err end

		local result, err = self.rightMotor:on(rightPower)
		if not result then return nil, err end

		return true
	end

	device.on_for_seconds = function(self, leftPower, rightPower, seconds, brake, nonBlocking)
		local result, err = self.leftMotor:on_for_seconds(leftPower, seconds, brake, true)
		if not result then return nil, err end
		
		local result, err = self.rightMotor:on_for_seconds(rightPower, seconds, brake, nonBlocking)
		if not result then return nil, err end

		return true
	end

	device.on_for_degrees = function(self, leftPower, rightPower, degrees, brake, nonBlocking)
		local result, err = self.leftMotor:on_for_degrees(leftPower, seconds, brake, true)
		if not result then return nil, err end
		
		local result, err = self.rightMotor:on_for_degrees(rightPower, seconds, brake, nonBlocking)
		if not result then return nil, err end

		return true
	end

	device.on_for_rotations = function(self, leftPower, rightPower, rotations, brake, nonBlocking)
		local result, err = self.leftMotor:on_for_rotations(leftPower, seconds, brake, true)
		if not result then return nil, err end
		
		local result, err = self.rightMotor:on_for_rotations(rightPower, seconds, brake, nonBlocking)
		if not result then return nil, err end

		return true
	end

	device.turn = function(self, power, direction, brake, nonBlocking)
		--direction from -90 to face left to 90 to face right
		return self:on_for_degrees(power, -power, direction/2, brake, nonBlocking)
	end

	device.turnLeft = function(self, power, brake, nonBlocking)
		return self:turn(power, -90, brake, nonBlocking)
	end

	device.turnRight = function(self, power, nonBlocking)
		return self:turn(power, 90, brake, nonBlocking)
	end

	device.reset = function(self)
		self.leftMotor:reset()
		self.rightMotor:reset()

		return true
	end

	return device
end

--Sensors
ev3.newSensor = function(port)
	local devices = getDevices("sensor")
	local device = {["raw"] = {}}

	for k, v in pairs(devices) do
		local portIO = io.open("/sys/class/sensor/"..v.."/port_name", "r")
		local portName = portIO:read("*a")
		if (portName == port) or port == nil then
			device.raw.path = "/sys/class/sensor/"..v.."/"
			device.raw.port_name = portName
			break
		end
		portIO:close()
	end

	if not device.raw.path then
		return nil, "no sensor on "..port
	end

	--The default API
	device.raw.bin_data = function(self)
		return getValue(self.path.."bin_data")
	end

	device.raw.bin_data_format = function(self)
		return getValue(self.path.."bin_data_format")
	end

	device.raw.command = function(self, value)
		setValue(self.path.."command", value)
	end

	device.raw.commands = stringSplit(getValue(device.raw.path.."commands"))

	device.raw.direct = function(self, value)
		if value then
			setValue(self.raw.path.."direct", value)
		else
			return getValue(self.raw.path.."direct")
		end
	end

	device.raw.decimals = function(self)
		return getValue(self.path.."decimals")
	end

	device.raw.driver_name = function(self)
		return getValue(self.path.."driver_name")
	end

	device.raw.fw_version = function(self)
		return getValue(self.path.."fw_version")
	end

	device.raw.mode = function(self, value)
		setValue(self.path.."mode", value)
	end

	device.raw.modes = stringSplit(getValue(device.raw.path.."modes"))

	device.raw.num_values = function(self)
		return getValue(self.path.."num_values")
	end

	device.raw.poll_ms = function(self, value)
		if value then
			setValue(self.raw.path.."poll_ms", value)
		else
			return getValue(self.raw.path.."poll_ms")
		end
	end

	--port_name is defined above in the device finding loop

	device.raw.units = function(self)
		return getValue(self.path.."units")
	end

	device.raw.value = function(self, value)
		return getValue(self.path.."value"..value)
	end

	--Start abstraction layer
	device.commands = {}
	for k, v in pairs(device.raw.commands) do
		device.commands[v] = true
	end

	device.modes = {}
	for k, v in pairs(device.raw.modes) do
		device.stop_commands[v] = true
	end

	return device
end

ev3.newColourSensor = function(port)
	local device = {["sensor"] = ev3.newSensor(port), ["currentMode"] = ""}
	if not sensor then return "Could not find colour sensor on "..port end

	device.mode = function(self, mode)
		if self.sensor.modes[mode] then
			self.sensor.raw:mode(mode)
			self.currentMode = mode
		elseif mode == nil then
			return self.currentMode
		else
			return nil, mode.." is not a colour sensor mode."
		end
		return true
	end
	device:mode("COL-COLOR")

	device.value = function(self)
		return self.sensor.raw:value(0)
	end

	return device
end

ev3.newInfraredSensor = function(port)
	local device = {["sensor"] = ev3.newSensor(port), ["currentMode"] = ""}
	if not sensor then return "Could not find infared sensor on "..port end

	device.mode = function(self, mode)
		if self.sensor.modes then
			self.sensor.raw:mode(mode)
			self.currentMode = mode
		elseif mode == nil then
			return self.currentMode
		else
			return nil, mode.." is not an IR sensor mode."
		end
		return true
	end
	device:mode("IR-PROX")

	device.proximity = function(self)
		local result, err = self:mode("IR-PROX")
		if not result then return nil, err end

		return self.sensor.raw:value(0)
	end

	device.beacon = function(self, channel)
		local result, err = self:mode("IR-SEEK")
		if not result then return nil, err end

		local valueOffset = (channel-1)*2
		local heading = self.sensor.raw:value(valueOffset)
		local distance = self.sensor.raw:value(valueOffset+1)
		local detected = true

		if heading == 0 and distance == -128 then
			detected = false
		end

		return {heading, distance, detected}
	end

	device.remote = function(self, channel)
		local result, err = self:mode("IR-SEEK")
		if not result then return nil, err end

		return self.sensor.raw:value(channel-1)
	end

	return device
end

ev3.newTouchSensor = function(port)
	local device = {["sensor"] = ev3.newSensor(port)}
	if not sensor then return "Could not find touch sensor on "..port end

	device.sensor.raw:mode("TOUCH")

	device.touch = function(self)
		if self.sensor.raw:value(0) == 0 then
			return false
		else
			return true
		end
	end

	return device
end

ev3.newUltrasonicSensor = function(port)
	local device = {["sensor"] = ev3.newSensor(port), ["currentMode"] = ""}
	if not sensor then return "Could not find ultrasonic sensor on "..port end

	device.mode = function(self, mode)
		if self.sensor.modes then
			self.sensor.raw:mode(mode)
			self.currentMode = mode
		elseif mode == nil then
			return self.currentMode
		else
			return nil, mode.." is not an ultrasonic sensor mode."
		end
		return true
	end
	device:mode("US-SI-CM")

	device.distance = function(self)
		if self.currentMode == "US-LISTEN" then
			local result, err = self:mode("US-SI-CM")
			if not result then return nil, err end
		end

		if self.currentMode == "US-SI-CM" or currentMode == "US-SI-IN" then
			--In single check mode, must enable the sensor again
			self:mode(currentMode)
		end
		return self.sensor.raw:value(0)/10
	end

	device.listen = function(self)
		local result, err = self:mode("US-LISTEN")
		if not result then return nil, err end

		if self.sensor.raw:value(0) == 0 then
			return false
		else
			return true
		end
	end
end

--Output
os.execute("cls")
ev3.log = function(value)
	os.execute("echo "..value.."\n")
	return true
end

ev3.playTone = function(hz, seconds)
	hz = hz or 440
	time = (seconds or 1)*1000
	os.execute("beep -f "..hz.." -l "..time)
	return true
end

ev3.playFile = function(path)
	os.execute("aplay "..path)
	return true
end

ev3.speak = function(value)
	os.execute("espeak --stdout '"..value.."' | aplay -q")
	return true
end