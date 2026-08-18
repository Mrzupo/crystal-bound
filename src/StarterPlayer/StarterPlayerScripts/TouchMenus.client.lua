local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

if not UserInputService.TouchEnabled then return end

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "TouchMenus"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function openByAttribute(attributeName)
	player:SetAttribute(attributeName, os.clock())
end

local function makeButton(name, text, index, attributeName)
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
	button.Activated:Connect(function() openByAttribute(attributeName) end)
end

makeButton("Inventory", "Items", 1, "OpenCrystalMenu")
makeButton("Quests", "Quests", 2, "OpenQuestMenu")
makeButton("Shop", "Shop", 3, "OpenShopMenu")
makeButton("Achievements", "Goals", 4, "OpenAchievementMenu")
makeButton("Crafting", "Craft", 5, "OpenCraftingMenu")

local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.Position = UDim2.fromOffset(18, 110)
hint.Size = UDim2.fromOffset(420, 26)
hint.BackgroundTransparency = 1
hint.Text = "Tap a menu button above"
hint.Font = Enum.Font.Gotham
hint.TextSize = 11
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Parent = gui
