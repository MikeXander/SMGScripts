--[[
    Script by Xander
    Thanks to SwareJonge for help setting up the reference pointers
    Thanks to Yoshifan for all the addresses
        Find his Cheat Engine script here: https://github.com/yoshifan/ram-watch-cheat-engine
]]

--[[
    TODO:
    - For bytes that return a "type" find out what those types mean
]]

local core = {}

function core.GameID()
    local address = 0x0
    return ReadValueString(address, 6)
end

-- Most addresses are offset from this pointer
local function RefPointer()
    local address = nil
    if core.GameID() == "RMGE01" then address = 0xF8EF88
    elseif core.GameID() == "RMGJ01" then address = 0xF8F328
    elseif core.GameID() == "RMGP01" then address = 0xF8EF88
    end
    if address == nil then return nil
    else return GetPointerNormal(address)
    end
end
core.rp = RefPointer

local function PosRef()
    if RefPointer() == nil then
        return nil
    else
        return RefPointer() + 0x3EEC
    end
end
core.pr = PosRef

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

function core.Pos()
  return readTriple(PosRef(), 0x0, ReadValueFloat, {"X", "Y", "Z"})
end

function core.PrevPos()
  return readTriple(RefPointer(), 0x18DC, ReadValueFloat, {"X", "Y", "Z"})
end

-- Speed based off position change
function core.Spd()
  local p1 = core.PrevPos()
  local p2 = core.Pos()
  return {
      Y = (p2.Y - p1.Y),
      X = (p2.X - p1.X),
      Z = (p2.Z - p1.Z),
      XZ = math.sqrt(((p2.X - p1.X)^2) + (p2.Z - p1.Z)^2),
      XYZ = math.sqrt(((p2.X - p1.X)^2) + ((p2.Y - p1.Y)^2) + (p2.Z - p1.Z)^2)
  }
end

function core.TextProgress()
  local pointer = 0x9A9240
  local address = GetPointerNormal(pointer)
  if ReadValue32(pointer) == 0 then
    return {textProgress = 0, alphaReq = 0, fadeRate = 0}
  end
  return {
      textProgress = ReadValue32(address + 0x2D39C),
      alphaReq = ReadValueFloat(address + 0x2D3B0),
      fadeRate = ReadValueFloat(address + 0x2D3B4)
  }
end

-- Set the player's position to certain coordinates
function core.setPos(x, y, z)
    local offset = 0x18DC
    local address = RefPointer()
    if address ~= nil then
        WriteValueFloat(address + offset, x)
        WriteValueFloat(address + offset + 4, y)
        WriteValueFloat(address + offset + 8, z)
    end
end

-- Change the player's position relative to their current position
function core.changePos(dx, dy, dz)
    local pos = core.Pos()
    core.setPos(pos.X + dx, pos.Y + dy, pos.Z + dz)
end

-- gets both stick coords as a float from -1.0 to 1.0 inclusive
function core.Stick()
    local x_addr = 0x61D3A0
    local y_addr = 0x61D3A4
    return {
        X = ReadValueFloat(x_addr),
        Y = ReadValueFloat(y_addr)
    }
end

function core.Buttons()
    local buttons1 = 0x61D342
    local buttons2 = 0x61D343
    local p2_buttons = 0x61EF3A
    return {
        P1_main = ReadValue8(buttons1),
        P1_alt = ReadValue8(buttons2),
        P2 = ReadValue8(p2_buttons)
    }
end

-- in-game velocity
-- displacement from moving platforms and launch stars are not accounted for
-- this is the velocity that's observed on the NEXT frame
function core.BaseVelocity()
    return readTriple(PosRef(), 0x78, ReadValueFloat, {"X", "Y", "Z"})
end

function core.NextPos()
    local vel = core.BaseVelocity()
    local pos = core.Pos()
    return {
        X = pos.X + vel.X,
        Y = pos.Y + vel.Y,
        X = pos.Z + vel.Z,
    }
end

