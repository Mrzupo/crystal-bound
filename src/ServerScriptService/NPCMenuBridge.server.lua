local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InteractionConfig = require(ReplicatedStorage.Config.InteractionConfig)

local NPC_INTERACTION_RANGE = math.max(1, tonumber(InteractionConfig.NPCInteractionRange) or 14)

local function isNearModel(player, model)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local targetRoot = model and (model.PrimaryPart or model:FindFirstChild("Torso"))
	return root and targetRoot and (root.Position - targetRoot.Position).Magnitude <= NPC_INTERACTION_RANGE
end

local function openDialog(player, npcId)
	player:SetAttribute("OpenNPCDialog", nil)
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
	player:SetAttribute("OpenQuestMenu", nil)
	player:SetAttribute("OpenShopMenu", nil)
	player:SetAttribute("OpenCrystalMenu", nil)
	player:SetAttribute("OpenCraftingMenu", nil)
	player:SetAttribute("OpenNPCDialog", nil)
end)
