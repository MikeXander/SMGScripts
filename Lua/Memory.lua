--[[
    ========= Memory Module =========
    Easy access to most known things in RAM.
    Quick reference for available info:

    Memory.Inputs = {Stick, WiimoteAccel, Buttons, NunchukEncryptionKey}
    Memory.Misc = {StageTime, TextInfo, FileStarbits, Coins, HP, Grounded}
    Memory.Objects[i] = {Address, Name, Position, Rotation, Size, Speed}
    Refer to Memory.PlayerObjectOffsets for all of the Memory.Player properties

    Example: Memory.Player.Position.X
]]

local Vec = require "Vector_Math"

local Memory = {
    OFFSETS = {
        POSITION = 0x0C,
        ROTATION = 0x18,
        SIZE     = 0x24,
        SPEED    = 0x30
    },
    Objects = { -- Array of objects
        StartAddress = 0x0
    },
    Player  = {}, -- Mario/Luigi Easy to Grab Object
}

local TYPES = {
    Vec3f   = 0,
    Byte    = 1,
    BIT     = 2,
    Integer = 3
}
Memory.TYPES = TYPES

local GAMEID = ReadValueString(0x0, 6)
local PlayerObjectAddress = function()
    local ptr_addrs = {
        ["RMGE01"] = 0xF8EF88,
        ["RMGJ01"] = 0xF8F328,
        ["RMGP01"] = 0xF8EF88
    }
    if ptr_addrs[GAMEID] == nil then
        return nil
    end
    local addr = GetPointerNormal(ptr_addrs[GAMEID])
    if addr == 0x0 then
        return nil
    end
    return addr + 0x18D0
end

Memory.PlayerObjectOffsets = {
    -- Attribute        = {Offset, Type}
    Position            = {0x000C, TYPES.Vec3f},
    Rotation            = {0x0018, TYPES.Vec3f},
    Size                = {0x0024, TYPES.Vec3f},
    Speed               = {0x0030, TYPES.Vec3f},
    Gravity             = {0x0240, TYPES.Vec3f},
    SpinAttackTimer     = {0x0944, TYPES.Byte},
    SpinCooldownTimer   = {0x0947, TYPES.Byte},
    SpinHitboxTimer     = {0x0944, TYPES.Byte},
    Rainbow             = {0x0A6E, TYPES.Byte}, -- 0 = off, 1 = on, n>1 => count down to 1, 5 when talking?
    WmSpinSuppressTimer = {0x0F1D, TYPES.Byte},
    NcSpinSuppressTimer = {0x0F1F, TYPES.Byte},
    WiimoteShake        = {0x0F20, TYPES.Byte}, -- aka WmWaterSpinFilter
    NunchuckShake       = {0x0F21, TYPES.Byte},
    StateA              = {0x24F4, TYPES.Byte},
    StateB              = {0x24F5, TYPES.Byte},
    StateC              = {0x24F6, TYPES.Byte},
    StateD              = {0x24F7, TYPES.Byte},
    PreviousPosition    = {0x261C, TYPES.Vec3f},
    Velocity            = {0x2694, TYPES.Vec3f},
    FacingDirection     = {0x26F4, TYPES.Vec3f},
    Tilt                = {0x26DC, TYPES.Vec3f},
    MidairSpinTimer     = {0x28EF, TYPES.Byte}, -- 180 when inactive
    GroundTurnTimer     = {0x28FB, TYPES.Byte},
    MidairSpinType      = {0x2917, TYPES.Byte}, -- 1=wm, 2=nc
    LastJumpType        = {0x291F, TYPES.Byte},
    LastGroundPosition  = {0x2978, TYPES.Vec3f},
    ReverseGravity      = {0x516C, TYPES.Vec3f}, -- points "up"
    WaterSpinTimer      = {0x517D, TYPES.Byte},
    WaterState          = {0x519F, TYPES.Byte},
    Air                 = {0x51E8, TYPES.Integer},
    HP                  = {0xC497, TYPES.Byte}
    -- length = 0x6A9C8
    --[[
        observatory testing - some object specific info depends on level/area
        81 06 4B D0 ? start = 10C1298 , end = 112BC60
        starting at 0x810C4100 (offset 2E68) = 810c72e0 => bubble pop word to -2129890592
        word at offset 60D0 -> bubble travel timer
        word at offset 609A -> bubble start timer
    ]]
}