-- direction of gravity
function core.DownGravity()
    return readTriple(RefPointer(), 0x1B10, ReadValueFloat, {"X", "Y", "Z"})
end

-- this is just a positive version of gravity
function core.UpGravity()
    return readTriple(RefPointer(), 0x6A3C, ReadValueFloat, {"X", "Y", "Z"})
end

-- This can be different from upwards gravity
function core.Tilt()
    return readTriple(PosRef(), 0xC0, ReadValueFloat, {"X", "Y", "Z"})
end

-- State Values
-- Once we figure out what these are we can probably combine it into 1 function
function core.StateA()
    return readValue(PosRef(), - 0x128, ReadValue8)
end

function core.StateATable()
    local function bitTable(val, length)
        local t = {}
    	local size = 2 ^ (length - 1)
    	while size > 0 do
    		t[length] = string.format("%d", val % 2)
            length = length - 1
    		val = val // 2
    		if size == 1 then size = 0 end
    		size = size / 2
    	end
    	return t
    end
    return bitTable(core.StateA(), 8)
end

function core.StateB()
    return readValue(PosRef(), - 0x127, ReadValue8)
end

function core.StateC()
    return readValue(PosRef(), - 0x126, ReadValue8)
end

function core.StateD()
    return readValue(PosRef(), - 0x125, ReadValue8)
end

function core.States()
    return ReadValue32(PosRef() - 0x128)
    --[[{
        A = core.StateA(),
        B = core.StateB(),
        C = core.StateC(),
        D = core.StateD()
    }]]
end

function core.OnGround()

end

-- This appears to be an in-game timer
-- It counts up by 1 per frame starting from the level-beginning cutscenes.
-- It also pauses for a few frames when you get the star.
-- It resets to 0 if you die.
function core.StageTime()
    return ReadValue8(0x9ADE58)
end

-- Shake related info
function core.WiimoteShake()
    return readValue(RefPointer(), 0x27F0, ReadValue8)
end

function core.NunchuckShake()
    return readValue(RefPointer(), 0x27F1, ReadValue8)
end

function core.SpinCooldownTimer()
    return readValue(RefPointer(), 0x2217, ReadValue8)
end

function core.SpinAttackTimer()
    return readValue(RefPointer(), 0x2214, ReadValue8)
end

-- Value is 180 when inactive
function core.MidairSpinTimer()
    return readValue(RefPointer(), 0x41BF, ReadValue8)
end

function core.MidairSpinType()
    return readValue(RefPointer(), 0x41E7, ReadValue8)
end

-- Types include:
-- Jump, double jump or rainbow star jump, triple jump,
-- bonk or forward facing slope jump, sideflip, long jump, backflip, wall jump,
-- midair spin, ?, ledge hop, spring topman bounce, enemy bounce,
-- jump off swing / pull star release / after planet landing / spin out of water
function core.LastJumpType()
    return readValue(RefPointer(), 0x41EF, ReadValue8)
end

function core.GroundTurnTimer()
    return readValue(RefPointer(), 0x41CB, ReadValue8)
end

function core.FileStarbits()
    local addr = 0xF63CF4
    return ReadValue32(addr)
end

-- HUD information
function core.HP()
    return readValue(RefPointer(), 0xDD67, ReadValue8)
end

function core.Starbits()
    return readValue(RefPointer(), - 0x781E34, ReadValue32)
end

function core.Coins()
    return readValue(RefPointer(), - 0x4C61C, ReadValue32)
end

function core.Rotation() -- 0x18E8 ?
    return readTriple(RefPointer(), 0x18DC + 0xC, ReadValueFloat, {"AngleA", "AngleB", "AngleC"})
end

function core.NunchukEncryptionKey() -- Found by BillyWAR
    local addr = 0x661AC4
    local array = {}
    local str = ""
    for i = 1, 16 do
        array[i] = ReadValue8(addr + (i - 1))
        str = str .. string.format("%02X ", array[i])
    end
    return {array, str}
end

--[[
function core.angle()
    return ReadValue32(RefPointer() + 0x3FC4‬)
end]]

return core
