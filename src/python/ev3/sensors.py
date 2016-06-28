from ev3dev.core import TouchSensor as _TouchSensor
from ev3dev.core import ColorSensor as _ColourSensor
from ev3dev.core import UltrasonicSensor as _UltrasonicSensor
from ev3dev.core import InfraredSensor as _InfraredSensor
from math import floor

class TouchSensor:
	def __init__(self, port):
		self._sensor = _TouchSensor(port)

	def pressed(self)
		return self._sensor.is_pressed() == 1

class ColourSensor:
	def __init__(self, port):
		self._sensor = _ColourSensor(port)

	def reflected(self):
		return self._sensor.reflected_light_intensity()

	def ambient(self):
		return self._sensor.ambient_light_intensity()

	def colour(self):
		return self._sensor.color()

	_rgbConstant = 256 / 1020 #Used to convert from the raw sensor range (0 - 1020) to rgb range (0 - 255)
	def rgb(self):
		return [
			floor(self._sensor.red() * _rgbConstant),
			floor(self._sensor.green() * _rgbConstant),
			floor(self._sensor.blue() * _rgbConstant)
		]

class UltrasonicSensor:
	def __init__(self, port):
		self._sensor = _UltrasonicSensor(port)

	def distance(self, unit = "cm"):
		if unit == "cm":
			return self._sensor.distance_centimeters()
		else:
			return self._sensor.distance_inches()

	def nearby(self):
		return self._sensor.other_sensor_present == 1

class InfraredSensor:
	def __init__(self, port):
		self._sensor = _InfraredSensor(port)

	def proximity(self):
		return self._sensor.proximity()

	def seek(self, channel = 1):
		self._sensor.mode = _InfraredSensor.MODE_IR_SEEK

		valueOffset = (channel - 1) * 2

		return {
			"heading": self._sensor.value(valueOffset),
			"strength": self._sensor.value(valueOffset + 1),
			"detected": not (heading == 0 and strength == -128),
		}

	_simpleSensorStates = [
		{"red":{"up":False,"down":False},"blue":{"up":False,"down":False},"beacon":False}, # None
		{"red":{"up":True,"down":False},"blue":{"up":False,"down":False},"beacon":False}}, # Red up
		{"red":{"up":False,"down":True},"blue":{"up":False,"down":False},"beacon":False}}, # Red down
		{"red":{"up":False,"down":False},"blue":{"up":True,"down":False},"beacon":False}}, # Blue up
		{"red":{"up":False,"down":False},"blue":{"up":False,"down":True},"beacon":False}}, # Blue down
		{"red":{"up":True,"down":False},"blue":{"up":True,"down":False},"beacon":False}}, # Red up, blue up
		{"red":{"up":True,"down":False},"blue":{"up":False,"down":True},"beacon":False}}, # Red up, blue down
		{"red":{"up":False,"down":True},"blue":{"up":True,"down":False},"beacon":False}}, # Red down, blue up
		{"red":{"up":False,"down":True},"blue":{"up":False,"down":True},"beacon":False}}, # Red down, blue down
		{"red":{"up":False,"down":False},"blue":{"up":False,"down":False},"beacon":True}, # Beacon
		{"red":{"up":True,"down":True},"blue":{"up":False,"down":False},"beacon":False}}, # Red up, red down
		{"red":{"up":False,"down":False},"blue":{"up":True,"down":True},"beacon":False}} # Blue up, blue down
	]
	def remote(self, channel = 1):
		if channel == 1:
			# Use the more detailed mode that can read multiple pressed buttons
			self._sensor.mode = _InfraredSensor.MODE_IR_REM_A

			value = self._sensor.value(0) - 0x100 # Remove the most significant byte (it is always the same)
			buttons = {
				"red": {
					"up": False,
					"down": False
				},
				"blue": {
					"up": False,
					"down": False
				},
				"beacon": False
			}

			if not (value & 0x0F == 0):
				# Some buttons have been pressed
				buttons["blue"]["down"] = value & 0x80
				buttons["blue"]["up"] = value & 0x40
				buttons["red"]["down"] = value & 0x20
				buttons["red"]["up"] = value & 0x10
				buttons["beacon"] = value & 0xF9 == 0

			return buttons
		else:
			self._sensor.mode = _InfraredSensor.MODE_IR_REMOTE
			return _simpleSensorStates[self._sensor.value(channel - 1)]