local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatRemote = remotes:WaitForChild("CombatRequest")
local xpChanged = remotes:WaitForChild("XPChanged")
local levelUp = remotes:WaitForChild("LevelUp")
local moneyChanged = remotes:WaitForChild("MoneyChanged")
local inventoryChanged = remotes:WaitForChild("InventoryChanged")
local inventoryRequest = remotes:WaitForChild("InventoryRequest")
local crystalChanged = remotes:WaitForChild("CrystalChanged")
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
		panel.Size = UDim2.fromOffset(380, 220)
		panel.BackgroundTransparency = 0.15
		panel.Parent = gui
		Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

		local stats = Instance.new("TextLabel")
		stats.Name = "Stats"
		stats.Position = UDim2.fromOffset(12, 10)
		stats.Size = UDim2.fromOffset(356, 106)
		stats.BackgroundTransparency = 1
		stats.TextXAlignment = Enum.TextXAlignment.Left
		stats.TextYAlignment = Enum.TextYAlignment.Top
		stats.TextWrapped = true
		stats.Font = Enum.Font.GothamMedium
		stats.TextSize = 18
		stats.Parent = panel

		local inv = Instance.new("TextLabel")
		inv.Name = "Inventory"
		inv.Position = UDim2.fromOffset(12, 118)
		inv.Size = UDim2.fromOffset(356, 82)
		inv.BackgroundTransparency = 1
		inv.TextXAlignment = Enum.TextXAlignment.Left
		inv.TextYAlignment = Enum.TextYAlignment.Top
		inv.TextWrapped = true
		inv.Font = Enum.Font.Gotham
		inv.TextSize = 14
		inv.Parent = panel

		local quest = Instance.new("TextLabel")
		quest.Name = "Quest"
		quest.Position = UDim2.fromOffset(16, 236)
		quest.Size = UDim2.fromOffset(600, 145)
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
		message.Size = UDim2.fromOffset(560, 46)
		message.BackgroundTransparency = 0.2
		message.TextXAlignment = Enum.TextXAlignment.Center
		message.Font = Enum.Font.GothamBold
		message.TextSize = 18
		message.Parent = gui
		Instance.new("UICorner", message).CornerRadius = UDim.new(0, 10)

		local help = Instance.new("TextLabel")
		help.Name = "Help"
		help.AnchorPoint = Vector2.new(0.5, 1)
		help.Position = UDim2.new(0.5, 0, 1, -18)
		help.Size = UDim2.fromOffset(1050, 50)
		help.BackgroundTransparency = 0.25
		help.Text = "Klick = Angriff | Q = Fähigkeit | Z/X/C = Kristall | E = aktualisieren | 4/5/6 = je 1 Loot verkaufen"
		help.Font = Enum.Font.GothamBold
		help.TextSize = 16
		help.Parent = gui
	end
	return panel.Stats, panel.Inventory, gui.Quest, gui.Message
end

local statsLabel, inventoryLabel, questLabel, messageLabel = ensureHud()

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
	statsLabel.Text = string.format(
		"Crystal Bound\nLevel: %d    XP: %d\nMoney: %d\nCrystal: %s",
		player:GetAttribute("Level") or 1,
		player:GetAttribute("Experience") or 0,
		player:GetAttribute("Money") or 0,
		player:GetAttribute("EquippedCrystal") or "EMBER"
	)
	refreshInventory()
	showMessage(
		player:GetAttribute("ShopMessage")
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

for _, attribute in ipairs({ "Level", "Experience", "Money", "EquippedCrystal", "QuestMessage", "CrystalMessage", "PortalMessage", "ShopMessage", "QuestProgress" }) do
	player:GetAttributeChangedSignal(attribute):Connect(function()
		refreshHud()
		refreshQuests()
	end)
end

xpChanged.OnClientEvent:Connect(function() refreshHud(); refreshQuests() end)
moneyChanged.OnClientEvent:Connect(function() refreshHud(); refreshQuests() end)
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
	end
end)

print("Crystal Bound client ready")
