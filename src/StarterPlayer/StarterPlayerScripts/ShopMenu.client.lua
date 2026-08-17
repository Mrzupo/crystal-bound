local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local inventoryRequest = remotes:WaitForChild("InventoryRequest")
local inventoryChanged = remotes:WaitForChild("InventoryChanged")

local sellable = {
	{ Id = "EmberShard", Price = 8 },
	{ Id = "TidePearl", Price = 14 },
	{ Id = "GaleFeather", Price = 22 },
	{ Id = "GuardianCore", Price = 250 },
	{ Id = "AncientShard", Price = 35 },
}

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
	panel.Size = UDim2.fromOffset(520, 410)
	panel.Visible = false
	panel.BackgroundTransparency = 0.08
	panel.Parent = gui
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Position = UDim2.fromOffset(18, 14)
	title.Size = UDim2.fromOffset(410, 38)
	title.BackgroundTransparency = 1
	title.Text = "Material Trader"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.Position = UDim2.fromOffset(460, 14)
	close.Size = UDim2.fromOffset(42, 36)
	close.Text = "X"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 18
	close.Parent = panel
	close.Activated:Connect(function() open = false; panel.Visible = false end)

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Position = UDim2.fromOffset(18, 55)
	status.Size = UDim2.fromOffset(484, 44)
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
	list.Size = UDim2.fromOffset(484, 260)
	list.BackgroundTransparency = 1
	list.Parent = panel

	for index, item in ipairs(sellable) do
		local row = Instance.new("Frame")
		row.Name = item.Id
		row.Position = UDim2.fromOffset(0, (index - 1) * 50)
		row.Size = UDim2.fromOffset(484, 44)
		row.BackgroundTransparency = 0.1
		row.Parent = list
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Position = UDim2.fromOffset(12, 0)
		label.Size = UDim2.fromOffset(260, 44)
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 15
		label.Parent = row

		local sell = Instance.new("TextButton")
		sell.Name = "Sell"
		sell.Position = UDim2.fromOffset(374, 6)
		sell.Size = UDim2.fromOffset(96, 32)
		sell.Text = "SELL x1"
		sell.Font = Enum.Font.GothamBold
		sell.TextSize = 13
		sell.Parent = row
		sell.Activated:Connect(function() inventoryRequest:FireServer("Sell", item.Id, 1) end)
	end

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.Position = UDim2.fromOffset(18, 370)
	hint.Size = UDim2.fromOffset(484, 26)
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
			row.Label.Text = string.format("%s  •  %d owned  •  %d Money each", item.Id, amount, item.Price)
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
