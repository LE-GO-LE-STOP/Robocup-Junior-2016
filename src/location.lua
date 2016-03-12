local class = require("class").class

local trig = require("trig")

local Angle = trig.Angle

local function locateMe(boxWidth, boxHeight, distanceOffset, compass, usSensors)
	local angle = correctAngle(compass:relativeDirection()) -- Relative direction is used, as it respects previous calibration

	local frontDistance = usSensors.front:distance("US-DIST-CM") + distanceOffset
	local backDistance = usSensors.back:distance("US-DIST-CM") + distanceOffset
	local leftDistance = usSensors.left:distance("US-DIST-CM") + distanceOffset
	local rightDistance = usSensors.right:distance("US-DIST-CM") + distanceOffset

	if angle > 0 and angle <= 90 then
		-- Front is facing towards the top right corner
		if angle - 90
	end
end

return {
	locateMe = locateMe
}