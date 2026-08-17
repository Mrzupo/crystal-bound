local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatRemote = remotes:WaitForChild("CombatRequest")
local xpChanged = remotes:WaitForChild("XPChanged")
local levelUp = remotes:WaitForChild("LevelUp")
local moneyChanged = remotes:WaitForChild("MoneyChanged")
local questRemote = remotes:WaitForChild("QuestRequest")
local getQuestData = remotes:WaitForChild("GetQuestData")

local function getTargetFromMouse()
	local mouse = player:GetMouse()
	local hit = mouse.Target
	if not hit then return nil end
	return hit:FindFirstAncestorOfClass("Model") or hit
end

local function ensureHud()
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:FindFirstChild("MainUI")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "MainUI"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.Parent = playerGui
	end

	local panel = gui:FindFirstChild("Info")
	if not panel then
		panel = Instance.new("Frame")
		panel.Name = "Info"
		panel.Position = UDim2.fromOffset(16, 16)
		panel.Size = UDim2.fromOffset(330, 150)
		panel.BackgroundTransparency = 0.15
		panel.Parent = gui
		Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

		local label = Instance.new("TextLabel")
		label.Name = "Stats"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Top
		label.TextWrapped = true
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 18
		label.Parent = panel

		local quest = Instance.new("TextLabel")
		quest.Name = "Quest"
		quest.Position = UDim2.fromOffset(16, 178)
		quest.Size = UDim2.fromOffset(420, 100)
		quest.BackgroundTransparency = 0.15
		quest.TextXAlignment = Enum.TextXAlignment.Left
		quest.TextYAlignment = Enum.TextYAlignment.Top
		quest.TextWrapped = true
		quest.Font = Enum.Font.GothamMedium
		quest.TextSize = 16
		quest.Parent = gui
		Instance.new("UICorner", quest).CornerRadius = UDim.new(0, 10)

		local help = Instance.new("TextLabel")
		help.Name = "Help"
		help.AnchorPoint = Vector2.new(0.5, 1)
		help.Position = UDim2.new(0.5, 0, 1, -18)
		help.Size = UDim2.fromOffset(620, 46)
		help.BackgroundTransparency = 0.25
		help.Text = "Klick = Angriff    Q = Kristallfähigkeit    E = Quest anzeigen"
		help.Font = Enum.Font.GothamBold
		help.TextSize = 17
		help.Parent = gui
	end
	return panel.Stats, gui.Quest
end

local statsLabel, questLabel = ensureHud()

local function refreshHud()
	statsLabel.Text = string.format(
		"Crystal Bound\nLevel: %d    XP: %d\nMoney: %d\nCrystal: %s",
		player:GetAttribute("Level") or 1,
		player:GetAttribute("Experience") or 0,
		player:GetAttribute("Money") or 0,
		player:GetAttribute("EquippedCrystal") or "EMBER"
	)
end

local function refreshQuests()
	local ok, data = pcall(function() return getQuestData:InvokeServer() end)
	if not ok or not data then return end
	local lines = { "Quests" }
	if #data.Active == 0 then
		table.insert(lines, "No active quests.")
	else
		for _, id in ipairs(data.Active) do
			local definition = data.Definitions[id]
			if definition then table.insert(lines, "• " .. definition.Name .. ": " .. definition.Description) end
		end
	end
	questLabel.Text = table.concat(lines, "\n")
end

for _, attribute in ipairs({ "Level", "Experience", "Money", "EquippedCrystal", "QuestMessage" }) do
	player:GetAttributeChangedSignal(attribute):Connect(function()
		refreshHud()
		refreshQuests()
	end)
end

xpChanged.OnClientEvent:Connect(function() refreshHud(); refreshQuests() end)
moneyChanged.OnClientEvent:Connect(function() refreshHud(); refreshQuests() end)
levelUp.OnClientEvent:Connect(function() refreshHud(); refreshQuests() end)
refreshHud()
refreshQuests()

local mouse = player:GetMouse()
mouse.Button1Down:Connect(function()
	local target = getTargetFromMouse()
	if target then combatRemote:FireServer("Basic", target) end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Q then
		local target = getTargetFromMouse()
		if target then combatRemote:FireServer("Ability", target) end
	elseif input.KeyCode == Enum.KeyCode.E then
		refreshQuests()
	elseif input.KeyCode == Enum.KeyCode.One then
		questRemote:FireServer("Start", "FIRST_FIGHT")
	elseif input.KeyCode == Enum.KeyCode.Two then
		questRemote:FireServer("Start", "CRYSTAL_POWER")
		refreshQuests()
	end
end)

print("Crystal Bound client ready")
