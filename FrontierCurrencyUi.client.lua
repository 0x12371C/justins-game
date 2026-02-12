-- Frontier currency HUD mockup for Roblox Studio + Rojo.
-- Sync path: src/client/FrontierCurrencyUi.client.lua

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

if not RunService:IsClient() then
	error("FrontierCurrencyUi.client.lua must run as a LocalScript on the client.")
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "FrontierCurrencyDemo"

-- Paste Roblox asset IDs here once imported in Studio (ImageId, not Decal page id).
local ASSET_IDS = {
	emeraldIcon = "rbxassetid://95988623348342",
	purpleGemIcon = "rbxassetid://79230156961338",
}

local function asAssetId(raw: string?): string?
	if not raw or raw == "" then
		return nil
	end

	if string.find(raw, "rbxassetid://", 1, true) then
		return raw
	end

	if string.match(raw, "^%d+$") then
		return "rbxassetid://" .. raw
	end

	return raw
end

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

type CurrencyBarConfig = {
	iconText: string,
	amountText: string,
	accentColor: Color3,
	iconBaseColor: Color3,
	textColor: Color3,
	delay: number,
	iconImageId: string?,
}

local function addFacet(
	parent: Instance,
	color: Color3,
	transparency: number,
	position: UDim2,
	size: UDim2,
	rotation: number,
	zIndex: number
)
	local facet = Instance.new("Frame")
	facet.BackgroundColor3 = color
	facet.BackgroundTransparency = transparency
	facet.BorderSizePixel = 0
	facet.Position = position
	facet.Size = size
	facet.Rotation = rotation
	facet.ZIndex = zIndex
	facet.Parent = parent
	addCorner(facet, 2)
end