local SETTER = function(addr, datatype)
    if datatype == TYPES.Vec3f then
        return function(x, y, z)
            if type(x) == "table" then -- for use with the Vector Math module
                y = x[2]
                z = x[3]
                x = x[1]
            end
            if x then WriteValueFloat(addr, x) end
            if y then WriteValueFloat(addr + 4, y) end
            if z then WriteValueFloat(addr + 8, z) end
        end
    elseif datatype == TYPES.Integer then
        return function(value)
            WriteValue32(addr, value)
        end
    elseif datatype == TYPES.Byte then
        return function(value)
            WriteValue8(addr, value)
        end
    end
end
Memory.Set = SETTER

local GETTER = function(addr, datatype)
    if datatype == TYPES.Vec3f then
        return Vec.New({
            X = ReadValueFloat(addr),
            Y = ReadValueFloat(addr + 4),
            Z = ReadValueFloat(addr + 8),
            Set = SETTER(addr, datatype)
        })
    elseif datatype == TYPES.Integer then
        return ReadValue32(addr)
    elseif datatype == TYPES.Byte then
        return ReadValue8(addr)
    end
end
Memory.Get = GETTER

-- looks for keys that start with "_" corresponding to functions
-- calls the function and stores the value in a key without the "_"
local function UPDATER(self)
    for key,func in pairs(self) do
        if key:find("^_") and type(func) == "function" then
            self[key:sub(2)] = func()
        end
    end
end

Memory.Player = {
    Update = UPDATER,

    _Address = function()
        return PlayerObjectAddress() or 0
    end

    --[[__Acceleration = function()
        if Memory.Player.PreviousVelocity == nil then
            Memory.Player.PreviousVelocity = Vec.New({0, 0, 0})
        end
        local accel = Memory.Player.Velocity - Memory.Player.PreviousVelocity
        MsgBox(Memory.Player.Velocity)
        MsgBox(Memory.Player.PreviousVelocity)
        Memory.Player.PreviousVelocity = Memory.Player.Velocity
        return accel
    end,]]
}

-- Memory.JumpType[Memory.Player.LastJumpType]
Memory.JumpType = {
    [0x0] = "Single Jump",
    [0x1] = "Double Jump / Star Jump", -- check rainbow star jump?
    [0x2] = "Triple Jump / 2P Jump",
    [0x3] = "Bonk / Uphill Slope Jump",
    [0x4] = "Sideflip",
    [0x5] = "Long Jump",
    [0x6] = "Backflip",
    [0x7] = "Wall Jump",
    [0x8] = "Midair Spin",
    -- Unknown
    [0xA] = "Ledge Pullup",
    [0xB] = "spring topman bounce", -- todo: verify below
    [0xC] = "Enemy Bounce",
    [0xD] = "jump off swing / pull star release / after planet landing / spin out of water"
}

-- Memory.WaterStateType[Memory.Player.WaterState]
Memory.WaterStateType = {
    [0] = "Surfaced (Stationary)",
    [1] = "Surfaced (Moving)",
    [2] = "Underwater (Moving)",
    [3] = "Underwater (Stationary)",
    [255] = "Out of Water"
}

