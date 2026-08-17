local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatRemote = remotes:WaitForChild("CombatRequest")
local xpChanged = remotes:WaitForChild("XPChanged")
local levelUp = remotes:WaitForChild("LevelUp")
local moneyChanged = remotes:WaitForChild("MoneyChanged")
local inventoryChanged = remotes:WaitForChild("InventoryChanged")
local inventoryRequest = remotes:WaitForChild("InventoryRequest")
local crystalChanged = remotes:WaitForChild("CrystalChanged")
local crystalMasteryChanged = remotes:WaitForChild("CrystalMasteryChanged")
local crystalUpgradeRequest = remotes:WaitForChild("CrystalUpgradeRequest")
local getQuestData = remotes:WaitForChild("GetQuestData")

local inventory = {}
local crystalOrder = { "EMBER", "TIDE", "GALE" }
local sellOrder = { "EmberShard", "TidePearl", "GaleFeather" }
local messageExpiresAt = 0

local function getTargetFromMouse()
	local hit = player:GetMouse().Target
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
		panel.Size = UDim2.fromOffset(430, 305)
		panel.BackgroundTransparency = 0.15
		panel.Parent = gui
		Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

		local stats = Instance.new("TextLabel")
		stats.Name = "Stats"
		stats.Position = UDim2.fromOffset(12, 10)
		stats.Size = UDim2.fromOffset(406, 100)
		stats.BackgroundTransparency = 1
		stats.TextXAlignment = Enum.TextXAlignment.Left
		stats.TextYAlignment = Enum.TextYAlignment.Top
		stats.TextWrapped = true
		stats.Font = Enum.Font.GothamMedium
		stats.TextSize = 18
		stats.Parent = panel

		local mastery = Instance.new("TextLabel")
		mastery.Name = "Mastery"
		mastery.Position = UDim2.fromOffset(12, 105)
		mastery.Size = UDim2.fromOffset(406, 55)
		mastery.BackgroundTransparency = 1
		mastery.TextXAlignment = Enum.TextXAlignment.Left
		mastery.TextYAlignment = Enum.TextYAlignment.Top
		mastery.TextWrapped = true
		mastery.Font = Enum.Font.GothamBold
		mastery.TextSize = 16
		mastery.Parent = panel

		local achievements = Instance.new("TextLabel")
		achievements.Name = "Achievements"
		achievements.Position = UDim2.fromOffset(12, 155)
		achievements.Size = UDim2.fromOffset(406, 42)
		achievements.BackgroundTransparency = 1
		achievements.TextXAlignment = Enum.TextXAlignment.Left
		achievements.TextYAlignment = Enum.TextYAlignment.Top
		achievements.TextWrapped = true
		achievements.Font = Enum.Font.GothamBold
		achievements.TextSize = 14
		achievements.Parent = panel

		local inv = Instance.new("TextLabel")
		inv.Name = "Inventory"
		inv.Position = UDim2.fromOffset(12, 195)
		inv.Size = UDim2.fromOffset(406, 96)
		inv.BackgroundTransparency = 1
		inv.TextXAlignment = Enum.TextXAlignment.Left
		inv.TextYAlignment = Enum.TextYAlignment.Top
		inv.TextWrapped = true
		inv.Font = Enum.Font.Gotham
		inv.TextSize = 14
		inv.Parent = panel

		local quest = Instance.new("TextLabel")
		quest.Name = "Quest"
		quest.Position = UDim2.fromOffset(16, 320)
		quest.Size = UDim2.fromOffset(640, 155)
		quest.BackgroundTransparency = 0.15
		quest.TextXAlignment = Enum.TextXAlignment.Left
		quest.TextYAlignment = Enum.TextYAlignment.Top
		quest.TextWrapped = true
		quest.Font = Enum.Font.GothamMedium
		quest.TextSize = 16
		quest.Parent = gui
		Instance.new("UICorner", quest).CornerRadius = UDim.new(0, 10)

		local message = Instance.new("TextLabel")
		message.Name = "Message"
		message.AnchorPoint = Vector2.new(0.5, 0)
		message.Position = UDim2.new(0.5, 0, 0, 20)
		message.Size = UDim2.fromOffset(620, 46)
		message.BackgroundTransparency = 0.2
		message.TextXAlignment = Enum.TextXAlignment.Center
		message.Font = Enum.Font.GothamBold
		message.TextSize = 18
		message.Parent = gui
		Instance.new("UICorner", message).CornerRadius = UDim.new(0, 10)

		local boss = Instance.new("Frame")
		boss.Name = "BossBar"
		boss.AnchorPoint = Vector2.new(0.5, 0)
		boss.Position = UDim2.new(0.5, 0, 0, 78)
		boss.Size = UDim2.fromOffset(620, 74)
		boss.BackgroundTransparency = 0.12
		boss.Visible = false
		boss.Parent = gui
		Instance.new("UICorner", boss).CornerRadius = UDim.new(0, 10)

		local bossName = Instance.new("TextLabel")
		bossName.Name = "Name"
		bossName.Position = UDim2.fromOffset(12, 6)
		bossName.Size = UDim2.fromOffset(596, 24)
		bossName.BackgroundTransparency = 1
		bossName.TextXAlignment = Enum.TextXAlignment.Center
		bossName.Font = Enum.Font.GothamBold
		bossName.TextSize = 19
		bossName.Parent = boss

		local hpBack = Instance.new("Frame")
		hpBack.Name = "HPBack"
		hpBack.Position = UDim2.fromOffset(12, 35)
		hpBack.Size = UDim2.fromOffset(596, 25)
		hpBack.BackgroundTransparency = 0.15
		hpBack.Parent = boss
		Instance.new("UICorner", hpBack).CornerRadius = UDim.new(0, 6)

		local hpFill = Instance.new("Frame")
		hpFill.Name = "HPFill"
		hpFill.Size = UDim2.fromScale(1, 1)
		hpFill.Parent = hpBack
		Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 6)

		local hpText = Instance.new("TextLabel")
		hpText.Name = "HPText"
		hpText.Size = UDim2.fromScale(1, 1)
		hpText.BackgroundTransparency = 1
		hpText.TextXAlignment = Enum.TextXAlignment.Center
		hpText.Font = Enum.Font.GothamBold
		hpText.TextSize = 14
		hpText.Parent = hpBack

		local help = Instance.new("TextLabel")
		help.Name = "Help"
		help.AnchorPoint = Vector2.new(0.5, 1)
		help.Position = UDim2.new(0.5, 0, 1, -18)
		help.Size = UDim2.fromOffset(1120, 50)
		help.BackgroundTransparency = 0.25
		help.Text = "Klick = Angriff | Q = Fähigkeit | Z/X/C = Kristall | E = aktualisieren | 4/5/6 = Loot verkaufen | U = Kristall upgraden"
		help.Font = Enum.Font.GothamBold
		help.TextSize = 16
		help.Parent = gui
	end
	return panel.Stats, panel.Mastery, panel.Achievements, panel.Inventory, gui.Quest, gui.Message, gui.BossBar
