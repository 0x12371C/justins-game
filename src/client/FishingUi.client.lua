local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

if not RunService:IsClient() then
	error("FishingUi.client.lua must run on the client.")
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "FishingMiniGameUi"

local function clearExistingGui()
	local old = playerGui:FindFirstChild(GUI_NAME)
	if old then
		old:Destroy()
	end
end

local function addCorner(target: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = target
end

local function addStroke(target: GuiObject, color: Color3, transparency: number, thickness: number)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Transparency = transparency
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = target
end

local function addFacet(parent: Instance, color: Color3, transparency: number, pos: UDim2, size: UDim2, rot: number, z: number)
	local facet = Instance.new("Frame")
	facet.BackgroundColor3 = color
	facet.BackgroundTransparency = transparency
	facet.BorderSizePixel = 0
	facet.Position = pos
	facet.Size = size
	facet.Rotation = rot
	facet.ZIndex = z
	facet.Parent = parent
	addCorner(facet, 2)
end

clearExistingGui()

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui
screenGui.Enabled = false

local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Size = UDim2.fromOffset(780, 430)
root.BackgroundTransparency = 1
root.Parent = screenGui

local panelShadow = Instance.new("Frame")
panelShadow.Name = "PanelShadow"
panelShadow.Position = UDim2.fromOffset(7, 8)
panelShadow.Size = UDim2.fromScale(1, 1)
panelShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
panelShadow.BackgroundTransparency = 0.42
panelShadow.BorderSizePixel = 0
panelShadow.ZIndex = 1
panelShadow.Parent = root
addCorner(panelShadow, 30)

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromScale(1, 1)
panel.BackgroundColor3 = Color3.fromRGB(21, 58, 141)
panel.BorderSizePixel = 0
panel.ClipsDescendants = false
panel.ZIndex = 2
panel.Parent = root
addCorner(panel, 28)
addStroke(panel, Color3.fromRGB(17, 38, 98), 0.15, 5)

local panelGrad = Instance.new("UIGradient")
panelGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(42, 95, 194)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(24, 72, 170)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(16, 52, 128)),
})
panelGrad.Rotation = 90
panelGrad.Parent = panel

addFacet(panel, Color3.fromRGB(14, 41, 104), 0, UDim2.fromOffset(-14, 54), UDim2.fromOffset(24, 300), -14, 2)
addFacet(panel, Color3.fromRGB(14, 41, 104), 0, UDim2.new(1, -10, 0, 54), UDim2.fromOffset(24, 300), 14, 2)
addFacet(panel, Color3.fromRGB(45, 122, 255), 0.28, UDim2.fromOffset(42, 10), UDim2.new(1, -84, 0, 4), 0, 3)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.fromScale(0.5, 0.02)
title.Size = UDim2.fromOffset(240, 62)
title.BackgroundTransparency = 1
title.Text = "Fishing"
title.Font = Enum.Font.GothamBlack
title.TextColor3 = Color3.fromRGB(240, 244, 255)
title.TextStrokeColor3 = Color3.fromRGB(8, 19, 55)
title.TextStrokeTransparency = 0.25
title.TextScaled = true
title.ZIndex = 5
title.Parent = panel

local playArea = Instance.new("Frame")
playArea.Name = "PlayArea"
playArea.Position = UDim2.fromOffset(28, 72)
playArea.Size = UDim2.new(1, -56, 1, -120)
playArea.BackgroundColor3 = Color3.fromRGB(16, 93, 178)
playArea.BackgroundTransparency = 0.12
playArea.BorderSizePixel = 0
playArea.ZIndex = 3
playArea.Parent = panel
addCorner(playArea, 18)
addStroke(playArea, Color3.fromRGB(80, 193, 255), 0.4, 2)

local waterGrad = Instance.new("UIGradient")
waterGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(50, 162, 222)),
	ColorSequenceKeypoint.new(0.52, Color3.fromRGB(22, 126, 206)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(14, 82, 167)),
})
waterGrad.Rotation = 90
waterGrad.Parent = playArea

