local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local inventoryRequest = remotes:WaitForChild("InventoryRequest")
local inventoryChanged = remotes:WaitForChild("InventoryChanged")
local shopRequest = remotes:WaitForChild("ShopRequest")
local useItemRequest = remotes:WaitForChild("UseItemRequest")
local inventoryConfig = require(ReplicatedStorage.Config.InventoryConfig)
local shopConfig = require(ReplicatedStorage.Config.ShopConfig)
local consumableConfig = require(ReplicatedStorage.Config.ConsumableConfig)

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then
		return fallback
	end
	return number
end

local sellable = {}
for _, itemId in ipairs(shopConfig.SellOrder or {}) do
	local item = inventoryConfig.GetItemConfig(itemId)
	if item then
		table.insert(sellable, {
			Id = itemId,
			Name = type(item.Name) == "string" and item.Name or itemId,
			Rarity = type(item.Rarity) == "string" and item.Rarity or "Common",
			Price = math.max(0, math.floor(finiteNumber(item.SellPrice, 0))),
		})
	end
end

local rarityOrder = inventoryConfig.Rarities or {}
local potionOffer = shopConfig.Offers.HealthPotion
local potionConfig = consumableConfig.HealthPotion
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
	panel.Size = UDim2.fromOffset(600, 470)
	panel.Visible = false
	panel.BackgroundTransparency = 0.08
	panel.Parent = gui
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Position = UDim2.fromOffset(18, 14)
	title.Size = UDim2.fromOffset(500, 38)
	title.BackgroundTransparency = 1
	title.Text = "Material Trader"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.Position = UDim2.fromOffset(540, 14)
	close.Size = UDim2.fromOffset(42, 36)
	close.Text = "X"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 18
	close.Parent = panel
	close.Activated:Connect(function()
		open = false
		panel.Visible = false
		player:SetAttribute("OpenShopMenu", nil)
	end)

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Position = UDim2.fromOffset(18, 55)
	status.Size = UDim2.fromOffset(564, 44)
	status.BackgroundTransparency = 1
	status.Text = "Stand near the Material Trader to sell loot, or buy a Health Potion."
	status.TextWrapped = true
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Font = Enum.Font.Gotham
	status.TextSize = 14
	status.Parent = panel

	local potion = Instance.new("Frame")
	potion.Name = "PotionOffer"
	potion.Position = UDim2.fromOffset(18, 100)
	potion.Size = UDim2.fromOffset(564, 54)
	potion.BackgroundTransparency = 0.08
	potion.Parent = panel
	Instance.new("UICorner", potion).CornerRadius = UDim.new(0, 8)

	local potionLabel = Instance.new("TextLabel")
	potionLabel.Name = "Label"
	potionLabel.Position = UDim2.fromOffset(12, 0)
	potionLabel.Size = UDim2.fromOffset(350, 54)
	potionLabel.BackgroundTransparency = 1
	potionLabel.TextXAlignment = Enum.TextXAlignment.Left
	potionLabel.Font = Enum.Font.GothamBold
	potionLabel.TextSize = 14
	potionLabel.Parent = potion

	local buy = Instance.new("TextButton")
	buy.Name = "Buy"
	buy.Position = UDim2.fromOffset(390, 10)
	buy.Size = UDim2.fromOffset(92, 34)
	buy.Text = "BUY x1"
	buy.Font = Enum.Font.GothamBold
	buy.TextSize = 13
	buy.Parent = potion
	buy.Activated:Connect(function()
		if type(potionOffer) == "table" and type(potionOffer.ItemId) == "string" then
			shopRequest:FireServer("Buy", potionOffer.ItemId, 1)
		end
	end)

	local use = Instance.new("TextButton")
	use.Name = "Use"
	use.Position = UDim2.fromOffset(488, 10)
	use.Size = UDim2.fromOffset(62, 34)
	use.Text = "USE"
	use.Font = Enum.Font.GothamBold
	use.TextSize = 12
	use.Parent = potion
	use.Activated:Connect(function()
		if type(potionConfig) == "table" and type(potionConfig.ItemId) == "string" then
			useItemRequest:FireServer(potionConfig.ItemId)
		end
	end)

	local list = Instance.new("Frame")
	list.Name = "List"
	list.Position = UDim2.fromOffset(18, 164)
	list.Size = UDim2.fromOffset(564, 260)
	list.BackgroundTransparency = 1
	list.Parent = panel

	for index, item in ipairs(sellable) do
		local row = Instance.new("Frame")
		row.Name = item.Id
		row.Position = UDim2.fromOffset(0, (index - 1) * 51)
		row.Size = UDim2.fromOffset(564, 46)
		row.BackgroundTransparency = 0.1
		row.Parent = list
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Position = UDim2.fromOffset(12, 0)
		label.Size = UDim2.fromOffset(420, 46)
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 14
		label.TextWrapped = true
		label.Parent = row

		local sell = Instance.new("TextButton")
		sell.Name = "Sell"
		sell.Position = UDim2.fromOffset(458, 7)
		sell.Size = UDim2.fromOffset(94, 32)
		sell.Text = "SELL x1"
		sell.Font = Enum.Font.GothamBold
		sell.TextSize = 13
		sell.Parent = row
		sell.Activated:Connect(function() inventoryRequest:FireServer("Sell", item.Id, 1) end)
	end

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.Position = UDim2.fromOffset(18, 432)
	hint.Size = UDim2.fromOffset(564, 24)
	hint.BackgroundTransparency = 1
	hint.Text = "O = Händler   •   P = Potion benutzen"
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 13
	hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.Parent = panel

	return gui
