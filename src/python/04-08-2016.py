from math import pi

WHEEL_CIRCUMFERENCE = 13.19
AXLE_LENGTH = 10
WATER_TOWER_DETECT_DISTANCE = 8
WATER_TOWER_DETECT_ANGLE = 40
WATER_TOWER_DETECT_ANGLED_DISTANCE = # WATER_TOWER_DETECT_DISTANCE / cos(WATER_TOWER_DETECT_ANGLE)

def detectWaterTower:
  if ultrasonicSensor.distance() < WATER_TOWER_DETECT_DISTANCE:
    degrees = (math.pi * WATER_TOWER_DETECT_ANGLE * AXLE_LENGTH) / WHEEL_CIRCUMFERENCE
    leftMotor.onForDegrees(BASE_POWER, degrees, "brake", False)
    rightMotor.onForDegrees(-BASE_POWER, degrees, "brake, True)
    
    distance = ultrasonicSensor.distance()
    if WATER_TOWER_DETECT_ANGLED_DISTANCE - 1 < distance and WATER_TOWER_DETECT_ANGLED_DISTANCE + 1 > distance:
      # Turn until 90 degrees
    else:
      # Reverse
      leftMotor.on(-BASE_POWER, degrees, "brake", False)
      rightMotor.on(BASE_POWER, degrees, "brake", True)
      slope()
      return

def slope:
  pass