end

local statsLabel, masteryLabel, achievementsLabel, inventoryLabel, questLabel, messageLabel, bossBar = ensureHud()

local function showMessage(text)
	if type(text) ~= "string" or text == "" then return end
	messageLabel.Text = text
	messageExpiresAt = os.clock() + 4
end

task.spawn(function()
	while true do
		if os.clock() >= messageExpiresAt then messageLabel.Text = "" end
		task.wait(0.25)
	end
end)

local function refreshInventory()
	local parts = {}
	for _, id in ipairs(sellOrder) do
		local amount = inventory[id] or 0
		if amount > 0 then table.insert(parts, id .. ": " .. amount) end
	end
	inventoryLabel.Text = #parts > 0 and ("Loot\n" .. table.concat(parts, "  |  ")) or "Loot\nNo materials yet"
end

local function refreshHud()
	local crystal = player:GetAttribute("EquippedCrystal") or "EMBER"
	local masteryLevel = player:GetAttribute("CrystalMasteryLevel") or 1
	local masteryXP = player:GetAttribute("CrystalMasteryXP") or 0
	statsLabel.Text = string.format(
		"Crystal Bound\nLevel: %d    XP: %d\nMoney: %d\nCrystal: %s\nTitle: %s",
		player:GetAttribute("Level") or 1,
		player:GetAttribute("Experience") or 0,
		player:GetAttribute("Money") or 0,
		crystal,
		player:GetAttribute("Title") or ""
	)
	masteryLabel.Text = string.format("%s Mastery: Lv. %d    XP: %d", crystal, masteryLevel, masteryXP)
	achievementsLabel.Text = "Achievements: " .. tostring(player:GetAttribute("AchievementCount") or 0)
	refreshInventory()
	showMessage(
		player:GetAttribute("AchievementMessage")
		or player:GetAttribute("BossMessage")
		or player:GetAttribute("ShopMessage")
		or player:GetAttribute("QuestMessage")
		or player:GetAttribute("CrystalMessage")
		or player:GetAttribute("PortalMessage")
		or ""
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
			local progress = data.Progress and data.Progress[id] or 0
			if definition then
				table.insert(lines, string.format("• %s: %s (%d/%d)", definition.Name, definition.Description, progress, definition.Goal))
			end
		end
	end
	questLabel.Text = table.concat(lines, "\n")
end

local function refreshBoss()
	local workspaceFolder = workspace:FindFirstChild("NPCs")
	local boss = workspaceFolder and workspaceFolder:FindFirstChild("CrystalGuardian")
	local humanoid = boss and boss:FindFirstChildOfClass("Humanoid")
	if not boss or not humanoid or humanoid.Health <= 0 then
		bossBar.Visible = false
		return
	end
	bossBar.Visible = true
	local phase = boss:GetAttribute("BossPhase") or 1
	bossBar.Name.Text = string.format("Crystal Guardian  •  Phase %d", phase)
	local ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
	bossBar.HPBack.HPFill.Size = UDim2.fromScale(ratio, 1)
	bossBar.HPBack.HPText.Text = string.format("%d / %d HP", math.max(0, math.floor(humanoid.Health)), math.floor(humanoid.MaxHealth))
end

for _, attribute in ipairs({ "Level", "Experience", "Money", "EquippedCrystal", "CrystalMasteryLevel", "CrystalMasteryXP", "AchievementCount", "Title", "AchievementMessage", "BossMessage", "QuestMessage", "CrystalMessage", "PortalMessage", "ShopMessage", "QuestProgress" }) do
	player:GetAttributeChangedSignal(attribute):Connect(function()
		refreshHud()
		refreshQuests()
	end)
end

xpChanged.OnClientEvent:Connect(function() refreshHud(); refreshQuests() end)
moneyChanged.OnClientEvent:Connect(function() refreshHud(); refreshQuests() end)
crystalMasteryChanged.OnClientEvent:Connect(function(crystalId, level, xp)
	if crystalId == player:GetAttribute("EquippedCrystal") then
		player:SetAttribute("CrystalMasteryLevel", level or 1)
		player:SetAttribute("CrystalMasteryXP", xp or 0)
	end
	refreshHud()
end)
levelUp.OnClientEvent:Connect(function(level)
	refreshHud()
	refreshQuests()
	if level then showMessage("Level Up! Level " .. tostring(level)) end
end)
inventoryChanged.OnClientEvent:Connect(function(data)
	inventory = type(data) == "table" and data or {}
	refreshHud()
end)

refreshHud()
refreshQuests()
inventoryRequest:FireServer()

player:GetMouse().Button1Down:Connect(function()
	local target = getTargetFromMouse()
	if target then combatRemote:FireServer("Basic", target) end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Q then
		local target = getTargetFromMouse()
		if target then combatRemote:FireServer("Ability", target) end
	elseif input.KeyCode == Enum.KeyCode.Z then
		crystalChanged:FireServer(crystalOrder[1])
	elseif input.KeyCode == Enum.KeyCode.X then
		crystalChanged:FireServer(crystalOrder[2])
	elseif input.KeyCode == Enum.KeyCode.C then
		crystalChanged:FireServer(crystalOrder[3])
	elseif input.KeyCode == Enum.KeyCode.E then
		inventoryRequest:FireServer()
		refreshQuests()
	elseif input.KeyCode == Enum.KeyCode.Four then
		inventoryRequest:FireServer("Sell", sellOrder[1], 1)
	elseif input.KeyCode == Enum.KeyCode.Five then
		inventoryRequest:FireServer("Sell", sellOrder[2], 1)
	elseif input.KeyCode == Enum.KeyCode.Six then
		inventoryRequest:FireServer("Sell", sellOrder[3], 1)
	elseif input.KeyCode == Enum.KeyCode.U then
		crystalUpgradeRequest:FireServer(player:GetAttribute("EquippedCrystal") or "EMBER")
	end
end)

RunService.RenderStepped:Connect(refreshBoss)
print("Crystal Bound client ready")
