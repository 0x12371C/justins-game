local Players = game:GetService("Players")
local StarterPack = game:GetService("StarterPack")

local TOOL_NAME = "Fishing Pole"

local function buildFishingPole(): Tool
	local tool = Instance.new("Tool")
	tool.Name = TOOL_NAME
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool.ToolTip = "Equip and click to fish"
	tool:SetAttribute("IsFishingPole", true)
	return tool
end

local function ensureTemplate(): Tool
	local existing = StarterPack:FindFirstChild(TOOL_NAME)
	if existing and not existing:IsA("Tool") then
		existing:Destroy()
		existing = nil
	end

	if existing and existing:IsA("Tool") then
		existing.RequiresHandle = false
		existing.CanBeDropped = false
		existing:SetAttribute("IsFishingPole", true)
		return existing
	end

	local tool = buildFishingPole()
	tool.Parent = StarterPack
	return tool
end

local template = ensureTemplate()

local function ensureContainerHasPole(container: Instance?)
	if not container then
		return
	end

	local existing = container:FindFirstChild(TOOL_NAME)
	if existing and not existing:IsA("Tool") then
		existing:Destroy()
		existing = nil
	end

	if existing and existing:IsA("Tool") then
		existing.RequiresHandle = false
		existing.CanBeDropped = false
		existing:SetAttribute("IsFishingPole", true)
		return
	end

	local clone = template:Clone()
	clone.Parent = container
end

local function setupPlayer(player: Player)
	local backpack = player:WaitForChild("Backpack")
	ensureContainerHasPole(backpack)
	ensureContainerHasPole(player:FindFirstChild("StarterGear"))

	player.CharacterAdded:Connect(function()
		local nextBackpack = player:WaitForChild("Backpack")
		ensureContainerHasPole(nextBackpack)
	end)
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end
