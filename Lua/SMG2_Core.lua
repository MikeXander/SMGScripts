--[[
    Script by Xander
    Thanks to SwareJonge for help setting up the reference pointers
    Thanks to Yoshifan for all the addresses
        Find his Cheat Engine script here: https://github.com/yoshifan/ram-watch-cheat-engine
]]

--[[
    TODO:
    - For bytes that return a "type" find out what those types mean
    - Find player 2's button address
    - Find the reference pointer for PAL
    - Add File time in frames (not sure about Yoshifan's conversion)
]]

local core = {}

function core.GameID()
    local address = 0x0
    return ReadValueString(address, 6)
end

-- Pointer based on version
local function RefPointer()
    local address = nil
    if core.GameID() == "SB4E01" then address = 0xC7A2C8 -- jp, na
    elseif core.GameID() == "SB4P01" then address = nil -- eu, unknown ?
    end
    if address == nil then return nil
    else return GetPointerNormal(address)
    end
end

-- most values are relative to this
local function PosRef()
    if RefPointer() == nil then
        return nil
    else
        return GetPointerNormal(RefPointer() + 0x750)
    end
end

-- helper function to safely read any 1 value
local function readValue(pointer, offset, readFunc)
    if pointer == nil then
        return 0
    else
        return readFunc(pointer + offset)
    end
end

-- helper function to read 3 values in a row
local function readTriple(pointer, offset, readFunc, keys)
    local data = {}
    for i = 1,3 do
        data[keys[i]] = readValue(pointer, offset + 4 * (i - 1), readFunc)
    end
    return data
end

-- STATIC Addresses

-- returns the in-gamer timer in frames
function core.StageTime()
    local addr = 0xA75D10
    return ReadValue32(addr)
end

-- gets both stick coords as a float from -1.0 to 1.0 inclusive
function core.Stick()
    local x_addr = 0xB38A8C
    local y_addr = 0xB38A90
    return {
        X = ReadValueFloat(x_addr),
        Y = ReadValueFloat(y_addr)
    }
end

function core.Buttons()
    local addr1 = 0xB38A2E
    local addr2 = 0xB38A2F
    return {
        ReadValue8(addr1),
        ReadValue8(addr2)
    }
end

-- DYNAMIC Addresses

function core.Pos()
    return readTriple(PosRef(), - 0x8670, ReadValueFloat, {"X", "Y", "Z"})
end

function core.PrevPos()
    return readTriple(PosRef(), 0x14 - 0x8C58, ReadValueFloat, {"X", "Y", "Z"})
end

-- Speed based off position change
function core.Spd()
  local p2 = core.Pos()
  local p1 = core.PrevPos()
  return {
      X = (p2.X - p1.X),
      Y = (p2.Y - p1.Y),
      Z = (p2.Z - p1.Z),
      XZ = math.sqrt(((p2.X - p1.X)^2) + (p2.Z - p1.Z)^2),
      XYZ = math.sqrt(((p2.X - p1.X)^2) + ((p2.Y - p1.Y)^2) + (p2.Z - p1.Z)^2)
  }
end

-- Set the player's position to certain coordinates
function core.setPos(x, y, z)
    local offset1 = 0x14 - 0x8C58
    local address = PosRef()
    if address ~= nil then
        WriteValueFloat(address + offset1, x)
        WriteValueFloat(address + offset1 + 4, y)
        WriteValueFloat(address + offset1 + 8, z)
    end
end

-- Change the player's position relative to their current position
function core.changePos(dx, dy, dz)
    local pos = core.Pos()
    core.setPos(pos.X + dx, pos.Y + dy, pos.Z + dz)
end

-- in-game velocity
-- displacement from moving platforms and launch stars are not accounted for
-- this is the velocity that's observed on the NEXT frame
function core.BaseVelocity()
    return readTriple(PosRef(), 0x38 - 0x8C58, ReadValueFloat, {"X", "Y", "Z"})
end

-- direction of gravity
function core.DownGravity()
    return readTriple(PosRef(), - 0x86C4, ReadValueFloat, {"X", "Y", "Z"})
end

-- Different from gavity + tilt
-- This responds to tilting slopes
-- Unlike tilt, this 'straightens out' to match gravity a few frames after jumping
function core.DownAccel()
    return readTriple(PosRef(), - 0x7D88, ReadValueFloat, {"X", "Y", "Z"})
end

-- Tilt offset from the upwards gravity vector
function core.Tilt()
    return readTriple(PosRef(), - 0x5018, ReadValueFloat, {"X", "Y", "Z"})
end

-- Shaking related information
function core.WiimoteShake()
    return readValue(PosRef(), - 0x7C4A, ReadValue8)
end

function core.NunchuckShake()
    return readValue(PosRef(), - 0x7C49, ReadValue8)
end

function core.SpinCooldownTimer()
    return readValue(PosRef(), - 0x7E19, ReadValue8)
end

function core.SpinAttackTimer()
    return readValue(PosRef(), - 0x7E1C, ReadValue8)
end

-- this keeps counting up if you do multiple mini-spins in one jump
function core.SpinFrames()
    return readValue(PosRef(), - 0x7E1B, ReadValue8)
end

-- Counts up during a ground spin. If interrupted by jumping, tapping crouch
-- while standing still, etc., stops counting up.
-- Doesn't apply to a crouching spin (couldn't find a similar value that applies)
function core.SpinAnimationFrames()
    return readValue(PosRef(), - 0x1BE1, ReadValue8)
end

function core.LumaReturnAnimationTimer()
    return readValue(PosRef(), - 0x7E15, ReadValue8)
end

function core.MidairSpinTimer()
    return readValue(PosRef(), - 0x4E05, ReadValue8)
end

function core.MidairSpinType()
    return readValue(PosRef(), - 0x4DE1, ReadValue8)
end

-- Other/misc/unknown purpose for the following addresses
function core.LastJumpType()
    return readValue(PosRef(), - 0x4DD9, ReadValue8)
end

function core.GroundTurnTimer()
    return readValue(PosRef(), - 0x4DFB, ReadValue8)
end

function core.UnknownState()
    return readValue(PosRef(), - 0x7D23, ReadValue8)
end

return core