local function createCurrencyBar(parent: Instance, config: CurrencyBarConfig)
	local holder = Instance.new("Frame")
	holder.Name = "CurrencyBar"
	holder.Size = UDim2.fromOffset(500, 84)
	holder.BackgroundTransparency = 1
	holder.Parent = parent

	local panelFinalPos = UDim2.fromOffset(0, 42)

	local panelShadow = Instance.new("Frame")
	panelShadow.Name = "PanelShadow"
	panelShadow.AnchorPoint = Vector2.new(0, 0.5)
	panelShadow.Position = panelFinalPos + UDim2.fromOffset(-24, 4)
	panelShadow.Size = UDim2.fromOffset(446, 58)
	panelShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	panelShadow.BackgroundTransparency = 0.5
	panelShadow.BorderSizePixel = 0
	panelShadow.ZIndex = 3
	panelShadow.Parent = holder

	local panelGlow = Instance.new("Frame")
	panelGlow.Name = "PanelGlow"
	panelGlow.AnchorPoint = Vector2.new(0, 0.5)
	panelGlow.Position = panelFinalPos + UDim2.fromOffset(-25, 2)
	panelGlow.Size = UDim2.fromOffset(448, 60)
	panelGlow.BackgroundColor3 = config.accentColor
	panelGlow.BackgroundTransparency = 0.8
	panelGlow.BorderSizePixel = 0
	panelGlow.ZIndex = 4
	panelGlow.Parent = holder

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = panelFinalPos + UDim2.fromOffset(-24, 0)
	panel.Size = UDim2.fromOffset(446, 58)
	panel.BackgroundColor3 = Color3.fromRGB(16, 17, 24)
	panel.BorderSizePixel = 0
	panel.ZIndex = 6
	panel.ClipsDescendants = false
	panel.Parent = holder

	local leftWing = Instance.new("Frame")
	leftWing.Name = "LeftWing"
	leftWing.Position = UDim2.fromOffset(-8, 7)
	leftWing.Size = UDim2.fromOffset(14, 42)
	leftWing.Rotation = -13
	leftWing.BackgroundColor3 = panel.BackgroundColor3
	leftWing.BorderSizePixel = 0
	leftWing.ZIndex = 6
	leftWing.Parent = panel

	local rightWing = Instance.new("Frame")
	rightWing.Name = "RightWing"
	rightWing.Position = UDim2.new(1, -6, 0, 7)
	rightWing.Size = UDim2.fromOffset(14, 42)
	rightWing.Rotation = 13
	rightWing.BackgroundColor3 = panel.BackgroundColor3
	rightWing.BorderSizePixel = 0
	rightWing.ZIndex = 6
	rightWing.Parent = panel

	local panelFace = Instance.new("Frame")
	panelFace.Name = "PanelFace"
	panelFace.Position = UDim2.fromOffset(4, 4)
	panelFace.Size = UDim2.new(1, -8, 1, -10)
	panelFace.BackgroundColor3 = Color3.fromRGB(13, 14, 20)
	panelFace.BackgroundTransparency = 0.06
	panelFace.BorderSizePixel = 0
	panelFace.ZIndex = 7
	panelFace.Parent = panel

	local panelGradient = Instance.new("UIGradient")
	panelGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(29, 31, 42)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(20, 21, 30)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(12, 13, 19)),
	})
	panelGradient.Rotation = 180
	panelGradient.Parent = panelFace

	local panelStroke = Instance.new("UIStroke")
	panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	panelStroke.Color = config.accentColor
	panelStroke.Transparency = 0.24
	panelStroke.Thickness = 1.6
	panelStroke.Parent = panel

	local topEdge = Instance.new("Frame")
	topEdge.Name = "TopEdge"
	topEdge.Position = UDim2.fromOffset(18, 2)
	topEdge.Size = UDim2.new(1, -76, 0, 2)
	topEdge.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	topEdge.BackgroundTransparency = 0.62
	topEdge.BorderSizePixel = 0
	topEdge.ZIndex = 8
	topEdge.Parent = panel

	local accentGlow = Instance.new("Frame")
	accentGlow.Name = "AccentGlow"
	accentGlow.AnchorPoint = Vector2.new(0.5, 1)
	accentGlow.Position = UDim2.fromScale(0.5, 1)
	accentGlow.Size = UDim2.new(1, -30, 0, 4)
	accentGlow.BackgroundColor3 = config.accentColor
	accentGlow.BackgroundTransparency = 0.1
	accentGlow.BorderSizePixel = 0
	accentGlow.ZIndex = 8
	accentGlow.Parent = panel
	addCorner(accentGlow, 3)

	addFacet(panel, Color3.fromRGB(12, 13, 18), 0, UDim2.fromOffset(3, 9), UDim2.fromOffset(14, 37), -15, 8)
	addFacet(panel, Color3.fromRGB(12, 13, 18), 0, UDim2.new(1, -18, 0, 9), UDim2.fromOffset(14, 37), 15, 8)
	addFacet(panel, config.accentColor, 0.68, UDim2.fromOffset(4, 14), UDim2.fromOffset(7, 26), -15, 9)
	addFacet(panel, config.accentColor, 0.68, UDim2.new(1, -11, 0, 14), UDim2.fromOffset(7, 26), 15, 9)

	local notch = Instance.new("Frame")
	notch.Name = "Notch"
	notch.AnchorPoint = Vector2.new(0.5, 1)
	notch.Position = UDim2.new(0.52, 0, 1, -1)
	notch.Size = UDim2.fromOffset(48, 8)
	notch.Rotation = -8
	notch.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
	notch.BorderSizePixel = 0
	notch.ZIndex = 9
	notch.Parent = panel

	local notchStroke = Instance.new("UIStroke")
	notchStroke.Color = config.accentColor
	notchStroke.Thickness = 1
	notchStroke.Transparency = 0.33
	notchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	notchStroke.Parent = notch

	local iconWrap = Instance.new("Frame")
	iconWrap.Name = "IconWrap"
	iconWrap.Size = UDim2.fromOffset(50, 50)
	iconWrap.Position = UDim2.fromOffset(7, 4)
	iconWrap.BackgroundColor3 = config.iconBaseColor
	iconWrap.BorderSizePixel = 0
	iconWrap.ZIndex = 10
	iconWrap.Parent = panel
	addCorner(iconWrap, 11)

	local iconGradient = Instance.new("UIGradient")
	iconGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1.00, config.iconBaseColor),
	})
	iconGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 0.15),
		NumberSequenceKeypoint.new(1.00, 0.52),
	})
	iconGradient.Rotation = 120
	iconGradient.Parent = iconWrap

	local iconStroke = Instance.new("UIStroke")
	iconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	iconStroke.Color = Color3.fromRGB(255, 255, 255)
	iconStroke.Transparency = 0.53
	iconStroke.Thickness = 1.2
	iconStroke.Parent = iconWrap

	local iconImageId = asAssetId(config.iconImageId)
	if iconImageId then
		local iconImage = Instance.new("ImageLabel")
		iconImage.Name = "IconImage"
		iconImage.AnchorPoint = Vector2.new(0.5, 0.5)
		iconImage.Position = UDim2.fromScale(0.5, 0.5)
		iconImage.Size = UDim2.fromOffset(42, 42)
		iconImage.BackgroundTransparency = 1
		iconImage.Image = iconImageId
		iconImage.ScaleType = Enum.ScaleType.Fit
		iconImage.ZIndex = 11
		iconImage.Parent = iconWrap
	else
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "IconLabel"
		iconLabel.Size = UDim2.fromScale(1, 1)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = config.iconText
		iconLabel.TextColor3 = Color3.fromRGB(246, 250, 255)
		iconLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		iconLabel.TextStrokeTransparency = 0.55
		iconLabel.TextScaled = true
		iconLabel.Font = Enum.Font.GothamBlack
		iconLabel.ZIndex = 11
		iconLabel.Parent = iconWrap
	end

	local amount = Instance.new("TextLabel")
	amount.Name = "Amount"
	amount.BackgroundTransparency = 1
	amount.Position = UDim2.fromOffset(67, 0)
	amount.Size = UDim2.new(1, -137, 1, 0)
	amount.Text = config.amountText
	amount.TextXAlignment = Enum.TextXAlignment.Left
	amount.TextYAlignment = Enum.TextYAlignment.Center
	amount.TextColor3 = config.textColor
	amount.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	amount.TextStrokeTransparency = 0.45
	amount.Font = Enum.Font.GothamBlack
	amount.TextSize = 36
	amount.ZIndex = 10
	amount.Parent = panel

	local amountGradient = Instance.new("UIGradient")
	amountGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1.00, config.textColor),
	})
	amountGradient.Rotation = 90
	amountGradient.Parent = amount

	local plusFinalPos = UDim2.fromOffset(430, 42)

	local plusShadow = Instance.new("Frame")
	plusShadow.Name = "PlusShadow"
	plusShadow.AnchorPoint = Vector2.new(0, 0.5)
	plusShadow.Position = plusFinalPos + UDim2.fromOffset(-24, 4)
	plusShadow.Size = UDim2.fromOffset(48, 44)
	plusShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	plusShadow.BackgroundTransparency = 0.45
	plusShadow.BorderSizePixel = 0
	plusShadow.ZIndex = 10
	plusShadow.Parent = holder

	local plusButton = Instance.new("TextButton")
	plusButton.Name = "PlusButton"
	plusButton.AnchorPoint = Vector2.new(0, 0.5)
	plusButton.Position = plusFinalPos + UDim2.fromOffset(-24, 0)
	plusButton.Size = UDim2.fromOffset(48, 44)
	plusButton.BackgroundColor3 = config.accentColor
	plusButton.BorderSizePixel = 0
	plusButton.ClipsDescendants = true
	plusButton.Text = "+"
	plusButton.TextColor3 = Color3.fromRGB(247, 252, 255)
	plusButton.TextSize = 32
	plusButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	plusButton.TextStrokeTransparency = 0.6
	plusButton.Font = Enum.Font.GothamBlack
	plusButton.AutoButtonColor = true
	plusButton.ZIndex = 12
	plusButton.Parent = holder

	addFacet(plusButton, Color3.fromRGB(8, 9, 13), 0.5, UDim2.fromOffset(-1, 7), UDim2.fromOffset(10, 30), -18, 13)
	addFacet(plusButton, Color3.fromRGB(8, 9, 13), 0.5, UDim2.new(1, -9, 0, 7), UDim2.fromOffset(10, 30), 18, 13)
	addFacet(plusButton, Color3.fromRGB(255, 255, 255), 0.74, UDim2.fromOffset(8, 1), UDim2.new(1, -16, 0, 2), 0, 13)

	local plusGradient = Instance.new("UIGradient")
	plusGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1.0, config.accentColor),
	})
	plusGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.18),
		NumberSequenceKeypoint.new(1.0, 0.52),
	})
	plusGradient.Rotation = 140
	plusGradient.Parent = plusButton

	local plusStroke = Instance.new("UIStroke")
	plusStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	plusStroke.Color = Color3.fromRGB(255, 255, 255)
	plusStroke.Transparency = 0.36
	plusStroke.Thickness = 2
	plusStroke.Parent = plusButton

	local buttonScale = Instance.new("UIScale")
	buttonScale.Parent = plusButton

	plusButton.Activated:Connect(function()
		print(("TODO: open shop flow for %s"):format(config.amountText))
	end)

	task.delay(config.delay, function()
		TweenService:Create(
			panel,
			TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Position = panelFinalPos }
		):Play()

		TweenService:Create(
			panelShadow,
			TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Position = panelFinalPos + UDim2.fromOffset(0, 4) }
		):Play()
		TweenService:Create(
			panelGlow,
			TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Position = panelFinalPos + UDim2.fromOffset(-1, 2) }
		):Play()

		TweenService:Create(
			plusButton,
			TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Position = plusFinalPos }
		):Play()

		TweenService:Create(
			plusShadow,
			TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Position = plusFinalPos + UDim2.fromOffset(0, 4) }
		):Play()
	end)

	task.delay(config.delay + 0.28, function()
		TweenService:Create(
			buttonScale,
			TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Scale = 1.055 }
		):Play()
	end)
