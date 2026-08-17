local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

if not UserInputService.TouchEnabled then return end

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatRemote = remotes:WaitForChild("CombatRequest")
local crystalChanged = remotes:WaitForChild("CrystalChanged")
local currentTarget

local function rayTarget(position)
	local camera = Workspace.CurrentCamera
	if not camera then return nil end
	local ray = camera:ViewportPointToRay(position.X, position.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	if not result then return nil end
	return result.Instance:FindFirstAncestorOfClass("Model") or result.Instance
end

UserInputService.TouchTap:Connect(function(touchPositions, processed)
	if processed or not touchPositions or not touchPositions[1] then return end
	currentTarget = rayTarget(touchPositions[1])
end)

local gui = Instance.new("ScreenGui")
gui.Name = "TouchControls"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function makeButton(name, text, position, size, callback)
	local button = Instance.new("TextButton")
	button.Name = name; button.Position = position; button.Size = size; button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundTransparency = 0.18; button.Text = text; button.Font = Enum.Font.GothamBold; button.TextSize = 16; button.Parent = gui
	Instance.new("UICorner", button).CornerRadius = UDim.new(1, 0)
	button.Activated:Connect(callback)
	return button
end

makeButton("Attack", "ATK", UDim2.new(1, -95, 1, -100), UDim2.fromOffset(86, 86), function()
	if currentTarget then combatRemote:FireServer("Basic", currentTarget) end
end)
makeButton("Ability", "Q", UDim2.new(1, -195, 1, -165), UDim2.fromOffset(74, 74), function()
	if currentTarget then combatRemote:FireServer("Ability", currentTarget) end
end)
makeButton("Ember", "E", UDim2.new(0, 60, 1, -110), UDim2.fromOffset(64, 64), function() crystalChanged:FireServer("EMBER") end)
makeButton("Tide", "T", UDim2.new(0, 135, 1, -150), UDim2.fromOffset(64, 64), function() crystalChanged:FireServer("TIDE") end)
makeButton("Gale", "G", UDim2.new(0, 210, 1, -110), UDim2.fromOffset(64, 64), function() crystalChanged:FireServer("GALE") end)

local info = Instance.new("TextLabel")
info.Name = "Hint"; info.AnchorPoint = Vector2.new(0.5, 1); info.Position = UDim2.new(0.5, 0, 1, -62); info.Size = UDim2.fromOffset(420, 32)
info.BackgroundTransparency = 0.3; info.Text = "Touch Controls • Tap an enemy to target"; info.Font = Enum.Font.GothamMedium; info.TextSize = 13; info.Parent = gui
Instance.new("UICorner", info).CornerRadius = UDim.new(0, 8)
