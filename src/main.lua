dofile('ev3.lua')

local leftMotor = ev3.newMotor(OUT_D)
local rightMotor = ev3.newMotor(OUT_A)
local clawMotor = ev3.newMotor(OUT_B)
local leftColour = ev3.newColourSensor(IN_2)
leftColour:mode(REFLECT)
local rightColour = ev3.newColourSensor(IN_1)
rightColour:mode(REFLECT)
local ir = ev3.newInfraredSensor(IN_4)
local touch = ev3.newTouchSensor(IN_3)

local tank = ev3.newTank(leftMotor, rightMotor)

--calibrate sensors
--calibrate white
while not touch:touch() do --[[wait for any button press]] end
while touch:touch() do end
local col_white = leftColour:value()
ev3.playTone(600, 0.2)

--calibrate black
while not touch:touch() do --[[wait for any button press]] end
while touch:touch() do end
local col_black = leftColour:value()
ev3.playTone(600, 0.2)

--calibrate reflective
while not touch:touch() do --[[wait for any button press]] end
while touch:touch() do end
local col_reflective = leftColour:value()
ev3.playTone(600, 0.2)

--calibrate green
while not touch:touch() do --[[wait for any button press]] end
while touch:touch() do end
local col_green = leftColour:value()
ev3.playTone(600, 0.2)

--calibrate red
while not touch:touch() do --[[wait for any button press]] end
while touch:touch() do end
local col_red = leftColour:value()
ev3.playTone(600, 0.2)

--calibrate blue
while not touch:touch() do --[[wait for any button press]] end
while touch:touch() do end
local col_blue = leftColour:value()
ev3.playTone(1000, 0.2)

local function main()
	while true do
		if touch:touch() then
			--reset
			ev3.playTone(100, 0.5)
			return
		end

		if leftColour:value() == col_reflective and rightColour:value() == col_reflective then
			--In toxic spill
			break
		end

		if ir:proximity() <= 6 then
			--water tower
			tank:turnRight(30)
			tank:on_for_rotations(75, 75, 1.5)
			tank:turnLeft(30)
			tank:on_for_rotations(75, 75, 3)
			tank:turnLeft(30)
			tank:on_for_rotations(75, 75, 1.5)
			tank:turnRight(30)
		end

		if leftMotor:value() == col_green then
			--green on left side
			tank:on(20, 20)
			while leftColour() == col_green do end
			tank:off("hold")
			tank:on_for_rotations(-10, -10, 0.1, "hold")
			rightMotor:on(30)
			--see the tile for explanation
			while rightMotor:value() ~= col_black do end
			while rightMotor:value() ~= col_white do end
			while rightMotor:value() ~= col_black do end
			rightMotor:off()
			tank:on(30, 30)
			while leftColour:value() == col_green do end
			tank:off()
		end

		if rightMotor:value() == col_green then
			--green on right side
			tank:on(20, 20)
			while rightColour() == col_green do end
			tank:off("hold")
			tank:on_for_rotations(-10, -10, 0.1, "hold")
			leftMotor:on(30)
			--see the tile for explanation
			while leftMotor:value() ~= col_black do end
			while leftMotor:value() ~= col_white do end
			while leftMotor:value() ~= col_black do end
			leftMotor:off()
			tank:on(30, 30)
			while rightColour:value() == col_green do end
			tank:off()
		end

		--[[
		--Partial logic for Robocup Junior 2015
		if leftColour:value() == col_red and rightColour:value() == col_red then
			--on red line
			ev3.playTone(, 5)
			tank:on_for_rotations(50, 50, 0.5)
		end

		if leftColour:value() == col_blue then
			--on blue line or water spill
			tank:on(50, 50)
			while leftColour:value() == col_blue do end
			ev3.playTone(, , true)
		end
		--]]

		if leftColour:value() == col_black then
			--left sensor on black
			leftMotor:off()
			rightMotor:on(50)
			while leftColour:value() == col_black do --[[wait until leftColour is not on black]] end
			rightMotor:off()
		end

		if rightColour:value() == col_black then
			--right sensor on black
			leftMotor:on(50)
			rightMotor:off()
			while rightColour:value() == col_black do --[[wait until rightColour is not on black]] end
			leftMotor:off()
		end

		tank:on(50, 50)
	end

	--In toxic spill
	local function checkForFail()
		if ir:remote(1) ~= 0 then
			--reset
			ev3.playTone(100, 0.5)
			return
		end
	end
	tank:off()
	tank:on_for_rotations(50, 50, 0.5)
	checkForFail()

	local closestDistance = 0
	local closestAngle = 0
	for i=0, 179 do
		tank:on_for_degrees(10, -10, 1)
		local distance = ir:proximity()
		if distance < closestDistance then
			closestDistance = distance
			closestAngle = i
		end
		checkForFail()
	end
	checkForFail()

	tank:on_for_degrees(10, -10, closestAngle)
	checkForFail()

	local leftPosition = leftMotor.raw:position()
	local rightPosition = rightMotor.raw:position()
	checkForFail()
	tank:on(50, 50)
	while ir:proximity() >= 2 do end
	tank:off()
	checkForFail()

	clawMotor:on(-100)
	checkForFail()

	leftMotor.raw:position(leftPosition)
	rightMotor.raw:position(rightPosition)
	checkForFail()

	tank:on_for_degrees(-10, 10, closestAngle)
	tank:on_for_rotations(-50, -50, 1)
	checkForFail()

	clawMotor:off()
	clawMotor:on(100)
end

while true do
	while touch:touch() do end
	main()
end