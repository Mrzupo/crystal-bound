local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InteractionConfig = require(ReplicatedStorage.Config.InteractionConfig)
local PlayerService = require(script.Parent.Services.PlayerService)

local NPC_INTERACTION_RANGE = math.clamp(tonumber(InteractionConfig.NPCInteractionRange) or 14, 4, 50)
local MENU_ATTRIBUTES = {
	"OpenQuestMenu",
	"OpenShopMenu",
	"OpenCrystalMenu",
	"OpenCraftingMenu",
	"OpenAchievementMenu",
	"OpenNPCDialog",
}
local playerCharacterConnections = setmetatable({}, { __mode = "k" })
local NPC_IDS = {
	CrystalKeeper = true,
	MaterialTrader = true,
}

local function isCanonicalNPC(model)
	local folder = Workspace:FindFirstChild("NPCs")
	return folder ~= nil
		and model ~= nil
		and model:IsA("Model")
		and model.Parent == folder
		and NPC_IDS[model.Name] == true
		and model:GetAttribute("Interactable") == true
end

local function isNearModel(player, model)
	if not isCanonicalNPC(model) then return false end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local targetRoot = model.PrimaryPart or model:FindFirstChild("Torso")
	return root and targetRoot and (root.Position - targetRoot.Position).Magnitude <= NPC_INTERACTION_RANGE
end

local function clearMenus(player)
	for _, attribute in ipairs(MENU_ATTRIBUTES) do
		player:SetAttribute(attribute, nil)
	end
end

local function disconnectPlayer(player)
	local connection = playerCharacterConnections[player]
	if connection and connection.Connected then connection:Disconnect() end
	playerCharacterConnections[player] = nil
end

local function bindPlayer(player)
	disconnectPlayer(player)
	clearMenus(player)
	playerCharacterConnections[player] = player.CharacterAdded:Connect(function(character)
		if PlayerService.ShuttingDown then return end
		if player.Parent and player.Character == character then
			clearMenus(player)
		end
	end)
end

local function openDialog(player, npcId, character)
	if PlayerService.ShuttingDown or player:GetAttribute("ProfileLoaded") ~= true then return end
	clearMenus(player)
	task.defer(function()
		if PlayerService.ShuttingDown or player:GetAttribute("ProfileLoaded") ~= true then return end
		if player.Parent and player.Character == character and character.Parent then
			player:SetAttribute("OpenNPCDialog", npcId)
		end
	end)
end

local function bindPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") or prompt:GetAttribute("CrystalBoundMenuBound") then return end
	prompt:SetAttribute("CrystalBoundMenuBound", true)
	local model = prompt:FindFirstAncestorOfClass("Model")
	if not isCanonicalNPC(model) then return end
	prompt.Triggered:Connect(function(player)
		if PlayerService.ShuttingDown or player:GetAttribute("ProfileLoaded") ~= true then return end
		if isNearModel(player, model) then
			openDialog(player, model.Name, player.Character)
		end
	end)
end

local folder = Workspace:WaitForChild("NPCs")
for _, descendant in ipairs(folder:GetDescendants()) do bindPrompt(descendant) end
folder.DescendantAdded:Connect(bindPrompt)

for _, player in ipairs(Players:GetPlayers()) do bindPlayer(player) end
Players.PlayerAdded:Connect(bindPlayer)
Players.PlayerRemoving:Connect(function(player)
	disconnectPlayer(player)
	clearMenus(player)
end)