Memory.Inputs = {
    Update = UPDATER,

    _Stick = function()
        return { -- float from -1.0 to 1.0
            X = ReadValueFloat(0x61D3A0),
            Y = ReadValueFloat(0x61D3A4),
            -- note: the following values appear 3 times in memory
            -- offset 0x60 from each other. Not sure the difference
            Coordinates = { -- number from 0 to 255
                X = (ReadValue8(0x661210) + 128) % 256,
                Y = (ReadValue8(0x661211) + 128) % 256
            }
        }
    end,
    
    _WiimoteAccel = function()
        -- these values are in the same block as the joystick coordinates
        -- but are only repeated twice
        -- FE00 maps to -512 (0 on tas input)
        -- 0000 maps to 0 (512 on tas input)
        -- 01FF maps to 511 (1023 on tas input)
        local function ReadAccel(addr)
            val = ReadValue16(addr)
            if val > 511 then
                val = -1 * (0xFFFF - val + 1)
                val = val 
            end
            return (val + 0) --// 10 * 10
        end
        return {
            X = ReadAccel(0x661242),
            Y = ReadAccel(0x661244),
            Z = ReadAccel(0x661246)
        }
    end,
    
    _Buttons = function()
        local P1 = ReadValue16(0x61D342)
        local P2 = ReadValue8(0x61EF3A)
        local isPressed = function(mask, inputs)
            return mask & inputs == mask
        end
        return {
            P1 = {
                Two = isPressed(1 << 8, P1),
                One = isPressed(1 << 9, P1),
                B = isPressed(1 << 10, P1),
                A = isPressed(1 << 11, P1),
                Minus = isPressed(1 << 12, P1),
                Z = isPressed(1 << 13, P1),
                C = isPressed(1 << 14, P1),
                Home = isPressed(1 << 15, P1),
                Left = isPressed(1, P1),
                Right = isPressed(1 << 1, P1),
                Down = isPressed(1 << 2, P1),
                Up = isPressed(1 << 3, P1),
                Plus = isPressed(1 << 4, P1),
                Data = P1
            },
            P2 = {
                A = isPressed(8, P2),
                B = isPressed(4, P2),
                HOME = isPressed(128, P2),
                Data = P2
            }
        }
    end,
    
    _NunchukEncryptionKey = function()
        local array = {}
        local str = ""
        for i = 1, 16 do
            array[i] = ReadValue8(0x661AC4 + (i - 1))
            str = str .. string.format("%02X ", array[i])
        end
        return {array, str}
    end
}

Memory.Camera = {
    Update = UPDATER,

    _Position = function() -- I dont think this is actually the position....
        local addr = PlayerObjectAddress()
        if addr == nil then return {X = 0, Y = 0, Z = 0} end
        addr = addr - 0x18D0 - 0x48EBC
        -- maybe rotation / shake values between each coord?
        -- the coords appear to be listed twice (0x30 off)
        -- but the values inbetween are different
        return {
            X = ReadValueFloat(addr),
            Y = ReadValueFloat(addr + 0x10),
            Z = ReadValueFloat(addr + 0x20)
        }
    end
}

Memory.Misc = {
    Update = UPDATER,

    -- Counts up by 1 per frame starting from the level-beginning cutscenes.
    -- Pauses for a few frames when you get the star. It resets to 0 if you die.
    _StageTime = function()
        return ReadValue32(0x9ADE58)
    end,

    _TextInfo = function()
        local addr = GetPointerNormal(0x9A9240)
        if ReadValue32(pointer) == 0 then
            return {TextProgress = 0, AlphaReq = 0, FadeRate = 0}
          end
          return {
              TextProgress = ReadValue32(addr + 0x2D39C),
              AlphaReq = ReadValueFloat(addr + 0x2D3B0),
              FadeRate = ReadValueFloat(addr + 0x2D3B4)
          }
    end,

    _FileStarbits = function()
        return ReadValue32(0xF63CF4)
    end,

    _Coins = function()
        local addr = PlayerObjectAddress()
        if addr == nil then
            return 0
        end
        return ReadValue32(addr - 0x18D0 - 0x4C61C)
    end,

    _Starbits = function()
        local addr = PlayerObjectAddress()
        if addr == nil then
            return 0
        end
        return ReadValue32(addr - 0x18D0 - 0x781E34)
    end,

    _HP = function()
        local addr = PlayerObjectAddress()
        if addr == nil then
            return 0
        end
        return ReadValue8(addr - 0x18D0 - 0x781E34)
    end,

    _Grounded = function()
        local addr = PlayerObjectAddress()
        if addr == nil then
            return 0
        end
        local state = ReadValue8(addr + 0x24F4--[[ Memory.PlayerObjectOffsets.StateA[1] ]])
        return (state & 0x40 == 0x40) and 1 or 0
    end
}

local function getName(endAddress) -- Finding a name for an object if available
    endAddress = ReadValue32(endAddress)
    if endAddress < 0x91000000 then -- Finds if the object points to the right area of memory where a name exists
        return nil
    else
        stringEnd = endAddress - 2 -- Works backward from the end to get the string
        objName = ""
        while ReadValueString(stringEnd, 1) ~= "" do
            objName = ReadValueString(stringEnd, 1) .. objName
            stringEnd = stringEnd - 1
        end
    end
    return objName
