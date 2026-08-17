local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local inventoryRequest = remotes:WaitForChild("InventoryRequest")
local crystalChanged = remotes:WaitForChild("CrystalChanged")
local crystalUpgradeRequest = remotes:WaitForChild("CrystalUpgradeRequest")
local useItemRequest = remotes:WaitForChild("UseItemRequest")
local crystalConfig = require(ReplicatedStorage.Config.CrystalConfig)
local upgradeConfig = require(ReplicatedStorage.Config.CrystalUpgradeConfig)

local crystals = { "EMBER", "TIDE", "GALE" }
local unlockLevels = { EMBER = 1, TIDE = 3, GALE = 5 }
local crystalLabels = { EMBER = "Ember", TIDE = "Tide", GALE = "Gale" }
local rarityByItem = { EmberShard = "Common", TidePearl = "Uncommon", GaleFeather = "Rare", AncientShard = "Epic", GuardianCore = "Legendary", HealthPotion = "Uncommon" }
local inventory = {}
local open = false

local function ensureGui()
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:FindFirstChild("CrystalMenu")
	if gui then return gui end
	gui = Instance.new("ScreenGui")
	gui.Name = "CrystalMenu"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"; panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5); panel.Size = UDim2.fromOffset(700, 540); panel.BackgroundTransparency = 0.08; panel.Visible = false; panel.Parent = gui
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

	local title = Instance.new("TextLabel")
	title.Name = "Title"; title.Position = UDim2.fromOffset(20, 14); title.Size = UDim2.fromOffset(620, 36); title.BackgroundTransparency = 1; title.Text = "Crystal Bound • Inventory & Crystals"; title.Font = Enum.Font.GothamBold; title.TextSize = 24; title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = panel

	local close = Instance.new("TextButton")
	close.Name = "Close"; close.Position = UDim2.fromOffset(640, 14); close.Size = UDim2.fromOffset(40, 36); close.Text = "X"; close.Font = Enum.Font.GothamBold; close.TextSize = 20; close.Parent = panel
	close.Activated:Connect(function() open = false; panel.Visible = false end)

	local info = Instance.new("TextLabel")
	info.Name = "Info"; info.Position = UDim2.fromOffset(20, 58); info.Size = UDim2.fromOffset(660, 40); info.BackgroundTransparency = 1; info.TextXAlignment = Enum.TextXAlignment.Left; info.Font = Enum.Font.GothamMedium; info.TextSize = 15; info.Parent = panel

	local crystalFrame = Instance.new("Frame")
	crystalFrame.Name = "Crystals"; crystalFrame.Position = UDim2.fromOffset(20, 108); crystalFrame.Size = UDim2.fromOffset(660, 160); crystalFrame.BackgroundTransparency = 1; crystalFrame.Parent = panel

	for index, crystalId in ipairs(crystals) do
		local button = Instance.new("TextButton")
		button.Name = crystalId; button.Position = UDim2.fromOffset((index - 1) * 220, 0); button.Size = UDim2.fromOffset(208, 150); button.TextWrapped = true; button.Font = Enum.Font.GothamBold; button.TextSize = 14; button.Parent = crystalFrame
		button.Activated:Connect(function() crystalChanged:FireServer(crystalId) end)
	end

	local loot = Instance.new("TextLabel")
	loot.Name = "Loot"; loot.Position = UDim2.fromOffset(20, 280); loot.Size = UDim2.fromOffset(660, 130); loot.BackgroundTransparency = 1; loot.TextXAlignment = Enum.TextXAlignment.Left; loot.TextYAlignment = Enum.TextYAlignment.Top; loot.TextWrapped = true; loot.Font = Enum.Font.Gotham; loot.TextSize = 14; loot.Parent = panel

	local potion = Instance.new("TextButton")
	potion.Name = "Potion"
	potion.Position = UDim2.fromOffset(20, 416)
	potion.Size = UDim2.fromOffset(300, 42)
	potion.Text = "Use Health Potion (P)"
	potion.Font = Enum.Font.GothamBold
	potion.TextSize = 14
	potion.Parent = panel
	potion.Activated:Connect(function() useItemRequest:FireServer("HealthPotion") end)

	local upgrade = Instance.new("TextButton")
	upgrade.Name = "Upgrade"; upgrade.Position = UDim2.fromOffset(340, 416); upgrade.Size = UDim2.fromOffset(340, 42); upgrade.Text = "Upgrade Equipped Crystal"; upgrade.Font = Enum.Font.GothamBold; upgrade.TextSize = 15; upgrade.Parent = panel
	upgrade.Activated:Connect(function() crystalUpgradeRequest:FireServer(player:GetAttribute("EquippedCrystal") or "EMBER") end)

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"; hint.Position = UDim2.fromOffset(20, 462); hint.Size = UDim2.fromOffset(660, 42); hint.BackgroundTransparency = 1; hint.Text = "I = öffnen/schließen  •  P = Potion benutzen"; hint.Font = Enum.Font.Gotham; hint.TextSize = 14; hint.TextXAlignment = Enum.TextXAlignment.Right; hint.Parent = panel
	return gui
