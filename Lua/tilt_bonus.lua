-- This is a direct translation of the tilt bonus found here:
-- https://github.com/JoselleAstrid/ram-watch-cheat-engine
local Memory = require "Memory"
local Vec = require "Vector_Math"

-- one of ['mario', 'luigi', 'yoshi']
-- unknown location in RAM
local character = 'mario'

local tiltInfo = {
    rotation = 0, -- radians
    axis = Vec.New({0, 1, 0}), -- rotation axis
    difference = Vec.New({0, 0, 0}),
    bonus = 0
}

local function UpdateTilt()
    local ugrav = Memory.Player.ReverseGravity
    local tilt = Memory.Player.Tilt

    if ugrav == tilt then
        tiltInfo.rotation = 0
        tiltInfo.axis = Vec.New({0, 1, 0})
        tiltInfo.difference = Vec.New({0, 0, 0})
        return
    end

    -- rotational axis from ugrav to tilt vector
    tiltInfo.axis = Vec.Direction(Vec.Cross(ugrav, tilt))

    -- Check for NaN or +/-infinity.
    local x = tiltInfo.axis[1]
    if x ~= x or x == math.huge or x == -math.huge then
      -- Up vector difference is either 0, or close enough to 0 that our axis
      -- calculation can't work. Either way, we'll treat it as 0 and ensure that
      -- we can display valid values.
      tiltInfo.rotation = 0
      tiltInfo.axis = Vec.New({0, 1, 0})
      tiltInfo.difference = Vec.New({0, 0, 0})
      return
    end

    -- Dot product: to get rotational difference between gravity and tilt.
    tiltInfo.rotation = math.acos(Vec.Dot(ugrav, tilt))

    -- Alternate, crude representation of tilt: difference between up vectors
    tiltInfo.difference = tilt - ugrav
end

local function UpdateTiltBonus()
    if not Memory.Misc.Grounded then return end -- when in air, show the last bonus
    UpdateTilt()

    -- If no tilt, then we know there's no up vel bonus, and we're done.
    if tiltInfo.rotation == 0.0 then
      tiltInfo.bonus = 0
      return
    end

    local vel = Memory.Player.Velocity

    -- Account for the fact that lateral speed gets multiplied by a factor when you jump.
    -- This factor is related to the character's max run speed.
    -- We haven't found the character's max run speed in memory yet, so we have to determine it manually.
    local maxRunSpeed = {
        mario = 13,
        luigi = 15,
        yoshi = 18
        }
        vel = (12.5 / maxRunSpeed[character]) * vel

    -- If no velocity, then we know there's no up vel bonus, and we're done.
    if math.abs(#vel) < 0.000001 then
      tiltInfo.bonus = 0
      return
    end

    -- The up vel tilt bonus doesn't care about slopes if they don't affect your tilt.

    -- To ensure that standing on non-tilting slopes doesn't throw off our
    -- calculation, project the velocity vector onto the "ground plane"
    -- (the plane perpendicular to the gravity up vector), and keep the same magnitude.
    -- As it turns out, this seems to be the correct thing to do for tilting slopes, too.

    local ugrav = Memory.Player.ReverseGravity
    local hvel = vel - Vec.Project(vel, ugrav) -- lateral velocity component

    local groundvel = (#vel / #hvel) * hvel

    -- Apply the tilt to the ground velocity vector.
    -- This is a vector rotation, which we'll calculate with Rodrigues' formula.
    local a = math.cos(tiltInfo.rotation) * groundvel
    local b = math.sin(tiltInfo.rotation) * Vec.Cross(tiltInfo.axis, groundvel)
    local c = (Vec.Dot(tiltInfo.axis, groundvel) * (1 - math.cos(tiltInfo.rotation))) * tiltInfo.axis
    local tiltedVelocity = a + b + c

    -- Finally, find the upward component of the tilted velocity. This is the
    -- bonus up vel that the tilted velocity gives us.
    tiltInfo.bonus = Vec.Dot(tiltedVelocity, ugrav)
end

local function Bonus()
    UpdateTiltBonus()
    return tiltInfo.bonus
end

local tilt = {GetBonus = Bonus}
return tilt
