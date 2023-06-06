local Vec = require "Vector_Math"
local Tilt = require "Tilt_Bonus"
local Memory = require "Memory"
require "Misc" -- load some helper functions

local lastFrame = -1
function onScriptUpdate()
	if GetFrameCount() == lastFrame then return end -- only run once per frame
	lastFrame = GetFrameCount()
	Memory.Update()
	local text = "\n"
	
	text = text .. "Stage Time: " .. Memory.Misc.StageTime .. " " .. ReadValue32(0x806A2508) .. "\n"
	--text = text .. "Grounded: " .. Memory.Misc.Grounded .. "\n"
	--text = text .. string.format("Tilt Bonus: %.3f\n", Tilt.GetBonus())
	--text = text .. JumpStats()
	--text = text .. string.format("Jump: %s (0x%X)\n",  Memory.JumpType[Memory.Player.LastJumpType], Memory.Player.LastJumpType)
	--text = text .. AngleInfo(Memory.Player.Velocity) -- angle of motion compared to fixed axis
	--text = text .. string.format("Actual Angle: %5.3f\n", Memory.Player.Rotation.Y)
	--text = text .. DisplayValueOrdered("Input", Memory.Inputs.Stick, {"X", "Y"})
	--text = text .. DisplayValueOrdered("Gravity", Memory.Player.Gravity, {"X", "Y", "Z"}, "%12.5f")
	--text = text .. DisplayValueOrdered("Velocity", Memory.Player.Velocity, {"X", "Y", "Z"}, "%12.3f")
	text = text .. DisplayValueOrdered("Position", Memory.Player.Position, {"X", "Y", "Z"}, "%12.3f")
	
	-- Note: change in position (Memory.Player.Position - Memory.Player.PreviousPosition) is different
	local speeds = {
		YSpd = Vec.YSpd(Memory.Player.Velocity, Memory.Player.ReverseGravity),
		HSpd = Vec.HSpd(Memory.Player.Velocity, Memory.Player.ReverseGravity),
		XYZ = #Memory.Player.Velocity
	}
	text = text .. DisplayValueOrdered("Speed", speeds, {"YSpd", "HSpd", "XYZ"}, "%12.3f")

	text = text .. "\nWiimote Spin Suppress Timer: " .. Memory.Player.WmSpinSuppressTimer .. "\n"
	text = text .. "Spin Hitbox Timer: " .. Memory.Player.SpinHitboxTimer .. "\n"

	SetScreenText(text)
end

function onScriptStart()
	local id = GetGameID()
	if id ~= "RMGE01" and id ~= "RMGJ01" and id ~= "RMGP01" then -- safeguard
		CancelScript()
	end
end

function onScriptCancel()
	SetScreenText("")
end

function onStateLoaded() end

function onStateSaved() end
