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
	"OpenNPCDialog",
}

local function isNearModel(player, model)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local targetRoot = model and (model.PrimaryPart or model:FindFirstChild("Torso"))
	return root and targetRoot and (root.Position - targetRoot.Position).Magnitude <= NPC_INTERACTION_RANGE
end

local function clearMenus(player)
	for _, attribute in ipairs(MENU_ATTRIBUTES) do
		player:SetAttribute(attribute, nil)
	end
end

local function openDialog(player, npcId)
	clearMenus(player)
	task.defer(function()
		if player.Parent then
			player:SetAttribute("OpenNPCDialog", npcId)
		end
	end)
end

local function bindPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") or prompt:GetAttribute("CrystalBoundMenuBound") then return end
	prompt:SetAttribute("CrystalBoundMenuBound", true)
	local model = prompt:FindFirstAncestorOfClass("Model")
	if not model then return end
	prompt.Triggered:Connect(function(player)
		if (model.Name == "CrystalKeeper" or model.Name == "MaterialTrader") and isNearModel(player, model) then
			openDialog(player, model.Name)
		end
	end)
end

local folder = Workspace:WaitForChild("NPCs")
for _, descendant in ipairs(folder:GetDescendants()) do bindPrompt(descendant) end
folder.DescendantAdded:Connect(bindPrompt)

Players.PlayerRemoving:Connect(function(player)
	clearMenus(player)
end)
