from math import pi
from time import sleep

clawMotor = ev3.Motor("outB")

WHEEL_CIRCUMFERENCE = 13.19
AXLE_LENGTH = 10
WATER_TOWER_DETECT_DISTANCE = 8
WATER_TOWER_DETECT_ANGLE = 40
WATER_TOWER_DETECT_ANGLED_DISTANCE = # WATER_TOWER_DETECT_DISTANCE / cos(WATER_TOWER_DETECT_ANGLE)

def angleToDegrees(angle):
  return (pi * angle * AXLE_LENGTH) / WHEEL_CIRCUMFERENCE

def detectWaterTower():
  if ultrasonicSensor.distance() < WATER_TOWER_DETECT_DISTANCE:
    degrees = angleToDegrees(WATER_TOWER_DETECT_ANGLE)
    leftMotor.onForDegrees(BASE_POWER, degrees, "brake", False)
    rightMotor.onForDegrees(-BASE_POWER, degrees, "brake", True)
    
    distance = ultrasonicSensor.distance()
    if WATER_TOWER_DETECT_ANGLED_DISTANCE - 1 < distance and WATER_TOWER_DETECT_ANGLED_DISTANCE + 1 > distance:
      # Turn until 90 degrees
    else:
      # Reverse
      leftMotor.on(-BASE_POWER, degrees, "brake", False)
      rightMotor.on(BASE_POWER, degrees, "brake", True)
      slope()
      return

def slope():
  pass

def detectRescueZone():
  if iscolour(leftSensor.reflected(), SILVER) and iscolour(rightSensor.reflected(), SILVER):
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
    
    