end

clearExistingGui()

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = screenGui

local hudScale = Instance.new("UIScale")
hudScale.Name = "HudScale"
hudScale.Scale = 1
hudScale.Parent = root

local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
if viewport.X < 1366 then
	hudScale.Scale = 0.88
elseif viewport.X > 2400 then
	hudScale.Scale = 1.12
end

local hudStack = Instance.new("Frame")
hudStack.Name = "HudStack"
hudStack.AnchorPoint = Vector2.new(0, 1)
hudStack.Position = UDim2.fromScale(0.035, 0.775)
hudStack.Size = UDim2.fromOffset(500, 184)
hudStack.BackgroundTransparency = 1
hudStack.Parent = root

local list = Instance.new("UIListLayout")
list.FillDirection = Enum.FillDirection.Vertical
list.HorizontalAlignment = Enum.HorizontalAlignment.Left
list.VerticalAlignment = Enum.VerticalAlignment.Top
list.Padding = UDim.new(0, 16)
list.Parent = hudStack

createCurrencyBar(hudStack, {
	iconText = "$",
	amountText = "$ 25,000",
	accentColor = Color3.fromRGB(32, 236, 190),
	iconBaseColor = Color3.fromRGB(34, 185, 158),
	textColor = Color3.fromRGB(244, 250, 255),
	delay = 0.00,
	iconImageId = ASSET_IDS.emeraldIcon,
})

createCurrencyBar(hudStack, {
	iconText = "G",
	amountText = "500",
	accentColor = Color3.fromRGB(130, 100, 255),
	iconBaseColor = Color3.fromRGB(88, 70, 216),
	textColor = Color3.fromRGB(243, 238, 255),
	delay = 0.08,
	iconImageId = ASSET_IDS.purpleGemIcon,
})
