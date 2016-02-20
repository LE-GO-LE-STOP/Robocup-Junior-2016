require "ev3dev/class.lua"

local function stringSplit(inputString)
	local output = {}
	for i in string.gmatch(inputString, "%S+") do
  		table.insert(output, i)
	end
	return output
end

local Device = class()

function Device:init()
	self._type = self.raw._type
	self._port = self.raw._port

	self._modes = {}
	local rawModes = io.open("/sys/class/")
end

function Device:type()
	return self._type
end

function Device:port()
	return self._port
end

function Device:modes()
	return self._modes
end

function Device:isConnected()
	return self.raw:connected()
end

function Device:isMode(mName)
	if self._modes[mName] then
		return true
	else
		return false
	end
end

function Device:command(command)
	if !self:is
end

return Device