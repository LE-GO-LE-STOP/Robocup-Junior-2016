from ev3dev.ev3 import TouchSensor as _TouchSensor
from ev3dev.ev3 import ColorSensor as _ColourSensor
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