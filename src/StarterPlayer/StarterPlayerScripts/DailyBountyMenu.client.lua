local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "DailyBountyMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(430, 230)
panel.BackgroundTransparency = 0.08
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(18, 14)
title.Size = UDim2.fromOffset(350, 34)
title.BackgroundTransparency = 1
title.Text = "Daily Bounty"
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local close = Instance.new("TextButton")
close.Position = UDim2.fromOffset(370, 14)
close.Size = UDim2.fromOffset(42, 34)
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextSize = 18
close.Parent = panel
close.Activated:Connect(function() panel.Visible = false end)

local details = Instance.new("TextLabel")
details.Position = UDim2.fromOffset(20, 64)
details.Size = UDim2.fromOffset(390, 105)
details.BackgroundTransparency = 1
details.TextXAlignment = Enum.TextXAlignment.Left
details.TextYAlignment = Enum.TextYAlignment.Top
details.TextWrapped = true
details.Font = Enum.Font.GothamMedium
details.TextSize = 17
details.Parent = panel

local hint = Instance.new("TextLabel")
hint.Position = UDim2.fromOffset(20, 180)
hint.Size = UDim2.fromOffset(390, 28)
hint.BackgroundTransparency = 1
hint.Text = "B = Bounty öffnen/schließen"
hint.Font = Enum.Font.Gotham
hint.TextSize = 13
hint.TextXAlignment = Enum.TextXAlignment.Right
hint.Parent = panel

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then
		return fallback
	end
	return number
end

local function refresh()
	local rawEnemy = player:GetAttribute("DailyBountyEnemy")
	local enemy = type(rawEnemy) == "string" and rawEnemy ~= "" and rawEnemy or "Unknown"
	local progress = math.max(0, math.floor(finiteNumber(player:GetAttribute("DailyBountyProgress"), 0)))
	local goal = math.max(1, math.floor(finiteNumber(player:GetAttribute("DailyBountyGoal"), 1)))
	local reward = math.max(0, math.floor(finiteNumber(player:GetAttribute("DailyBountyReward"), 0)))
	local claimed = player:GetAttribute("DailyBountyClaimed") == true
	if claimed then
		details.Text = string.format("Today's Target: %s\nProgress: %d / %d\nReward: %d Money\n\n✓ Bounty completed", enemy, progress, goal, reward)
	else
		details.Text = string.format("Today's Target: %s\nProgress: %d / %d\nReward: %d Money\n\nKeep hunting to complete today's bounty.", enemy, progress, goal, reward)
	end
end

for _, attribute in ipairs({ "DailyBountyEnemy", "DailyBountyProgress", "DailyBountyGoal", "DailyBountyReward", "DailyBountyClaimed" }) do
	player:GetAttributeChangedSignal(attribute):Connect(refresh)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.B then
		panel.Visible = not panel.Visible
		if panel.Visible then refresh() end
	end
end)

refresh()
