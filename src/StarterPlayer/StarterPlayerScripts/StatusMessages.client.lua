local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "StatusMessages"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local container = Instance.new("Frame")
container.Name = "Container"
container.AnchorPoint = Vector2.new(0.5, 0)
container.Position = UDim2.new(0.5, 0, 0, 92)
container.Size = UDim2.fromOffset(560, 240)
container.BackgroundTransparency = 1
container.Parent = gui

local layout = Instance.new("UIListLayout")
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Top
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = container

local priorities = {
	BossMessage = 1,
	QuestMessage = 2,
	BountyMessage = 3,
	LootMessage = 4,
	CrystalMessage = 5,
	DodgeMessage = 6,
	PortalMessage = 7,
	ShopMessage = 8,
	AchievementMessage = 9,
	ProfileLoadFailed = 10,
}

local function show(text, priority)
	if type(text) ~= "string" or text == "" then return end
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(520, 34)
	label.BackgroundTransparency = 0.18
	label.Text = text
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.LayoutOrder = priority or 99
	label.Parent = container
	Instance.new("UICorner", label).CornerRadius = UDim.new(0, 8)

	local targetPosition = label.Position
	label.Position = UDim2.new(0, 0, 0, -8)
	label.TextTransparency = 1
	TweenService:Create(label, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = targetPosition, TextTransparency = 0 }):Play()

	task.delay(2.8, function()
		if not label.Parent then return end
		local fade = TweenService:Create(label, TweenInfo.new(0.2), { TextTransparency = 1, BackgroundTransparency = 1 })
		fade:Play()
		fade.Completed:Connect(function() if label.Parent then label:Destroy() end end)
	end)
end

local function bind(attribute)
	local last = ""
	local function changed()
		local value = player:GetAttribute(attribute)
		if type(value) ~= "string" or value == "" or value == last then return end
		last = value
		show(value, priorities[attribute])
	end
	player:GetAttributeChangedSignal(attribute):Connect(changed)
	changed()
end

for attribute in pairs(priorities) do bind(attribute) end