local waveLine = Instance.new("Frame")
waveLine.Name = "WaveLine"
waveLine.AnchorPoint = Vector2.new(0.5, 0.5)
waveLine.Position = UDim2.fromScale(0.5, 0.56)
waveLine.Size = UDim2.new(0.9, 0, 0, 3)
waveLine.BackgroundColor3 = Color3.fromRGB(124, 240, 255)
waveLine.BackgroundTransparency = 0.38
waveLine.BorderSizePixel = 0
waveLine.ZIndex = 4
waveLine.Parent = playArea
addCorner(waveLine, 3)

local rod = Instance.new("Frame")
rod.Name = "Rod"
rod.AnchorPoint = Vector2.new(0, 0.5)
rod.Position = UDim2.fromScale(0.08, 0.62)
rod.Size = UDim2.fromOffset(198, 9)
rod.Rotation = -24
rod.BackgroundColor3 = Color3.fromRGB(121, 77, 43)
rod.BorderSizePixel = 0
rod.ZIndex = 5
rod.Parent = playArea
addCorner(rod, 4)
addStroke(rod, Color3.fromRGB(64, 40, 24), 0.45, 1)

local line = Instance.new("Frame")
line.Name = "Line"
line.AnchorPoint = Vector2.new(0, 0.5)
line.Position = UDim2.fromScale(0.29, 0.55)
line.Size = UDim2.fromOffset(188, 2)
line.Rotation = 11
line.BackgroundColor3 = Color3.fromRGB(231, 247, 255)
line.BackgroundTransparency = 0.2
line.BorderSizePixel = 0
line.ZIndex = 5
line.Parent = playArea
addCorner(line, 2)

local bobber = Instance.new("Frame")
bobber.Name = "Bobber"
bobber.AnchorPoint = Vector2.new(0.5, 0.5)
bobber.Position = UDim2.fromScale(0.54, 0.59)
bobber.Size = UDim2.fromOffset(30, 30)
bobber.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
bobber.BorderSizePixel = 0
bobber.ZIndex = 6
bobber.Parent = playArea
addCorner(bobber, 999)
addStroke(bobber, Color3.fromRGB(125, 36, 29), 0.4, 1)

local bobberBottom = Instance.new("Frame")
bobberBottom.Name = "Bottom"
bobberBottom.AnchorPoint = Vector2.new(0.5, 1)
bobberBottom.Position = UDim2.fromScale(0.5, 1)
bobberBottom.Size = UDim2.fromScale(1, 0.52)
bobberBottom.BackgroundColor3 = Color3.fromRGB(240, 70, 60)
bobberBottom.BorderSizePixel = 0
bobberBottom.ZIndex = 6
bobberBottom.Parent = bobber
addCorner(bobberBottom, 999)

local meterShell = Instance.new("Frame")
meterShell.Name = "TensionMeter"
meterShell.AnchorPoint = Vector2.new(1, 0.5)
meterShell.Position = UDim2.new(0.97, 0, 0.52, 0)
meterShell.Size = UDim2.fromOffset(74, 220)
meterShell.BackgroundColor3 = Color3.fromRGB(17, 66, 116)
meterShell.BorderSizePixel = 0
meterShell.ZIndex = 5
meterShell.Parent = playArea
addCorner(meterShell, 26)
addStroke(meterShell, Color3.fromRGB(58, 211, 220), 0.2, 3)

local meterFill = Instance.new("Frame")
meterFill.Name = "Fill"
meterFill.Position = UDim2.fromOffset(16, 12)
meterFill.Size = UDim2.new(1, -32, 1, -24)
meterFill.BackgroundColor3 = Color3.fromRGB(255, 128, 64)
meterFill.BorderSizePixel = 0
meterFill.ZIndex = 6
meterFill.Parent = meterShell
addCorner(meterFill, 16)

local meterGrad = Instance.new("UIGradient")
meterGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(224, 63, 58)),
	ColorSequenceKeypoint.new(0.45, Color3.fromRGB(245, 188, 61)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(96, 225, 92)),
})
meterGrad.Rotation = 90
meterGrad.Parent = meterFill