end

local gui = ensureGui()
local panel = gui.Panel

local function formatCost(crystalId)
	local level = player:GetAttribute("CrystalMasteryLevel") or 1
	if level >= upgradeConfig.MaxLevel then return "MAX" end
	local base = upgradeConfig.BaseCosts[crystalId] or {}
	local parts = {}
	for itemId, amount in pairs(base) do table.insert(parts, string.format("%d %s", amount * level, itemId)) end
	table.sort(parts)
	return table.concat(parts, ", ")
end

local function refresh()
	local crystal = player:GetAttribute("EquippedCrystal") or "EMBER"
	local level = player:GetAttribute("CrystalMasteryLevel") or 1
	local xp = player:GetAttribute("CrystalMasteryXP") or 0
	panel.Info.Text = string.format("Equipped: %s   |   Mastery: Lv. %d   |   Mastery XP: %d   |   Upgrade: %s", crystalLabels[crystal] or crystal, level, xp, formatCost(crystal))
	for _, crystalId in ipairs(crystals) do
		local button = panel.Crystals:FindFirstChild(crystalId)
		if button then
			local owned = player:GetAttribute("Owns_" .. crystalId) == true
			local passive = crystalConfig.Passives[crystalId]
			local ability = crystalConfig.Abilities[crystalId]
			local unlock = unlockLevels[crystalId]
			local status = crystalId == crystal and "EQUIPPED" or (owned and "EQUIP" or string.format("LOCKED • Level %d", unlock))
			button.Text = string.format("%s\n%s\nAbility: %s (%d DMG)\nPassive: x%.2f damage | +%d HP | +%d speed\n[%s]", crystalLabels[crystalId], status, ability.Name, ability.Damage, passive.DamageMultiplier, passive.MaxHealthBonus, passive.WalkSpeedBonus)
			button.Active = owned or (tonumber(player:GetAttribute("Level")) or 1) >= unlock
		end
	end
	local parts = {}
	for itemId, amount in pairs(inventory) do
		if tonumber(amount) and amount > 0 then table.insert(parts, string.format("%s [%s]: %d", itemId, rarityByItem[itemId] or "Common", amount)) end
	end
	table.sort(parts)
	panel.Loot.Text = #parts > 0 and ("Loot / Items\n" .. table.concat(parts, "   |   ")) or "Loot / Items\nNo items collected."
	local potionAmount = tonumber(inventory.HealthPotion) or 0
	panel.Potion.Text = string.format("Use Health Potion (P)  •  Owned: %d", potionAmount)
	panel.Potion.Active = potionAmount > 0
	panel.Potion.TextTransparency = potionAmount > 0 and 0 or 0.5
end

inventoryRequest.OnClientEvent:Connect(function(data)
	if type(data) == "table" then inventory = data; refresh() end
end)

for _, attribute in ipairs({ "EquippedCrystal", "CrystalMasteryLevel", "CrystalMasteryXP", "Level", "Owns_EMBER", "Owns_TIDE", "Owns_GALE" }) do
	player:GetAttributeChangedSignal(attribute):Connect(refresh)
end

player:GetAttributeChangedSignal("OpenCrystalMenu"):Connect(function()
	open = true
	panel.Visible = true
	inventoryRequest:FireServer()
	refresh()
end)

local function openMenu()
	open = true; panel.Visible = true; inventoryRequest:FireServer(); refresh()
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.I then
		if open then open = false; panel.Visible = false else openMenu() end
	elseif input.KeyCode == Enum.KeyCode.P then
		useItemRequest:FireServer("HealthPotion")
	end
end)

refresh()
