local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local inventoryRequest = remotes:WaitForChild("InventoryRequest")
local inventoryChanged = remotes:WaitForChild("InventoryChanged")

local sellable = {
	{ Id = "EmberShard", Name = "Ember Shard", Rarity = "Common", Price = 8 },
	{ Id = "TidePearl", Name = "Tide Pearl", Rarity = "Uncommon", Price = 14 },
	{ Id = "GaleFeather", Name = "Gale Feather", Rarity = "Rare", Price = 22 },
	{ Id = "GuardianCore", Name = "Guardian Core", Rarity = "Legendary", Price = 250 },
	{ Id = "AncientShard", Name = "Ancient Shard", Rarity = "Epic", Price = 35 },
}

local rarityOrder = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5 }
local inventory = {}
local open = false

local function ensureGui()
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:FindFirstChild("ShopMenu")
	if gui then return gui end

	gui = Instance.new("ScreenGui")
	gui.Name = "ShopMenu"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(560, 430)
	panel.Visible = false
	panel.BackgroundTransparency = 0.08
	panel.Parent = gui
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Position = UDim2.fromOffset(18, 14)
	title.Size = UDim2.fromOffset(450, 38)
	title.BackgroundTransparency = 1
	title.Text = "Material Trader"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.Position = UDim2.fromOffset(500, 14)
	close.Size = UDim2.fromOffset(42, 36)
	close.Text = "X"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 18
	close.Parent = panel
	close.Activated:Connect(function() open = false; panel.Visible = false end)

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Position = UDim2.fromOffset(18, 55)
	status.Size = UDim2.fromOffset(524, 44)
	status.BackgroundTransparency = 1
	status.Text = "Stand near the Material Trader to sell loot."
	status.TextWrapped = true
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Font = Enum.Font.Gotham
	status.TextSize = 14
	status.Parent = panel

	local list = Instance.new("Frame")
	list.Name = "List"
	list.Position = UDim2.fromOffset(18, 104)
	list.Size = UDim2.fromOffset(524, 290)
	list.BackgroundTransparency = 1
	list.Parent = panel

	for index, item in ipairs(sellable) do
		local row = Instance.new("Frame")
		row.Name = item.Id
		row.Position = UDim2.fromOffset(0, (index - 1) * 54)
		row.Size = UDim2.fromOffset(524, 48)
		row.BackgroundTransparency = 0.1
		row.Parent = list
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Position = UDim2.fromOffset(12, 0)
		label.Size = UDim2.fromOffset(370, 48)
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 14
		label.TextWrapped = true
		label.Parent = row

		local sell = Instance.new("TextButton")
		sell.Name = "Sell"
		sell.Position = UDim2.fromOffset(418, 8)
		sell.Size = UDim2.fromOffset(94, 32)
		sell.Text = "SELL x1"
		sell.Font = Enum.Font.GothamBold
		sell.TextSize = 13
		sell.Parent = row
		sell.Activated:Connect(function() inventoryRequest:FireServer("Sell", item.Id, 1) end)
	end

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.Position = UDim2.fromOffset(18, 398)
	hint.Size = UDim2.fromOffset(524, 24)
	hint.BackgroundTransparency = 1
	hint.Text = "O = Händler öffnen/schließen"
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 13
	hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.Parent = panel

	return gui
end

local gui = ensureGui()
local panel = gui.Panel

local function refresh()
	for _, item in ipairs(sellable) do
		local row = panel.List:FindFirstChild(item.Id)
		if row then
			local amount = math.max(0, math.floor(tonumber(inventory[item.Id]) or 0))
			local rarityRank = rarityOrder[item.Rarity] or 1
			row.Label.Text = string.format("%s  •  %s  •  %d owned  •  %d Money each", item.Name, item.Rarity, amount, item.Price)
			row.Label.TextSize = 13 + math.min(3, rarityRank)
			row.Sell.Active = amount > 0
			row.Sell.TextTransparency = amount > 0 and 0 or 0.5
		end
	end
end

local function openMenu()
	open = true
	panel.Visible = true
	inventoryRequest:FireServer()
	refresh()
end

inventoryChanged.OnClientEvent:Connect(function(data)
	if type(data) == "table" then inventory = data; refresh() end
end)

player:GetAttributeChangedSignal("OpenShopMenu"):Connect(function() openMenu() end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.O then
		if open then open = false; panel.Visible = false else openMenu() end
	end
end)

refresh()
