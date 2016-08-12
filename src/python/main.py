import ev3
from ev3dev.ev3 import Button
from time import sleep
from math import pi

leftMotor = ev3.Motor("outD")
rightMotor = ev3.Motor("outA")
clawMotor = ev3.Motor("outB")

leftSensor = ev3.ColourSensor("in1")
rightSensor = ev3.ColourSensor("in4")

ultrasonicSensor = ev3.UltrasonicSensor("in2")

Buttons = Button()

BASE_POWER = 60
CALIBRATED_RANGE = 10 # The margin of error that is used when checking for colour
WHEEL_CIRCUMFERENCE = 13.573
TURNING_DIAMETRE = 10.5
WATER_TOWER_DETECT_DISTANCE = 8
WATER_TOWER_DETECT_ANGLE = 40
WATER_TOWER_DETECT_ANGLED_DISTANCE = 10.44 # 8 / cos(40)

WHITELEFT = 0
WHITERIGHT = 0
BLACKLEFT = 0
BLACKRIGHT = 0
GREENLEFT = 0
GREENRIGHT = 0
SILVERLEFT = 0
SILVERRIGHT = 0

def withinrange(x, y, range):
	return (x - range/2 <= y) and (x + range/2 >= y)

def iscolour(result, colour):
	return withinrange(result, colour, CALIBRATED_RANGE)

def angleToDegrees(angle):
  return (pi * angle * AXLE_LENGTH) / WHEEL_CIRCUMFERENCE

def calibrate():
	def cal():
		ev3.Sound.playTone(500, 0.5)

		while not Buttons.enter:
			pass
		while Buttons.enter: 
			pass
		return leftSensor.reflected()

	print("White: ")
	WHITELEFT = cal()
	print(str(WHITELEFT))
	WHITERIGHT = cal()
	print(str(WHITERIGHT))
	print("Black: ")
	BLACKLEFT = cal()
	print(str(BLACKLEFT))
	BLACKRIGHT = cal()
	print(str(BLACKRIGHT))
	print("Green: ")
	GREENLEFT = cal()
	print(str(GREENLEFT))
	GREENRIGHT = cal()
	print(str(GREENRIGHT))
	print("Silver: ")
	SILVERLEFT = cal()
	print(str(SILVERLEFT))
	SILVERRIGHT = cal()
	print(str(SILVERRIGHT))
	print("Calibrated!")

def followLine():
	if iscolour(rightSensor.reflected(), BLACKRIGHT):
		leftMotor.on(BASE_POWER + 15)
		rightMotor.on(BASE_POWER)
		while iscolour(rightSensor.reflected(), BLACKRIGHT):
			pass
		leftMotor.on(BASE_POWER)

	if iscolour(leftSensor.reflected(), BLACKLEFT):
		leftMotor.on(BASE_POWER)
		rightMotor.on(BASE_POWER + 15)
		while iscolour(leftSensor.reflected(), BLACKLEFT):
			pass
		rightMotor.on(BASE_POWER)

def detectGreenTile():
	if iscolour(leftSensor.reflected(), GREENLEFT):
		leftMotor.on(BASE_POWER - 30)
		rightMotor.on(BASE_POWER + 20)
		sleep(2)
		leftMotor.on(BASE_POWER)
		rightMotor.on(BASE_POWER)

	if iscolour(rightSensor.reflected(), GREENRIGHT):
		leftMotor.on(BASE_POWER + 20)
		rightMotor.on(BASE_POWER - 30)
		sleep(2)
		leftMotor.on(BASE_POWER)
		rightMotor.on(BASE_POWER)

def detectWaterTower():
  if ultrasonicSensor.distance() < WATER_TOWER_DETECT_DISTANCE:
    degrees = angleToDegrees(WATER_TOWER_DETECT_ANGLE)
    leftMotor.onForDegrees(BASE_POWER, degrees, "brake", False)
    rightMotor.onForDegrees(-BASE_POWER, degrees, "brake", True)
    
    distance = ultrasonicSensor.distance()
    if WATER_TOWER_DETECT_ANGLED_DISTANCE - 1 < distance and WATER_TOWER_DETECT_ANGLED_DISTANCE + 1 > distance:
      # Turn until 90 degrees
      pass
    else:
      # Reverse
      leftMotor.on(-BASE_POWER, degrees, "brake", False)
      rightMotor.on(BASE_POWER, degrees, "brake", True)
      slope()
      return

def slope():
  pass

def detectRescueZone():
  if iscolour(leftSensor.reflected(), SILVERLEFT) and iscolour(rightSensor.reflected(), SILVERRIGHT):
    degrees = angleToDegrees(90)
    degree = angleToDegrees(1)
    leftMotor.onForDegrees(-BASE_POWER, degrees, "brake", False)
    rightMotor.onForDegrees(BASE_POWER, degrees, "brake", True)
    
    minDistance = 500
    minAngle = 0
    for i in range(0, 180):
      leftMotor.onForDegrees(5, degree, "brake", False)
      rightMotor.onForDegrees(5, degree, "brake", True)
      sleep(0.5)
      
      distance = ultrasonicSensor.distance()
      if distance < minDistance:
        minDistance = distance
        minAngle = i
        
    reverseMinAngle = angleToDegrees(180 - minAngle)
    leftMotor.onForDegrees(-BASE_POWER, reverseMinAngle, "brake", False)
    rightMotor.onForDegrees(BASE_POWER, reverseMinAngle, "brake", True)
    
    canRotations = minDistance / WHEEL_CIRCUMFERENCE
    leftMotor.onForRotations(BASE_POWER, canRotations, "brake", False)
    rightMotor.onForRotations(BASE_POWER, canRotations, "brake", True)
    
    clawMotor.on(100)
    
    leftMotor.onForRotations(-BASE_POWER, canRotations, "brake", False)
    rightMotor.onForRotations(-BASE_POWER, canRotations, "brake", True)
    
    leftMotor.onForDegrees(BASE_POWER, reverseMinAngle, "brake", False)
    rightMotor.onForDegrees(-BASE_POWER, reverseMinAngle, "brake", True)
    
calibrate()
leftMotor.on(BASE_POWER)
rightMotor.on(BASE_POWER)
while True:
	if Buttons.backspace:
		exit()

	print("Left: " + str(leftSensor.reflected()) + " Right: " + str(rightSensor.reflected()))

	#detectRescueZone()
	#detectWaterTower()
	#detectGreenTile()
	followLine()