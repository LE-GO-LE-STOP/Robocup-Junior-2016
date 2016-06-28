from ev3dev.core import Motor as _Motor
from time import sleep

class Motor:
	def __init__(self, port):
		self._motor = _Motor(address = port)
		self._countPerRot = self._motor.count_per_rot

	def setBrake(self, brake = False):
		if brake:
			self._motor.stop_action = brake

	def off(self, brake):
		self.setBrake(brake = brake)

		self._motor.command = _Motor.COMMAND_STOP

	def on(self, power = 100):
		self._motor.duty_cycle_sp = power
		self._motor.command = _Motor.COMMAND_RUN_FOREVER

	def onForSeconds(self, power, seconds, brake, wait = True):
		if wait:
			self.on(power = power)
			sleep(seconds)
			self.off(brake = brake)
		else:
			self._motor.duty_cycle_sp = power
			self._motor.time_sp = seconds * 1000
			self._motor.command = _Motor.COMMAND_RUN_TIMED

			self.setBrake(brake = brake)

	def onForDegrees(self, power, degrees, brake, wait = True):
		position = degrees * (self._countPerRot / 360)

		if wait:
			targetPosition = self._motor.position + position
			self.on(power = power)

			if degrees >= 0:
				while self._motor.position < targetPosition:
					pass
			else:
				while self._motor.position > targetPosition:
					pass

			self.off(brake = brake)
		else:
			self._motor.duty_cycle_sp = power
			self._motor.position_sp = position
			self._motor.command = _Motor.COMMAND_RUN_TO_REL_POS

			self.setBrake(brake = brake)

	def onForRotations(self, power, rotations, brake, wait = True):
		self.onForDegrees(power = power, degrees = rotations * 360, brake = brake, wait = wait)