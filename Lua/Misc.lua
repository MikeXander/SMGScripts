local Vec = require "Vector_Math"
local Memory = require "Memory"

-------- functions for displaying info --------

-- BinaryString(5, 8) -> "00000101"
function BinaryString(value, length)
	local text = ""
	while length > 0 do
		text = (value & 1) .. text
		value = value >> 1
        length = length - 1
	end
	return text
end

-- recursively converts a table into a string
-- separates keys onto new lines
function TableString(t, indent)
	if indent == nil then
		indent = ""
	end
	if type(t) == "number" or type(t) == "string" then
		return indent .. t
	elseif type(t) == "boolean" then
		return indent ..  (t and "true" or "false")
	elseif type(t) == "function" then
		return indent .. "function()"
	end
	local text = indent .. "{\n"
	for key, val in pairs(t) do
		if #text > #indent + 2 then
			text = text .. ",\n"
		end
		text = text .. indent .. "  [" .. key .. "] = " .. TableString(val, indent .. "  ")
	end
	return text .. "\n" .. indent .. "}"
end

function DisplayValueOrdered(title, data, order, format, binarySize)
	local text = "\n".."==== " .. title .. " ====\n"
	local length = 0
	for k,v in pairs(order) do length = length + 1 end
	for i = 1, length do
		if binarySize ~= nil then
			text = text .. order[i] .. ": " .. BinaryString(data[order[i]], binarySize) .. "\n"
		elseif format == nil then
			text = text .. order[i] .. ": " .. data[order[i]] .. "\n"
		else
			text = text .. order[i] .. ": " .. string.format(format, data[order[i]]) .. "\n"
		end
	end
	return text
end

function DisplayValue(title, data, format) -- doesnt do padding
	local text = "\n"
	if text ~= "" then text = "\n==== " .. title .. " ====\n" end
	for key,value in pairs(data) do
		if format == nil then
			text = text .. key .. ": " .. value .. "\n"
		else
			text = text .. key .. ": " .. string.format(format, value) .. "\n"
		end
	end
	return text
end

-------- functions for finding info --------

-- returns the key corresponding to item in table t or nil if not found
function table.contains(t, item)
	for key, value in pairs(t) do
		if value == item then
			return key
		end
	end
	return nil
end

-------- functions for saving info --------

function ExportObjects(filename)
    if filename:match("%..+$") ~= ".csv" then
        filename = filename .. ".csv"
    end
    local f = io.open(filename, 'w')
    f:write("Address,Name,PosX,PosY,PosZ,RotX,RotY,RotZ,SizeX,SizeY,SizeZ,SpeedX,SpeedY,SpeedZ\n")
    Memory.Update()
    for i, obj in ipairs(Memory.Objects) do
        if obj.Address >= 0x80000000 then
            obj:Update()
            f:write(string.format(
                "%X,%s,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n",
                obj.Address,
                obj.Name,
                obj.Position.X, obj.Position.Y, obj.Position.Z,
                obj.Rotation.X, obj.Rotation.Y, obj.Rotation.Z, 
                obj.Size.X, obj.Size.Y, obj.Size.Z, 
                obj.Speed.X, obj.Speed.Y, obj.Speed.Z
            ))
        end
    end
    f:close()
end

-- export select info about the player
-- mode is optional (you can provide 'a' to skip adding the header)
-- Example: ExportPlayerInfo("mario.csv", {"Position", "Tilt"})
-- untested
function ExportPlayerInfo(filename, properties, mode)
	if properties == nil then
		properties = {"Position"}
	end
    if filename:match("%..+$") ~= ".csv" then
        filename = filename .. ".csv"
    end
    if mode == nil then
        mode = 'w'
    end
    local f = io.open(filename, mode)
    if mode == 'w' then -- add header
        local header = "frame"
        for i, key in ipairs(properties) do
            if Memory.PlayerObjectOffsets[key][2] == Memory.TYPES.Vec3f then
                header = header .. string.format(",%sX,%sY,%sZ", key, key, key)
            else
                header = header .. "," .. key
            end
        end
        f:write(header .. "\n")
    end
    local data = "" .. GetFrameCount()
    Memory.Player:Update()
    for i = 1, #properties do
        local key = properties[i]
        if Memory.PlayerObjectOffsets[key][2] == Memory.TYPES.Vec3f then
            data = data .. "," .. Memory.Player[key].X
            data = data .. "," .. Memory.Player[key].Y
            data = data .. "," .. Memory.Player[key].Z
        else
            data = data .. "," .. Memory.Player[key]
        end
    end
    f:write(data .. "\n")
    f:close()
end

-------- completely miscellaneous function --------

