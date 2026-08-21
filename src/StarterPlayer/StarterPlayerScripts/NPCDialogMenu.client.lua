local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local dialogRequest = remotes:WaitForChild("NPCDialogRequest")

local MENU_ATTRIBUTES = {
	"OpenQuestMenu",
	"OpenShopMenu",
	"OpenCrystalMenu",
	"OpenCraftingMenu",
	"OpenAchievementMenu",
	"OpenNPCDialog",
}

local function clearMenuState()
	for _, attribute in ipairs(MENU_ATTRIBUTES) do
		player:SetAttribute(attribute, nil)
	end
end

local function clearOtherMenuState()
	for _, attribute in ipairs(MENU_ATTRIBUTES) do
		if attribute ~= "OpenNPCDialog" then
			player:SetAttribute(attribute, nil)
		end
	end
end

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
close.Activated:Connect(function()
	panel.Visible = false
	clearMenuState()
end)

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
local dialogRequestGeneration = 0
local DIALOG_RETRY_DELAY = 0.25
local openDialog

local function clearOptions()
	for _, child in ipairs(options:GetChildren()) do child:Destroy() end
end

local function invalidateDialogRequest()
	dialogRequestGeneration += 1
	panel.Visible = false
	clearMenuState()
end

local function showNextLine()
	if #currentLines == 0 then return end
	line.Text = tostring(currentLines[currentIndex] or "")
	currentIndex = currentIndex % #currentLines + 1
end

local function openTargetMenu(optionId)
	panel.Visible = false
	clearMenuState()
	if optionId == "QUEST" then
		player:SetAttribute("OpenQuestMenu", os.clock())
	elseif optionId == "CRYSTAL" or optionId == "INVENTORY" then
		player:SetAttribute("OpenCrystalMenu", os.clock())
	elseif optionId == "SHOP" then
		player:SetAttribute("OpenShopMenu", os.clock())
	elseif optionId == "CRAFT" then
		player:SetAttribute("OpenCraftingMenu", os.clock())
	end
end

local function scheduleDialogRetry(npcId, character, generation)
	task.delay(DIALOG_RETRY_DELAY, function()
		if generation == dialogRequestGeneration and player.Character == character and character.Parent and player:GetAttribute("OpenNPCDialog") == npcId then
			openDialog(npcId, character, generation)
		end
	end)
end

openDialog = function(npcId, character, generation)
	local ok, data = pcall(function() return dialogRequest:InvokeServer(npcId) end)
	if generation ~= dialogRequestGeneration or player.Character ~= character or not character or not character.Parent or player:GetAttribute("OpenNPCDialog") ~= npcId then
		return
	end
	if not ok or type(data) ~= "table" then
		scheduleDialogRetry(npcId, character, generation)
		return
	end
	clearOtherMenuState()
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
			openTargetMenu(option.Id)
		end)
	end
	panel.Visible = true
end

player:GetAttributeChangedSignal("OpenNPCDialog"):Connect(function()
	dialogRequestGeneration += 1
	local generation = dialogRequestGeneration
	local npcId = player:GetAttribute("OpenNPCDialog")
	if type(npcId) == "string" and npcId ~= "" then
		local character = player.Character
		if character and character.Parent then
			openDialog(npcId, character, generation)
		end
	else
		panel.Visible = false
		clearOptions()
		currentLines = {}
		currentIndex = 1
	end
end)

player.CharacterAdded:Connect(function()
	invalidateDialogRequest()
end)
player.CharacterRemoving:Connect(function()
	invalidateDialogRequest()
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not panel.Visible then return end
	if input.KeyCode == Enum.KeyCode.Space then showNextLine() end
end)
