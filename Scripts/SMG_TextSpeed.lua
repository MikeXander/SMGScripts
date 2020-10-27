local core = require "SMG_core"
local lastFrame = 0
local lastText = 0
local secondLastText = 0
local totalSpd = 0
local frameCount = 0

function onScriptStart()
	MsgBox("Script Opened")
end

function onScriptCancel()
	MsgBox("Script Closed")
	SetScreenText("")
end

function onScriptUpdate()

	-- only update once per frame
	if GetFrameCount() == lastFrame then return end
	lastFrame = GetFrameCount()

	local currentText = core.TextProgress().textProgress
	local spd = currentText - lastText -- text/frame

	-- if the text goes from zero to non-zero, reset the average speed
	if lastText == 0 and currentText ~= 0 then
		totalSpd = 0
		frameCount = 0
	end

	-- text will drop to a non-zero value when it advances to the next page
	-- reset the average and adjust for the negative speed when it drops
	if currentText < lastText then
		totalSpd = -1 * spd
		frameCount = 0
	end

	-- if the progress has changed update the average speed
	-- sometimes text doesnt increment, so this includes the times the speed is 0
	if currentText ~= secondLastText then
		frameCount = frameCount + 1
		totalSpd = totalSpd + spd
	end

	local text = "\n\n\n\n\n\n\n\n\n" -- enough to put it below standard textboxes
	text = text .. string.format("Text Progress: %4d\n", core.TextProgress().textProgress)
	text = text .. string.format("Text Speed: %7d\n", spd)

	-- because it only stops when the text doesnt progress twice in a row,
	-- it adds an extra frame of zero speed at the end. This is a hacky
	-- way to adjust for that. Meaning, on the 2nd frame of text the
	-- average speed will jump up
	if frameCount <= 1 then
		text = text .. string.format("Average Speed: %10.5f\n", totalSpd / frameCount)
	else
		text = text .. string.format("Average Speed: %10.5f\n", totalSpd / (frameCount - 1))
	end

	SetScreenText(text)

	lastText = currentText
	secondLastText = lastText
end
