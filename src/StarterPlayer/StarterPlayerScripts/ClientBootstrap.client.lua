local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatRemote = remotes:WaitForChild("CombatRequest")
local xpChanged = remotes:WaitForChild("XPChanged")
local levelUp = remotes:WaitForChild("LevelUp")
local moneyChanged = remotes:WaitForChild("MoneyChanged")

local function getTargetFromMouse()
	local mouse = player:GetMouse()
	local hit = mouse.Target
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
		panel.Size = UDim2.fromOffset(300, 118)
		panel.BackgroundTransparency = 0.2
		panel.Parent = gui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = panel

		local label = Instance.new("TextLabel")
		label.Name = "Stats"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Top
		label.TextWrapped = true
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 18
		label.Parent = panel

		local help = Instance.new("TextLabel")
		help.Name = "Help"
		help.AnchorPoint = Vector2.new(0.5, 1)
		help.Position = UDim2.new(0.5, 0, 1, -18)
		help.Size = UDim2.fromOffset(520, 40)
		help.BackgroundTransparency = 0.25
		help.Text = "Klick = Angriff    Q = Kristallfähigkeit    Triff die Trainingspuppe"
		help.Font = Enum.Font.GothamBold
		help.TextSize = 18
		help.Parent = gui
	end
	return panel.Stats
end

local statsLabel = ensureHud()

local function refreshHud()
	statsLabel.Text = string.format(
		"Crystal Bound\nLevel: %d    XP: %d\nMoney: %d\nCrystal: %s",
		player:GetAttribute("Level") or 1,
		player:GetAttribute("Experience") or 0,
		player:GetAttribute("Money") or 0,
		player:GetAttribute("EquippedCrystal") or "EMBER"
	)
end

for _, attribute in ipairs({ "Level", "Experience", "Money", "EquippedCrystal" }) do
	player:GetAttributeChangedSignal(attribute):Connect(refreshHud)
end

xpChanged.OnClientEvent:Connect(refreshHud)
moneyChanged.OnClientEvent:Connect(refreshHud)
levelUp.OnClientEvent:Connect(refreshHud)
refreshHud()

local mouse = player:GetMouse()
mouse.Button1Down:Connect(function()
	local target = getTargetFromMouse()
	if target then
		combatRemote:FireServer("Basic", target)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Q then
		local target = getTargetFromMouse()
		if target then
			combatRemote:FireServer("Ability", target)
		end
	end
end)

print("Crystal Bound client ready")