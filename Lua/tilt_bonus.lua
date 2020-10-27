-- This is a direct translation of Yoshifan's tilt bonus calculation
-- Found here: https://github.com/yoshifan/ram-watch-cheat-engine
local core = require "SMG_core"
local vec = require "Vector_Math"

-- one of ['mario', 'luigi', 'yoshi']
-- unknown location in RAM
local character = 'mario'

local tiltInfo = {
	rotation = 0, -- radians
	axis = {0, 1, 0}, -- rotation axis
	difference = {0, 0, 0},
	bonus = 0
}

local function UpdateTilt()
	local ugrav = {core.UpGravity().X, core.UpGravity().Y, core.UpGravity().Z}
	local tilt = {core.Tilt().X, core.Tilt().Y, core.Tilt().Z}

	if vec.equal(ugrav, tilt, 0.000001) then
		tiltInfo.rotation = 0
		tiltInfo.axis = {0, 1, 0}
		tiltInfo.difference = {0, 0, 0}
		return
	end

	-- rotational axis from ugrav to tilt vector
	tiltInfo.axis = vec.direction(vec.cross(ugrav, tilt))

    -- Check for NaN or +/-infinity.
	local x = tiltInfo.axis[1]
    if x ~= x or x == math.huge or x == -math.huge then
      -- Up vector difference is either 0, or close enough to 0 that our axis
      -- calculation can't work. Either way, we'll treat it as 0 and ensure that
      -- we can display valid values.
	  tiltInfo.rotation = 0
	  tiltInfo.axis = {0, 1, 0}
	  tiltInfo.difference = {0, 0, 0}
	  return
    end

	-- Dot product: to get rotational difference between gravity and tilt.
	tiltInfo.rotation = math.acos(vec.dot(ugrav, tilt))

	-- Alternate, crude representation of tilt: difference between up vectors
	tiltInfo.difference = vec.minus(tilt, ugrav)
end

local function UpdateTiltBonus()
	if core.StateATable()[2] == "0" then return end -- when in air, show the last bonus
	UpdateTilt()

	-- If no tilt, then we know there's no up vel bonus, and we're done.
	if tiltInfo.rotation == 0.0 then
	  tiltInfo.bonus = 0
	  return
	end

	local vel = {core.BaseVelocity().X, core.BaseVelocity().Y, core.BaseVelocity().Z} -- next velocity

	-- Account for the fact that lateral speed gets multiplied by a factor when you jump.
    -- This factor is related to the character's max run speed.
    -- We haven't found the character's max run speed in memory yet, so we have to determine it manually.
    local maxRunSpeed = {
        mario = 13,
        luigi = 15,
        yoshi = 18
    }
    vel = vec.scalar_mult(12.5 / maxRunSpeed[character], vel)

    -- If no velocity, then we know there's no up vel bonus, and we're done.
    if math.abs(vec.mag(vel)) < 0.000001 then
      tiltInfo.bonus = 0
      return
    end

    -- The up vel tilt bonus doesn't care about slopes if they don't affect your tilt.

    -- To ensure that standing on non-tilting slopes doesn't throw off our
    -- calculation, project the velocity vector onto the "ground plane"
    -- (the plane perpendicular to the gravity up vector), and keep the same magnitude.
    -- As it turns out, this seems to be the correct thing to do for tilting slopes, too.

	local ugrav = {core.UpGravity().X, core.UpGravity().Y, core.UpGravity().Z}
	local hvel = vec.minus(vel, vec.proj(vel, ugrav)) -- lateral velocity component

    local groundvel = vec.scalar_mult(vec.mag(vel) / vec.mag(hvel), hvel)

    -- Apply the tilt to the ground velocity vector.
    -- This is a vector rotation, which we'll calculate with Rodrigues' formula.
    local a = vec.scalar_mult(math.cos(tiltInfo.rotation), groundvel)
    local b = vec.scalar_mult(math.sin(tiltInfo.rotation), vec.cross(tiltInfo.axis, groundvel))
    local c = vec.scalar_mult(vec.dot(tiltInfo.axis, groundvel) * (1 - math.cos(tiltInfo.rotation)), tiltInfo.axis)
    local tiltedVelocity = vec.add(vec.add(a, b), c)

    -- Finally, find the upward component of the tilted velocity. This is the
    -- bonus up vel that the tilted velocity gives us.
    tiltInfo.bonus = vec.dot(tiltedVelocity, ugrav)
end

local function Bonus()
    UpdateTiltBonus()
    return tiltInfo.bonus
end

local tilt = {GetBonus = Bonus}
return tilt
