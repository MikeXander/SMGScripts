----- GLOBAL VARIABLES -----
local core = require "SMG2_core"
local vec = require "Vector_Math"

function getILTime()
	return string.format("%.2f", core.StageTime()/60)
end

function onScriptStart()
	MsgBox("Script Opened")
end

function onScriptCancel()
	MsgBox("Script Closed")
	SetScreenText("")
end

function onScriptUpdate()
	local text = ""

	text = text .. "\n===== Speed ====="
	text = text .. string.format("\nY:   %10.6f \nXZ:  %10.6f \nXYZ: %10.6f", core.Spd().Y, core.Spd().XZ, core.Spd().XYZ)

	local v = {core.Spd().X, core.Spd().Y, core.Spd().Z}
	local g = {core.DownGravity().X, core.DownGravity().Y, core.DownGravity().Z}
	local yspd = vec.yspd(v, g)
	local hspd = vec.hspd(v, g)
	text = text .. string.format("\nyspd: %9.3f\nhspd: %9.3f", yspd, hspd)

	text = text .. "\n\n===== Position ====="
	--text = text .. string.format("\nX: %12.6f \nY: %12.6f \nZ: %12.6f", core.PrevPos().X, core.PrevPos().Y, core.PrevPos().Z)
	text = text .. string.format("\nX: %12.6f \nY: %12.6f \nZ: %12.6f", core.Pos().X, core.Pos().Y, core.Pos().Z)

	text = text .. "\n\n===== IL TIME ====="
	text = text .. "\n" .. getILTime()

	text = text .. "\n\n===== Input ====="
	text = text .. "\nX: " .. core.Stick().X .. "\nY: " .. core.Stick().Y

	text = text .. "\n\n===== Velocity ====="
	text = text .. "\nX: " .. core.BaseVelocity().X .. "\nY: " .. core.BaseVelocity().Y .. "\nZ: " .. core.BaseVelocity().Z

	--text = text .. "\n\n===== Tilt ====="
	--text = text .. "\nX: " .. core.Tilt().X .. "\nY: " .. core.Tilt().Y .. "\nZ: " .. core.Tilt().Z

	SetScreenText(text)

	if core.Stick().X == 0 and core.Stick().Y == -1 then
		--local val = io.read("*n")
		--core.changePos(-100, 100, -50)
		--core.setPos(3048, 8152, -6654)
	end

end

function onStateLoaded()
end

function onStateSaved()
end
