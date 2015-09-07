require 'easyev3'

local leftMotor = ev3.newMotor(OUTPUT_D)
local rightMotor = ev3.newMotor(OUTPUT_A)
local clawMotor = ev3.newMotor(OUTPUT_B)
local leftColour = ev3.newColourSensor(INPUT_2)
local rightColour = ev3.newColourSensor(INPUT_1)
local ir = ev3.newInfraredSensor(IN_4)

local tank = ev3.newTank(OUTPUT_D, OUTPUT_A)

--calibrate sensors
--calibrate white
ev3.buttons.waitToggle("center")
local col_white = leftColour:reflect()
ev3.sound.beep()

--calibrate black
ev3.buttons.waitToggle("center")
local col_black = leftColour:reflect()
ev3.sound.beep()

--calibrate reflective
ev3.buttons.waitToggle("center")
local col_reflective = leftColour:reflect()
ev3.sound.beep()

--calibrate green
ev3.buttons.waitToggle("center")
local col_green = leftColour:reflect()
ev3.sound.beep()

--[[
--calibrate red
ev3.buttons.waitToggle("center")
local col_red = leftColour:reflect()
ev3.sound.beep()

--calibrate blue
ev3.buttons.waitToggle("center")
local col_blue = leftColour:reflect()
ev3.sound.beep()
--]]

local function main()
	while true do
		if touch:touch() then
			--reset
			ev3.sound.beep()
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

		if leftColour:reflect() == col_green then
			--green on left side
			tank:on(20, 20)
			while leftColour:relfect() == col_green do end
			tank:off("hold")
			tank:on_for_rotations(-10, -10, 0.1, "hold")
			rightMotor:on(30)
			--see the tile for explanation
			while rightColour:value() ~= col_black do end
			while rightColour:value() ~= col_white do end
			while rightColour:value() ~= col_black do end
			rightMotor:off()
			tank:on(30, 30)
			while leftColour:value() == col_green do end
			tank:off()
		end

		if rightColour:reflect() == col_green then
			--green on right side
			tank:on(20, 20)
			while rightColour:reflect() == col_green do end
			tank:off("hold")
			tank:on_for_rotations(-10, -10, 0.1, "hold")
			leftMotor:on(30)
			--see the tile for explanation
			while leftColour:reflect() ~= col_black do end
			while leftColour:reflect() ~= col_white do end
			while leftColour:reflect() ~= col_black do end
			leftMotor:off()
			tank:on(30, 30)
			while rightColour:reflect() == col_green do end
			tank:off()
		end

		--[[
		--Partial logic for Robocup Junior 2015
		--Needs to be fixed for easyev3
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

		if leftColour:reflect() == col_black then
			--left sensor on black
			leftMotor:off()
			rightMotor:on(50)
			while leftColour:reflect() == col_black do --[[wait until leftColour is not on black]] end
			rightMotor:off()
		end

		if rightColour:reflect() == col_black then
			--right sensor on black
			leftMotor:on(50)
			rightMotor:off()
			while rightColour:reflect() == col_black do --[[wait until rightColour is not on black]] end
			leftMotor:off()
		end

		tank:on(50, 50)
	end

	--In toxic spill
	local function checkForFail()
		if ev3.buttons.getPressed("center") then
			ev3.sound.beep()
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

	leftMotor.raw:setPosition(leftPosition)
	rightMotor.raw:setPosition(rightPosition)
	checkForFail()

	tank:on_for_degrees(-10, 10, closestAngle)
	tank:on_for_rotations(-50, -50, 1)
	checkForFail()

	clawMotor:off()
	clawMotor:on(100)
end

while true do
	if ev3.buttons.get()["end"] then break end
	main()
end