from ev3dev.core import TouchSensor as _TouchSensor
from ev3dev.core import ColorSensor as _ColourSensor
from ev3dev.core import UltrasonicSensor as _UltrasonicSensor
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

	def distance(unit = "cm"):
		if unit == "cm":
			return self._sensor.distance_centimeters()
		else:
			return self._sensor.distance_inches()

	def nearby(self):
		return self._sensor.other_sensor_present == 1