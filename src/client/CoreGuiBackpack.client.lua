local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

if not RunService:IsClient() then
	return
end

local function enableBackpack()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	end)
end

enableBackpack()
task.defer(enableBackpack)
task.delay(1, enableBackpack)
