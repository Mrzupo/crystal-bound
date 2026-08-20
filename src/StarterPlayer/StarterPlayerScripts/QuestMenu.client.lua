local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local questRequest = remotes:WaitForChild("QuestRequest")
local getQuestData = remotes:WaitForChild("GetQuestData")
local getAvailableQuests = remotes:WaitForChild("GetAvailableQuests")

local open = false
local data = nil
local available = {}
local loading = false
local lastLoad = 0
local LOAD_INTERVAL = 0.2
local loadData

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then
		return fallback
	end
	return number
end

local function closeMenu(panel)
	open = false
	panel.Visible = false
	player:SetAttribute("OpenQuestMenu", nil)
end

local function ensureGui()
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:FindFirstChild("QuestMenu")
	if gui then return gui end
	gui = Instance.new("ScreenGui")
	gui.Name = "QuestMenu"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(680, 500)
	panel.BackgroundTransparency = 0.08
	panel.Visible = false
	panel.Parent = gui
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Position = UDim2.fromOffset(18, 14)
	title.Size = UDim2.fromOffset(580, 38)
	title.BackgroundTransparency = 1
	title.Text = "Quest Journal"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.Position = UDim2.fromOffset(620, 14)
	close.Size = UDim2.fromOffset(42, 36)
	close.Text = "X"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 18
	close.Parent = panel
	close.Activated:Connect(function() closeMenu(panel) end)

	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Position = UDim2.fromOffset(18, 64)
	list.Size = UDim2.fromOffset(644, 402)
	list.BackgroundTransparency = 0.12
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.new()
	list.Parent = panel
	Instance.new("UICorner", list).CornerRadius = UDim.new(0, 10)

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.Parent = list
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 12) end)
	return gui
end

local gui = ensureGui()
local panel = gui.Panel
local list = panel.List

local function clearList()
	for _, child in ipairs(list:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
end

local function addRow(questId, definition, state, progress)
	if type(questId) ~= "string" or type(definition) ~= "table" then return end
	local name = type(definition.Name) == "string" and definition.Name or questId
	local description = type(definition.Description) == "string" and definition.Description or ""
	local goal = math.max(0, math.floor(finiteNumber(definition.Goal, 0)))
	local xp = math.max(0, math.floor(finiteNumber(definition.XP, 0)))
	local money = math.max(0, math.floor(finiteNumber(definition.Money, 0)))
	local safeProgress = math.clamp(math.floor(finiteNumber(progress, 0)), 0, goal > 0 and goal or math.huge)

	local row = Instance.new("Frame")
	row.Name = questId
	row.Size = UDim2.fromOffset(620, 108)
	row.BackgroundTransparency = 0.08
	row.Parent = list
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 9)

	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Position = UDim2.fromOffset(12, 8)
	text.Size = UDim2.fromOffset(420, 92)
	text.BackgroundTransparency = 1
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.TextWrapped = true
	text.Font = Enum.Font.GothamMedium
	text.TextSize = 14
	text.Text = string.format("%s\n%s\nProgress: %d/%d\nReward: %d XP + %d Money\nStatus: %s", name, description, safeProgress, goal, xp, money, type(state) == "string" and state or "unknown")
	text.Parent = row

	if state == "available" then
		local start = Instance.new("TextButton")
		start.Name = "Start"
		start.Position = UDim2.fromOffset(470, 35)
		start.Size = UDim2.fromOffset(130, 38)
		start.Text = "Start"
		start.Font = Enum.Font.GothamBold
		start.TextSize = 14
		start.Parent = row
		start.Activated:Connect(function()
			questRequest:FireServer("Start", questId)
			task.delay(0.2, function() if open then loadData(true) end end)
		end)
	end
end

local function refresh()
	if not data or type(data) ~= "table" then return end
	clearList()
	local active = type(data.Active) == "table" and data.Active or {}
	local completed = type(data.Completed) == "table" and data.Completed or {}
	local progressData = type(data.Progress) == "table" and data.Progress or {}
	local defs = type(data.Definitions) == "table" and data.Definitions or {}
	local activeSet, completedSet, availableSet = {}, {}, {}
	for _, id in ipairs(active) do if type(id) == "string" then activeSet[id] = true end end
	for _, id in ipairs(completed) do if type(id) == "string" then completedSet[id] = true end end
	for _, id in ipairs(available) do if type(id) == "string" then availableSet[id] = true end end
	for id, definition in pairs(defs) do if activeSet[id] then addRow(id, definition, "active", progressData[id] or 0) end end
	for id, definition in pairs(defs) do if not activeSet[id] and not completedSet[id] and availableSet[id] then addRow(id, definition, "available", progressData[id] or 0) end end
	for id, definition in pairs(defs) do if completedSet[id] then addRow(id, definition, "completed", definition and definition.Goal or 0) end end
end

loadData = function(force)
	local now = os.clock()
	if loading then return end
	if not force and now - lastLoad < LOAD_INTERVAL then return end
	loading = true
	lastLoad = now
	local ok, response = pcall(function() return getQuestData:InvokeServer() end)
	if ok and type(response) == "table" then data = response end
	local okAvailable, responseAvailable = pcall(function() return getAvailableQuests:InvokeServer() end)
	if okAvailable and type(responseAvailable) == "table" then available = responseAvailable end
	loading = false
	refresh()
end

local function openMenu()
	open = true
	panel.Visible = true
	loadData(true)
end

player:GetAttributeChangedSignal("OpenQuestMenu"):Connect(function()
	if player:GetAttribute("OpenQuestMenu") == nil then return end
	openMenu()
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.J then
		if open then closeMenu(panel) else openMenu() end
	end
end)

loadData(true)