local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local craftingRequest = remotes:WaitForChild("CraftingRequest")
local inventoryRequest = remotes:WaitForChild("InventoryRequest")
local inventoryChanged = remotes:WaitForChild("InventoryChanged")
local inventoryConfig = require(ReplicatedStorage.Config.InventoryConfig)
local craftingConfig = require(ReplicatedStorage.Config.CraftingConfig)

local inventory = {}
local open = false
local recipeId = "HealthPotion"
local recipe = craftingConfig.Recipes[recipeId]
local outputItem = inventoryConfig.GetItemConfig(recipe.Output)

local gui = Instance.new("ScreenGui")
gui.Name = "CraftingMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(520, 300)
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(18, 14)
title.Size = UDim2.fromOffset(430, 34)
title.BackgroundTransparency = 1
title.Text = "Crafting"
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local close = Instance.new("TextButton")
close.Position = UDim2.fromOffset(460, 14)
close.Size = UDim2.fromOffset(40, 34)
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.Parent = panel
close.Activated:Connect(function() open = false; panel.Visible = false end)

local recipeLabel = Instance.new("TextLabel")
recipeLabel.Position = UDim2.fromOffset(18, 65)
recipeLabel.Size = UDim2.fromOffset(484, 80)
recipeLabel.BackgroundTransparency = 1
recipeLabel.TextWrapped = true
recipeLabel.TextXAlignment = Enum.TextXAlignment.Left
recipeLabel.TextYAlignment = Enum.TextYAlignment.Top
recipeLabel.Font = Enum.Font.Gotham
recipeLabel.TextSize = 16
recipeLabel.Parent = panel

local craft = Instance.new("TextButton")
craft.Position = UDim2.fromOffset(18, 165)
craft.Size = UDim2.fromOffset(484, 48)
craft.Font = Enum.Font.GothamBold
craft.TextSize = 16
craft.Parent = panel
craft.Activated:Connect(function() craftingRequest:FireServer("Craft", recipeId, 1) end)

local hint = Instance.new("TextLabel")
hint.Position = UDim2.fromOffset(18, 230)
hint.Size = UDim2.fromOffset(484, 40)
hint.BackgroundTransparency = 1
hint.Text = "B = Crafting öffnen/schließen"
hint.Font = Enum.Font.Gotham
hint.TextSize = 14
hint.TextXAlignment = Enum.TextXAlignment.Right
hint.Parent = panel

local function formatInputs()
	local lines = {}
	for itemId, amount in pairs(recipe.Inputs or {}) do
		local config = inventoryConfig.GetItemConfig(itemId)
		table.insert(lines, string.format("%d %s", amount, config and config.Name or itemId))
	end
	table.sort(lines)
	return table.concat(lines, " + ")
end

local function refresh()
	if not recipe or not outputItem then
		recipeLabel.Text = "Crafting recipe unavailable."
		craft.Active = false
		craft.TextTransparency = 0.5
		return
	end
	local outputAmount = math.max(1, math.floor(tonumber(recipe.Amount) or 1))
	local currentOutput = math.max(0, math.floor(tonumber(inventory[recipe.Output]) or 0))
	local maxStack = inventoryConfig.GetMaxStackSize(recipe.Output)
	local requirements = true
	for itemId, amount in pairs(recipe.Inputs or {}) do
		requirements = requirements and (math.max(0, math.floor(tonumber(inventory[itemId]) or 0)) >= amount)
	end
	local outputSpace = currentOutput + outputAmount <= maxStack
	recipeLabel.Text = string.format("%s • %s\nRezept: %s → %d %s\nBesitz: %d / %d %s", outputItem.Name, outputItem.Rarity, formatInputs(), outputAmount, outputItem.Name, currentOutput, maxStack, outputItem.Name)
	craft.Text = string.format("Craft %d %s", outputAmount, outputItem.Name)
	craft.Active = requirements and outputSpace
	craft.TextTransparency = craft.Active and 0 or 0.5
end

inventoryChanged.OnClientEvent:Connect(function(data)
	if type(data) == "table" then inventory = data; refresh() end
end)

player:GetAttributeChangedSignal("OpenCraftingMenu"):Connect(function()
	open = true
	panel.Visible = true
	inventoryRequest:FireServer()
	refresh()
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.B then
		if open then open = false; panel.Visible = false else open = true; panel.Visible = true; inventoryRequest:FireServer(); refresh() end
	end
end)

refresh()