-- pitch is from 0 to 180 degrees
-- yaw is from 0 to 360 degrees
-- returns {yaw, pitch, difference_from_goal_angle}
local yaw = 0
local function GetAngle(v, goal_angle) -- input speed or velocity
	local g = Memory.Player.Gravity
	local pitch = Vec.Angle(g, {0, -1, 0}) -- angle between g and -y_hat (vertical axis)

	local absolute_hspd = Vec.ProjectPlane(v, {0, 1, 0}) -- hspd along horizontal plane

	if #absolute_hspd > Vec.EPSILON then -- only update when possible

		-- angle between hspd and z_hat (choice of x_hat, z_hat is arbitrary)
		yaw = Vec.Angle({0, 0, 1}, absolute_hspd)

		--local relative_hspd = Vec.ProjectPlane(v, g)
		--local cam_to_mario = Memory.Player.Position - Memory.Camera.Position
		--cam_to_mario = Vec.ProjectPlane(cam_to_mario, {0, 1, 0}) --g)
		--yaw = Vec.Angle(cam_to_mario, absolute_hspd) --relative_hspd)

		-- get which side of x-axis it is
		local _, dir = Vec.Project(absolute_hspd, {0, 0, 1})
		--local _, dir = Vec.Project(absolute_hspd, cam_to_mario)
		
		if dir == -1 then
			yaw = 2 * math.pi - yaw
		end
	end

	if goal_angle == nil then
		return {math.deg(yaw), math.deg(pitch), 0}
	else
		return {math.deg(yaw), math.deg(pitch), math.deg(yaw) - goal_angle}
	end
end

function AngleInfo(velocity, goal_angle, goal_point)
	if velocity == nil then
		velocity = Memory.Player.Velocity
	end
	local angles = GetAngle(velocity, goal_angle)

	if goal_angle ~= nil then
		return string.format("\n==== Moving Angle ====\nYaw:   %4.3f (%.3f)\nPitch: %4.3f\n", angles[1], angles[3], angles[2])
	elseif goal_point ~= nil then
		local desired_v = goal_point - Memory.Player.Position
		local desired_angle = GetAngle(desired_v)
		return string.format("\n==== Moving Angle ====\nYaw:   %4.3f (%.3f)\nPitch: %4.3f\n", angles[1], desired_angle[1], angles[2])
	else
		return string.format("\n==== Moving Angle ====\nYaw:   %4.3f\nPitch: %4.3f\n", angles[1], angles[2])
	end
end

-- TODO: max relative height (max jump height = max(vec.proj(jump_dist, ugrav)))
local jump_start_pos = Vec.New({0, 0, 0})
local jump_end_pos = Vec.New({0, 0, 0})
local max_jump_height = 0
local previous_state = -1
function JumpStats()
	local jump_vec = Vec.New({0, 0, 0})

	-- 1 means on ground, 0 means in air (not always accurate during walking transitions?)
	local state = Memory.Misc.Grounded

	-- ground to air, set start point
	if previous_state == 1 and state == 0 then
		jump_start_pos = Memory.Player.PreviousPosition
		jump_end_pos = Memory.Player.Position
		max_jump_height = 0

	-- air to ground, set end point
	elseif previous_state == 0 and state == 1 then
		jump_end_pos = Memory.Player.Position

	-- air to air, update latest pos
	elseif previous_state == 0 and state == 0 then
		jump_end_pos = Memory.Player.Position
	end
	-- don't update when staying on ground to see the last jump dist
	previous_state = state

	local jump_vec = jump_end_pos - jump_start_pos
	local dist = #jump_vec
	local hdist = Vec.HSpd(jump_vec, Memory.Player.Gravity)
	max_jump_height = math.max(Vec.YSpd(jump_vec, Memory.Player.ReverseGravity), max_jump_height)

	return string.format("\n==== Jump Stats ====\nhdist: %13.3f\ndist: %14.3f\nMax Height: %8.3f\n", hdist, dist, max_jump_height)
end

-- lists the num clostest objects to pos
-- defaults to 3, and the player position
function ClosestObjects(num, pos)
	if num == nil then
		num = 3
	end
	if pos == nil then
		pos = Memory.Player.Position
	end
	local objs = {} -- [1] = closest {dist, index}
	for i, obj in ipairs(Memory.Objects) do
		local dist = #(pos - obj.Position)
		local insert_idx = 1
		while insert_idx <= num and objs[insert_idx] and dist > objs[insert_idx][1] do
			insert_idx = insert_idx + 1
		end
		objs[insert_idx] = {dist, i}
	end
	table.remove(objs, num + 1)
	for i = 1, num do
		objs[i] = Memory.Objects[objs[i][2]]
	end
	return objs
end
