local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InteractionConfig = require(ReplicatedStorage.Config.InteractionConfig)

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
local folder = Workspace:WaitForChild("NPCs")

local function isCanonicalNPC(model, npcId)
	return model
		and model:IsA("Model")
		and model.Parent == folder
		and model.Name == npcId
		and model:GetAttribute("Interactable") == true
end

local function isNearModel(player, model)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local targetRoot = model and (model.PrimaryPart or model:FindFirstChild("Torso"))
	return isCanonicalNPC(model, model and model.Name) and root and targetRoot and (root.Position - targetRoot.Position).Magnitude <= NPC_INTERACTION_RANGE
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
		if player.Parent and player.Character == character then
			clearMenus(player)
		end
	end)
end

local function openDialog(player, npcId, character)
	clearMenus(player)
	task.defer(function()
		if player.Parent and player.Character == character and character.Parent then
			player:SetAttribute("OpenNPCDialog", npcId)
		end
	end)
end

local function bindPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") or prompt:GetAttribute("CrystalBoundMenuBound") then return end
	local model = prompt:FindFirstAncestorOfClass("Model")
	if not model or model.Parent ~= folder then return end
	if model.Name ~= "CrystalKeeper" and model.Name ~= "MaterialTrader" then return end
	if not isCanonicalNPC(model, model.Name) then return end
	prompt:SetAttribute("CrystalBoundMenuBound", true)
	prompt.Triggered:Connect(function(player)
		local character = player.Character
		if character and isNearModel(player, model) then
			openDialog(player, model.Name, character)
		end
	end)
end

for _, descendant in ipairs(folder:GetDescendants()) do bindPrompt(descendant) end
folder.DescendantAdded:Connect(bindPrompt)

for _, player in ipairs(Players:GetPlayers()) do bindPlayer(player) end
Players.PlayerAdded:Connect(bindPlayer)
Players.PlayerRemoving:Connect(function(player)
	disconnectPlayer(player)
	clearMenus(player)
end)