end

local gui = ensureGui()
local panel = gui.Panel

local function usePotion()
	local potionItemId = type(potionConfig) == "table" and potionConfig.ItemId
	if type(potionItemId) ~= "string" then return end
	if finiteNumber(inventory[potionItemId], 0) <= 0 then return end
	useItemRequest:FireServer(potionItemId)
end

local function refresh()
	for _, item in ipairs(sellable) do
		local row = panel.List:FindFirstChild(item.Id)
		if row then
			local amount = math.max(0, math.floor(finiteNumber(inventory[item.Id], 0)))
			local rarityRank = math.max(1, math.floor(finiteNumber(rarityOrder[item.Rarity], 1)))
			row.Label.Text = string.format("%s  •  %s  •  %d owned  •  %d Money each", item.Name, item.Rarity, amount, item.Price)
			row.Label.TextSize = 13 + math.min(3, rarityRank)
			row.Sell.Active = amount > 0
			row.Sell.TextTransparency = amount > 0 and 0 or 0.5
		end
	end
	local potionItemId = type(potionConfig) == "table" and potionConfig.ItemId
	local potionItem = type(potionItemId) == "string" and inventoryConfig.GetItemConfig(potionItemId) or nil
	local potionAmount = math.max(0, math.floor(finiteNumber(potionItemId and inventory[potionItemId], 0)))
	local potionName = potionItem and type(potionItem.Name) == "string" and potionItem.Name or "Health Potion"
	local potionRarity = potionItem and type(potionItem.Rarity) == "string" and potionItem.Rarity or "Common"
	local potionPrice = type(potionOffer) == "table" and math.max(0, math.floor(finiteNumber(potionOffer.Price, 0))) or 0
	local healAmount = type(potionConfig) == "table" and math.max(0, math.floor(finiteNumber(potionConfig.HealAmount, 0))) or 0
	panel.PotionOffer.Label.Text = string.format("%s  •  %s  •  %d Money  •  Heal +%d HP  •  Owned: %d", potionName, potionRarity, potionPrice, healAmount, potionAmount)
	panel.PotionOffer.Use.Active = potionAmount > 0
	panel.PotionOffer.Use.TextTransparency = potionAmount > 0 and 0 or 0.5
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

player:GetAttributeChangedSignal("OpenShopMenu"):Connect(function()
	if player:GetAttribute("OpenShopMenu") == nil then return end
	openMenu()
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.O then
		if open then
			open = false
			panel.Visible = false
			player:SetAttribute("OpenShopMenu", nil)
		else
			openMenu()
		end
	elseif input.KeyCode == Enum.KeyCode.P then
		usePotion()
	end
end)

refresh()