end

local OBJ_MT = {
    __tostring = function(self)
        return string.format(
            "{%s, 0x%X, %s}",
            self.Name or "(nil)",
            self.Address or 0,
            self.Position or "(nil)"
        )
    end,

    __concat = function(a, b)
        if type(a) == "table" then
            a = tostring(a)
        end
        if type(b) == "table" then
            b = tostring(b)
        end
        return a .. b
    end
}

function Memory.NewObject(objAddress) -- object constructor
    if objAddress < 0x80000000 then
        return setmetatable({Address = objAddress}, OBJ_MT)
    end
    local get = function(addr) return GETTER(addr, TYPES.Vec3f) end
    local obj = {
        Address = objAddress,
        Name = getName(objAddress+4),
        --_last_update = -1,
        Update = function(self)
            --local vi = GetFrameCount() -- update at most once per frame
            --if vi == self._last_update then return end
            --self._last_update = vi
            self.Position = get(objAddress + Memory.OFFSETS.POSITION)
            self.Rotation = get(objAddress + Memory.OFFSETS.ROTATION)
            self.Size = get(objAddress + Memory.OFFSETS.SIZE)
            self.Speed = get(objAddress + Memory.OFFSETS.SPEED)
        end
    }
    obj:Update()
    setmetatable(obj, OBJ_MT)
    return obj
end

-- attempt to get an object's index given an address
local ObjectAddrIdMap = {}
local OBJ_IDX_SEARCH_MT = {
    __index = function(self, key)
        if Memory.Objects.StartAddress == nil or type(key) ~= "number" then
            return nil
        end
        if ObjectAddrIdMap[key]then
            return Memory.Objects[ObjectAddrIdMap[key]]
        end
    end
}

function Memory.Update()
    for _, data in pairs(Memory) do -- update key sections
        if type(data) == "table" and data.Update then
            data:Update()
        end
    end

    -- update all objects if the number of objects has changed
    local objListAddress = ReadValue32(0x809A9240)
    local objListStart = ReadValue32(objListAddress + 0x30)
    local objCount = ReadValue32(objListAddress + 0x14)
    
    if objCount ~= #Memory.Objects then
        ObjectAddrIdMap = {}
        Memory.Objects = setmetatable({StartAddress = objListAddress}, OBJ_IDX_SEARCH_MT)
        for i = 1, objCount do 
            local objAddress = ReadValue32(objListStart+4*i)
            ObjectAddrIdMap[objAddress] = i
            Memory.Objects[i] = Memory.NewObject(objAddress)
            if Memory.Objects[i].Name == "MarioNo" then -- same for Luigi
                --Memory.Player = Objects[i]
            end
        end
    end

    if objCount >= 5 then -- Mario/Luigi's Address (TODO: Figure out cases where it isn't the 5th address ie Bubble Breeze)
        --Memory.Player = Memory.Objects[5]
    end
end

setmetatable(Memory.Player, {
    -- Abstraction once we know more obj specific data: Memory.ObjectOffsets[objName][key]
    __index = function(self, key)
        if Memory.PlayerObjectOffsets[key] == nil then
            return nil
        end
        local addr = PlayerObjectAddress()
        local datatype = Memory.PlayerObjectOffsets[key][2]
        if addr == nil then -- default values
            if datatype == TYPES.Vec3f then
                return Vec.New({0, 0, 0})
            end
            return 0
        end
        return GETTER(addr + Memory.PlayerObjectOffsets[key][1], datatype)
    end
})

-- look for corresponding function named "_key" to invoke and return its value
-- as long as Thing:Update() is called, this isn't necessary
local AUTO_READ_MT = {
    __index = function(self, key)
        if rawget(self, "_"..key) then
            return rawget(self, "_"..key)()
        end
        return nil
    end
}

setmetatable(Memory.Inputs, AUTO_READ_MT)
setmetatable(Memory.Camera, AUTO_READ_MT)
setmetatable(Memory.Misc, AUTO_READ_MT)

return Memory