local fish = Instance.new("TextLabel")
fish.Name = "FishMarker"
fish.AnchorPoint = Vector2.new(1, 0.5)
local fishStartPosition = UDim2.new(0.82, 0, 0.5, 0)
local fishEndPosition = UDim2.new(0.82, 0, 0.76, 0)
fish.Position = fishStartPosition
fish.Size = UDim2.fromOffset(38, 22)
fish.BackgroundTransparency = 1
fish.Text = "><>"
fish.Font = Enum.Font.GothamBold
fish.TextScaled = true
fish.TextColor3 = Color3.fromRGB(12, 102, 130)
fish.TextStrokeColor3 = Color3.fromRGB(4, 43, 54)
fish.TextStrokeTransparency = 0.4
fish.ZIndex = 7
fish.Parent = meterShell

local catchBar = Instance.new("Frame")
catchBar.Name = "CatchBar"
catchBar.AnchorPoint = Vector2.new(0, 1)
catchBar.Position = UDim2.new(0.05, 0, 0.97, 0)
catchBar.Size = UDim2.new(0.72, 0, 0, 38)
catchBar.BackgroundColor3 = Color3.fromRGB(18, 43, 102)
catchBar.BorderSizePixel = 0
catchBar.ZIndex = 6
catchBar.Parent = panel
addCorner(catchBar, 12)
addStroke(catchBar, Color3.fromRGB(59, 156, 255), 0.26, 2)

local zoneColors = {
	Color3.fromRGB(226, 74, 59),
	Color3.fromRGB(236, 131, 50),
	Color3.fromRGB(240, 198, 61),
	Color3.fromRGB(152, 223, 78),
	Color3.fromRGB(54, 226, 128),
}

for i, color in ipairs(zoneColors) do
	local seg = Instance.new("Frame")
	seg.Name = "Zone" .. tostring(i)
	seg.Size = UDim2.new(1 / #zoneColors, -4, 1, -8)
	seg.Position = UDim2.new((i - 1) / #zoneColors, 2, 0, 4)
	seg.BackgroundColor3 = color
	seg.BorderSizePixel = 0
	seg.ZIndex = 7
	seg.Parent = catchBar
	addCorner(seg, 4)
end

local marker = Instance.new("Frame")
marker.Name = "Marker"
marker.AnchorPoint = Vector2.new(0.5, 0.5)
local markerStartPosition = UDim2.new(0.07, 0, 0.5, 0)
local markerEndPosition = UDim2.new(0.93, 0, 0.5, 0)
marker.Position = markerStartPosition
marker.Size = UDim2.fromOffset(8, 32)
marker.BackgroundColor3 = Color3.fromRGB(242, 247, 255)
marker.BorderSizePixel = 0
marker.ZIndex = 8
marker.Parent = catchBar
addCorner(marker, 4)
addStroke(marker, Color3.fromRGB(13, 46, 82), 0.38, 1)

local catchButton = Instance.new("TextButton")
catchButton.Name = "CatchButton"
catchButton.AnchorPoint = Vector2.new(1, 1)
catchButton.Position = UDim2.new(0.965, 0, 0.985, 0)
catchButton.Size = UDim2.fromOffset(158, 78)
catchButton.BackgroundColor3 = Color3.fromRGB(94, 203, 60)
catchButton.BorderSizePixel = 0
catchButton.Text = "CATCH"
catchButton.TextColor3 = Color3.fromRGB(242, 255, 235)
catchButton.TextStrokeColor3 = Color3.fromRGB(20, 87, 20)
catchButton.TextStrokeTransparency = 0.4
catchButton.TextScaled = true
catchButton.Font = Enum.Font.GothamBlack
catchButton.AutoButtonColor = true
catchButton.ZIndex = 9
catchButton.Parent = panel
addCorner(catchButton, 40)
addStroke(catchButton, Color3.fromRGB(215, 255, 188), 0.2, 3)

local catchGrad = Instance.new("UIGradient")
catchGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(139, 236, 96)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(73, 176, 49)),
})
catchGrad.Rotation = 90
catchGrad.Parent = catchButton

local status = Instance.new("TextLabel")
status.Name = "Status"
status.AnchorPoint = Vector2.new(1, 1)
status.Position = UDim2.new(0.95, 0, 0.83, 0)
status.Size = UDim2.fromOffset(220, 26)
status.BackgroundTransparency = 1
status.Text = "Click CATCH or press Space"
status.TextXAlignment = Enum.TextXAlignment.Right
status.Font = Enum.Font.GothamMedium
status.TextSize = 17
status.TextColor3 = Color3.fromRGB(225, 242, 255)
status.TextTransparency = 0.15
status.ZIndex = 9
status.Parent = panel

