local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

if not UserInputService.TouchEnabled then return end

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "TouchMenus"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function toggle(screenGuiName)
	local target = player.PlayerGui:FindFirstChild(screenGuiName)
	if not target then return end
	local panel = target:FindFirstChild("Panel")
	if panel then panel.Visible = not panel.Visible end
end

local function makeButton(name, text, index, targetGui)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = UDim2.fromOffset(18 + (index - 1) * 82, 68)
	button.Size = UDim2.fromOffset(74, 38)
	button.BackgroundTransparency = 0.18
	button.Text = text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 12
	button.Parent = gui
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
	button.Activated:Connect(function() toggle(targetGui) end)
end

makeButton("Inventory", "Items", 1, "CrystalMenu")
makeButton("Quests", "Quests", 2, "QuestMenu")
makeButton("Shop", "Shop", 3, "ShopMenu")
makeButton("Achievements", "Goals", 4, "AchievementMenu")

local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.Position = UDim2.fromOffset(18, 110)
hint.Size = UDim2.fromOffset(310, 26)
hint.BackgroundTransparency = 1
hint.Text = "Tap a menu button above"
hint.Font = Enum.Font.Gotham
hint.TextSize = 11
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Parent = gui
