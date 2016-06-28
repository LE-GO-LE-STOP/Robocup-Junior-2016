class Tank:
	def __init__(self, leftMotor, rightMotor):
		self._leftMotor = leftMotor
		self._rightMotor = rightMotor

	def off(self, brake):
		self._leftMotor.off(brake = brake)
		self._rightMotor.off(brake = brake)

	def on(self, leftPower, rightPower):
		self._leftMotor.on(power = leftPower)
		self._rightMotor.on(power = rightPower)

	def onForSeconds(self, leftPower, rightPower, seconds, brake, wait):
		self._leftMotor.onForSeconds(power = leftPower, seconds = seconds, brake = brake, wait = False)
		self._rightMotor.onForSeconds(power = rightPower, seconds = seconds, brake = brake, wait = wait)

	def onForDegrees(self, leftPower, rightPower, degrees, brake, wait):
		self._leftMotor.onForDegrees(power = leftPower, degrees = degrees, brake = brake, wait = False)
		self._rightMotor.onForDegrees(power = rightPower, degrees = degrees, brake = brake, wait = wait)

	def onForRotations(self, leftPower, rightPower, rotations, brake, wait):
		self.onForDegrees(leftPower = leftPower, rightPower = rightPower, degrees = rotations * 360, brake = brake, wait = wait)