local fishTween = TweenService:Create(
	fish,
	TweenInfo.new(0.95, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Position = fishEndPosition }
)

local markerTween = TweenService:Create(
	marker,
	TweenInfo.new(1.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Position = markerEndPosition }
)

local buttonScale = Instance.new("UIScale")
buttonScale.Parent = catchButton

local successMin = 0.62
local successMax = 0.93
local clickLock = false
local statusDefaultText = "Click CATCH or press Space"
local statusDefaultColor = Color3.fromRGB(225, 242, 255)

local function setUiVisible(visible: boolean)
	screenGui.Enabled = visible

	if visible then
		fishTween:Play()
		markerTween:Play()
		return
	end

	fishTween:Pause()
	markerTween:Pause()
	fish.Position = fishStartPosition
	marker.Position = markerStartPosition
	buttonScale.Scale = 1
	clickLock = false
	status.Text = statusDefaultText
	status.TextColor3 = statusDefaultColor
end

local function pulseButton()
	TweenService:Create(buttonScale, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.93 }):Play()
	task.delay(0.1, function()
		TweenService:Create(buttonScale, TweenInfo.new(0.11, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end)
end

local function attemptCatch()
	if clickLock or not screenGui.Enabled then
		return
	end

	clickLock = true
	pulseButton()

	local markerX = marker.Position.X.Scale
	local success = markerX >= successMin and markerX <= successMax

	if success then
		status.Text = "Nice catch!"
		status.TextColor3 = Color3.fromRGB(163, 255, 157)
	else
		status.Text = "Missed timing"
		status.TextColor3 = Color3.fromRGB(255, 183, 158)
	end

	task.delay(0.35, function()
		status.Text = statusDefaultText
		status.TextColor3 = statusDefaultColor
		clickLock = false
	end)
end

catchButton.Activated:Connect(attemptCatch)

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Space and screenGui.Enabled then
		attemptCatch()
	end
end)

local function disconnectAll(connections: { RBXScriptConnection })
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
end

local function isFishingPole(tool: Tool): boolean
	if tool:GetAttribute("IsFishingPole") == true then
		return true
	end

	local nameLower = string.lower(tool.Name)
	local hasFish = string.find(nameLower, "fish", 1, true) ~= nil
	local hasPoleWord = string.find(nameLower, "pole", 1, true) ~= nil or string.find(nameLower, "rod", 1, true) ~= nil
	return hasFish and hasPoleWord
end

local currentPole: Tool? = nil
local poleConnections: { RBXScriptConnection } = {}
local characterConnections: { RBXScriptConnection } = {}

local function clearPoleBinding()
	currentPole = nil
	disconnectAll(poleConnections)
	setUiVisible(false)
end

local function bindPole(tool: Tool)
	clearPoleBinding()
	currentPole = tool

	table.insert(poleConnections, tool.Activated:Connect(function()
		if currentPole ~= tool then
			return
		end
		setUiVisible(true)
	end))

	table.insert(poleConnections, tool.Unequipped:Connect(function()
		if currentPole == tool then
			setUiVisible(false)
		end
	end))

	table.insert(poleConnections, tool.AncestryChanged:Connect(function()
		local character = player.Character
		if currentPole ~= tool then
			return
		end
		if not character or not tool:IsDescendantOf(character) then
			clearPoleBinding()
		end
	end))
end

local function bindCharacter(character: Model)
	disconnectAll(characterConnections)
	clearPoleBinding()

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") and isFishingPole(child) then
			bindPole(child)
			break
		end
	end

	table.insert(characterConnections, character.ChildAdded:Connect(function(child: Instance)
		if child:IsA("Tool") and isFishingPole(child) then
			bindPole(child)
		end
	end))

	table.insert(characterConnections, character.ChildRemoved:Connect(function(child: Instance)
		if child == currentPole then
			clearPoleBinding()
		end
	end))
end

if player.Character then
	bindCharacter(player.Character)
end

player.CharacterAdded:Connect(function(character: Model)
	bindCharacter(character)
end)

player.CharacterRemoving:Connect(function()
	disconnectAll(characterConnections)
	clearPoleBinding()
end)
