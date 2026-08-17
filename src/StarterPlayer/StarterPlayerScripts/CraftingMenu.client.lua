local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local craftingRequest = remotes:WaitForChild("CraftingRequest")
local inventoryRequest = remotes:WaitForChild("InventoryRequest")
local inventoryChanged = remotes:WaitForChild("InventoryChanged")

local inventory = {}
local open = false

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

local recipe = Instance.new("TextLabel")
recipe.Position = UDim2.fromOffset(18, 65)
recipe.Size = UDim2.fromOffset(484, 80)
recipe.BackgroundTransparency = 1
recipe.TextWrapped = true
recipe.TextXAlignment = Enum.TextXAlignment.Left
recipe.TextYAlignment = Enum.TextYAlignment.Top
recipe.Font = Enum.Font.Gotham
recipe.TextSize = 16
recipe.Parent = panel

local craft = Instance.new("TextButton")
craft.Position = UDim2.fromOffset(18, 165)
craft.Size = UDim2.fromOffset(484, 48)
craft.Text = "Craft 1 Health Potion"
craft.Font = Enum.Font.GothamBold
craft.TextSize = 16
craft.Parent = panel
craft.Activated:Connect(function() craftingRequest:FireServer("Craft", "HealthPotion", 1) end)

local hint = Instance.new("TextLabel")
hint.Position = UDim2.fromOffset(18, 230)
hint.Size = UDim2.fromOffset(484, 40)
hint.BackgroundTransparency = 1
hint.Text = "C = Crafting öffnen/schließen"
hint.Font = Enum.Font.Gotham
hint.TextSize = 14
hint.TextXAlignment = Enum.TextXAlignment.Right
hint.Parent = panel

local function refresh()
	local ember = math.floor(tonumber(inventory.EmberShard) or 0)
	local tide = math.floor(tonumber(inventory.TidePearl) or 0)
	local potions = math.floor(tonumber(inventory.HealthPotion) or 0)
	recipe.Text = string.format("Health Potion • Uncommon\nRezept: 2 Ember Shard + 1 Tide Pearl → 1 Health Potion\nBesitz: %d Ember Shard | %d Tide Pearl | %d Potions", ember, tide, potions)
	craft.Active = ember >= 2 and tide >= 1 and potions < 20
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
	if input.KeyCode == Enum.KeyCode.C then
		if open then open = false; panel.Visible = false else open = true; panel.Visible = true; inventoryRequest:FireServer(); refresh() end
	end
end)

refresh()
