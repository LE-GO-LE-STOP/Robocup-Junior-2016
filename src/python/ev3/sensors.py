from ev3dev.ev3 import TouchSensor as _TouchSensor

class TouchSensor:
	def __init__(self, port = ""):
		self._sensor = _TouchSensor(port)

	def pressed(self)
		return self._sensor.is_pressed() == 1
