local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local getPlayerData = remotes:WaitForChild("GetPlayerData")
local AchievementSystem = require(ReplicatedStorage.Modules.AchievementSystem)
local open = false
local gui
local panel

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return fallback end
	return number
end

local function ensureGui()
	local playerGui = player:WaitForChild("PlayerGui")
	gui = playerGui:FindFirstChild("AchievementMenu")
	if gui then panel = gui.Panel; return end
	gui = Instance.new("ScreenGui")
gui.Name = "AchievementMenu"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui
	panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(620, 500)
	panel.Visible = false
	panel.BackgroundTransparency = 0.08
	panel.Parent = gui
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

	local title = Instance.new("TextLabel")
	title.Position = UDim2.fromOffset(18, 14)
	title.Size = UDim2.fromOffset(520, 36)
	title.BackgroundTransparency = 1
	title.Text = "Achievements & Titles"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local close = Instance.new("TextButton")
	close.Position = UDim2.fromOffset(560, 14)
	close.Size = UDim2.fromOffset(40, 34)
	close.Text = "X"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 18
	close.Parent = panel
	close.Activated:Connect(function() open = false; panel.Visible = false end)

	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Position = UDim2.fromOffset(18, 62)
	list.Size = UDim2.fromOffset(584, 420)
	list.BackgroundTransparency = 0.12
	list.ScrollBarThickness = 6
	list.Parent = panel
	Instance.new("UICorner", list).CornerRadius = UDim.new(0, 10)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = list
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8) end)
end

local function refresh()
	ensureGui()
	local ok, data = pcall(function() return getPlayerData:InvokeServer() end)
	if not ok or type(data) ~= "table" then return end
	for _, child in ipairs(panel.List:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
	local unlocked = {}
	local achievements = type(data.Achievements) == "table" and data.Achievements or {}
	for _, id in ipairs(achievements) do
		if type(id) == "string" then unlocked[id] = true end
	end

	for _, definition in ipairs(AchievementSystem.GetOrdered()) do
		local row = Instance.new("Frame")
		row.Size = UDim2.fromOffset(560, 64)
		row.BackgroundTransparency = 0.08
		row.Parent = panel.List
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromOffset(540, 64)
		label.Position = UDim2.fromOffset(10, 0)
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.TextWrapped = true
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 14
		local reward = math.max(0, math.floor(finiteNumber(definition.RewardMoney, 0)))
		local titleSuffix = type(definition.Title) == "string" and (" • Title: " .. definition.Title) or ""
		label.Text = string.format("%s  •  %s\n%s\nReward: %d Money%s", unlocked[definition.Id] and "UNLOCKED" or "LOCKED", tostring(definition.Name or definition.Id), tostring(definition.Requirement or ""), reward, titleSuffix)
		label.Parent = row
	end
end

local function openMenu()
	open = true
	panel.Visible = true
	refresh()
end

ensureGui()
player:GetAttributeChangedSignal("OpenAchievementMenu"):Connect(openMenu)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.L then
		if open then open = false; panel.Visible = false else openMenu() end
	end
end)
