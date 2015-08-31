require 'ev3'

local leftMotor = ev3.newMotor(OUT_D)
local rightMotor = ev3.newMotor(OUT_A)
local leftSensor = ev3.newColourSensor(IN_2)
local rightSensor = ev3.newColourSensor(IN_1)

while true do
	if leftSensor:value() == BLACK then
		leftMotor:off()
		rightMotor:on(30)
		while leftSensor:value() == BLACK do end
		rightMotor:off()
	end

	if rightSensor:value() == BLACK then
		leftMotor:on(30)
		rightMotor:off()
		while rightSensor:value() == BLACK do end
		leftMotor:off()
	end

	leftMotor:on(50)
	rightMotor:on(50)
end