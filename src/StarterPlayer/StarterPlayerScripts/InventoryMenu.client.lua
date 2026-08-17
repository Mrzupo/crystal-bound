local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local inventoryRequest = remotes:WaitForChild("InventoryRequest")
local crystalChanged = remotes:WaitForChild("CrystalChanged")
local crystalUpgradeRequest = remotes:WaitForChild("CrystalUpgradeRequest")

local crystals = { "EMBER", "TIDE", "GALE" }
local inventory = {}
local open = false

local function ensureGui()
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:FindFirstChild("CrystalMenu")
	if gui then return gui end

	gui = Instance.new("ScreenGui")
	gui.Name = "CrystalMenu"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(620, 420)
	panel.BackgroundTransparency = 0.08
	panel.Visible = false
	panel.Parent = gui
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Position = UDim2.fromOffset(20, 14)
	title.Size = UDim2.fromOffset(560, 36)
	title.BackgroundTransparency = 1
	title.Text = "Crystal Bound • Inventory & Crystals"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.Position = UDim2.fromOffset(560, 14)
	close.Size = UDim2.fromOffset(40, 36)
	close.Text = "X"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 20
	close.Parent = panel
	close.Activated:Connect(function()
		open = false
		panel.Visible = false
	end)

	local info = Instance.new("TextLabel")
	info.Name = "Info"
	info.Position = UDim2.fromOffset(20, 58)
	info.Size = UDim2.fromOffset(580, 40)
	info.BackgroundTransparency = 1
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.Font = Enum.Font.GothamMedium
	info.TextSize = 15
	info.Parent = panel

	local crystalFrame = Instance.new("Frame")
	crystalFrame.Name = "Crystals"
	crystalFrame.Position = UDim2.fromOffset(20, 108)
	crystalFrame.Size = UDim2.fromOffset(580, 140)
	crystalFrame.BackgroundTransparency = 1
	crystalFrame.Parent = panel

	for index, crystalId in ipairs(crystals) do
		local button = Instance.new("TextButton")
		button.Name = crystalId
		button.Position = UDim2.fromOffset((index - 1) * 193, 0)
		button.Size = UDim2.fromOffset(180, 120)
		button.TextWrapped = true
		button.Font = Enum.Font.GothamBold
		button.TextSize = 16
		button.Parent = crystalFrame
		button.Activated:Connect(function()
			crystalChanged:FireServer(crystalId)
		end)
	end

	local loot = Instance.new("TextLabel")
	loot.Name = "Loot"
	loot.Position = UDim2.fromOffset(20, 260)
	loot.Size = UDim2.fromOffset(580, 90)
	loot.BackgroundTransparency = 1
	loot.TextXAlignment = Enum.TextXAlignment.Left
	loot.TextYAlignment = Enum.TextYAlignment.Top
	loot.TextWrapped = true
	loot.Font = Enum.Font.Gotham
	loot.TextSize = 15
	loot.Parent = panel

	local upgrade = Instance.new("TextButton")
	upgrade.Name = "Upgrade"
	upgrade.Position = UDim2.fromOffset(20, 360)
	upgrade.Size = UDim2.fromOffset(260, 40)
	upgrade.Text = "Upgrade Equipped Crystal"
	upgrade.Font = Enum.Font.GothamBold
	upgrade.TextSize = 15
	upgrade.Parent = panel
	upgrade.Activated:Connect(function()
		crystalUpgradeRequest:FireServer(player:GetAttribute("EquippedCrystal") or "EMBER")
	end)

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.Position = UDim2.fromOffset(300, 360)
	hint.Size = UDim2.fromOffset(300, 40)
	hint.BackgroundTransparency = 1
	hint.Text = "I = öffnen/schließen"
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 14
	hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.Parent = panel

	return gui
end

local gui = ensureGui()
local panel = gui.Panel

local function refresh()
	local crystal = player:GetAttribute("EquippedCrystal") or "EMBER"
	local level = player:GetAttribute("CrystalMasteryLevel") or 1
	local xp = player:GetAttribute("CrystalMasteryXP") or 0
	panel.Info.Text = string.format("Equipped: %s   |   Mastery: Lv. %d   |   Mastery XP: %d", crystal, level, xp)
	for _, crystalId in ipairs(crystals) do
		local button = panel.Crystals:FindFirstChild(crystalId)
		if button then
			local owned = false
			local ownedAttribute = player:GetAttribute("Owns_" .. crystalId)
			if ownedAttribute == true then owned = true end
			button.Text = string.format("%s\n%s", crystalId, crystalId == crystal and "EQUIPPED" or "Press to Equip")
			if not owned and crystalId ~= "EMBER" then
				button.Text ..= "\nUnlock by Level"
			end
		end
	end
	local parts = {}
	for itemId, amount in pairs(inventory) do
		if tonumber(amount) and amount > 0 then table.insert(parts, string.format("%s: %d", itemId, amount)) end
	end
	table.sort(parts)
	panel.Loot.Text = #parts > 0 and ("Loot\n" .. table.concat(parts, "   |   ")) or "Loot\nNo materials collected."
end

inventoryRequest.OnClientEvent:Connect(function(data)
	if type(data) == "table" then
		inventory = data
		refresh()
	end
end)

for _, attribute in ipairs({ "EquippedCrystal", "CrystalMasteryLevel", "CrystalMasteryXP" }) do
	player:GetAttributeChangedSignal(attribute):Connect(refresh)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.I then
		open = not open
		panel.Visible = open
		if open then
			inventoryRequest:FireServer()
			refresh()
		end
	end
end)

refresh()
