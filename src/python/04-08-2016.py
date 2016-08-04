WHEEL_CIRCUMFERENCE = 13.19
WATER_TOWER_DETECT_DISTANCE = 8
WATER_TOWER_DETECT_ANGLE
WATER_TOWER_DETECT_ANGLED_DISTANCE = # WATER_TOWER_DETECT_DISTANCE / cos(WATER_TOWER_DETECT_ANGLE)

def detectWaterTower:
  if ultrasonicSensor.distance() < WATER_TOWER_DETECT_DISTANCE:
    degrees = 
    leftMotor.on(BASE_POWER, degrees, "brake", False)
    rightMotor.on(-BASE_POWER, degrees, "brake, True)
    
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
