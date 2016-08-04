import ev3
from time import sleep

leftMotor = ev3.Motor("outA")
rightMotor = ev3.Motor("outD")

leftSensor = ev3.ColourSensor("in1")
rightSensor = ev3.ColourSensor("in4")

ultrasonicSensor = ev3.UltrasonicSensor("in2")

BASE_POWER = 60
CALIBRATED_RANGE = 10 # The margin of error that is used when checking for colour
WHEEL_CIRCUMFERENCE = 13.573
WATER_TOWER_DETECT_DISTANCE = 8
WATER_TOWER_DETECT_TURN_ANGLE = 40
WATER_TOWER_DETECT_TURNED_DISTANCE = 10.44 # 8 / cos(40)

WHITE = 0
BLACK = 0
GREEN = 0
SILVER = 0

def withinrange(x, y, range):
	return x - range/2 <= y && x + range/2 >= y

def iscolour(result, colour):
	return withinrange(result, colour, CALIBRATED_RANGE)

def calibrate():
	def cal():
		ev3.Sound.playTone(500, 0.5)
		while not ev3.Buttons.center:
			pass
		while ev3.Buttons.center: 
			pass
		return leftSensor.reflected()

	WHITE = cal()
	BLACK = cal()
	GREEN = cal()
	SILVER = cal()

def followLine():
	if iscolour(rightSensor.reflected(), BLACK):
		leftMotor.on(BASE_POWER + 15)
		rightMotor.on(BASE_POWER)
		while iscolour(rightSensor.reflected, BLACK):
			pass
		leftMotor.on(BASE_POWER)

	if iscolour(leftSensor.reflected(), BLACK):
		leftMotor.on(BASE_POWER)
		rightMotor.on(BASE_POWER + 15)
		while iscolour(leftMotor.reflected, BLACK):
			pass
		rightMotor.on(BASE_POWER)

def detectGreenTile():
	if iscolour(leftSensor.reflected(), GREEN):
		leftMotor.on(BASE_POWER - 30)
		rightMotor.on(BASE_POWER + 20)
		sleep(2)
		leftMotor.on(BASE_POWER)
		rightMotor.on(BASE_POWER)

	if iscolour(rightSensor.reflected(), GREEN):
		leftMotor.on(BASE_POWER + 20)
		rightMotor.on(BASE_POWER - 30)
		sleep(2)
		leftMotor.on(BASE_POWER)
		rightMotor.on(BASE_POWER)

def detectWaterTower():
	if ultrasonicSensor.distance() < WATER_TOWER_DETECT_DISTANCE:
		leftMotor.onForDegrees(BASE_POWER, (), "brake", False)
		rightMotor.onForDegrees(BASE_POWER, (), "brake", True)

def detectFinal():
	pass

while True:
	detectFinal()
	detectWaterTower()
	detectGreenTile()
	followLine()