local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local dialogRequest = remotes:WaitForChild("NPCDialogRequest")

local gui = Instance.new("ScreenGui")
gui.Name = "NPCDialogMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -30)
panel.Size = UDim2.fromOffset(620, 230)
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(18, 12)
title.Size = UDim2.fromOffset(520, 34)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local close = Instance.new("TextButton")
close.Position = UDim2.fromOffset(565, 12)
close.Size = UDim2.fromOffset(36, 32)
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.Parent = panel
close.Activated:Connect(function() panel.Visible = false end)

local line = Instance.new("TextLabel")
line.Position = UDim2.fromOffset(18, 52)
line.Size = UDim2.fromOffset(584, 78)
line.BackgroundTransparency = 1
line.TextWrapped = true
line.TextXAlignment = Enum.TextXAlignment.Left
line.TextYAlignment = Enum.TextYAlignment.Top
line.Font = Enum.Font.Gotham
line.TextSize = 16
line.Parent = panel

local options = Instance.new("Frame")
options.Position = UDim2.fromOffset(18, 138)
options.Size = UDim2.fromOffset(584, 70)
options.BackgroundTransparency = 1
options.Parent = panel

local currentLines = {}
local currentIndex = 1

local function clearOptions()
	for _, child in ipairs(options:GetChildren()) do child:Destroy() end
end

local function showNextLine()
	if #currentLines == 0 then return end
	line.Text = tostring(currentLines[currentIndex] or "")
	currentIndex = currentIndex % #currentLines + 1
end

local function openDialog(npcId)
	local ok, data = pcall(function() return dialogRequest:InvokeServer(npcId) end)
	if not ok or type(data) ~= "table" then
		panel.Visible = false
		return
	end
	currentLines = type(data.Lines) == "table" and data.Lines or {}
	currentIndex = 1
	title.Text = data.Name or npcId
	showNextLine()
	clearOptions()
	for index, option in ipairs(type(data.Options) == "table" and data.Options or {}) do
		if type(option) ~= "table" then continue end
		local button = Instance.new("TextButton")
		button.Position = UDim2.fromOffset((index - 1) * 190, 0)
		button.Size = UDim2.fromOffset(176, 38)
		button.Text = option.Label or option.Id or "Option"
		button.Font = Enum.Font.GothamBold
		button.TextSize = 13
		button.Parent = options
		button.Activated:Connect(function()
			if option.Id == "QUEST" then player:SetAttribute("OpenQuestMenu", os.clock())
			elseif option.Id == "CRYSTAL" then player:SetAttribute("OpenCrystalMenu", os.clock())
			elseif option.Id == "SHOP" then player:SetAttribute("OpenShopMenu", os.clock())
			elseif option.Id == "INVENTORY" then player:SetAttribute("OpenCrystalMenu", os.clock())
			elseif option.Id == "CRAFT" then player:SetAttribute("OpenCraftingMenu", os.clock()) end
		end)
	end
	panel.Visible = true
end

player:GetAttributeChangedSignal("OpenNPCDialog"):Connect(function()
	local npcId = player:GetAttribute("OpenNPCDialog")
	if type(npcId) == "string" and npcId ~= "" then openDialog(npcId) end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not panel.Visible then return end
	if input.KeyCode == Enum.KeyCode.Space then showNextLine() end
end)
