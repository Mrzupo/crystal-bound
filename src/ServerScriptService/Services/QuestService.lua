local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestSystem = require(ReplicatedStorage.Modules.QuestSystem)

local QuestService = {}

local function sync(player, profile)
	local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("GetQuestData")
	if remote then
		player:SetAttribute("ActiveQuestCount", #profile.ActiveQuests)
		player:SetAttribute("CompletedQuestCount", #profile.CompletedQuests)
	end
end

function QuestService.GetActive(profile)
	return profile.ActiveQuests
end

function QuestService.GetCompleted(profile)
	return profile.CompletedQuests
end

function QuestService.Start(player, profile, questId)
	local started = QuestSystem.Start(profile, questId)
	if started then sync(player, profile) end
	return started
end

function QuestService.Complete(player, profile, questId, XPService, EconomyService, PlayerService)
	local definition = QuestSystem.GetDefinition(questId)
	if not definition or not QuestSystem.Complete(profile, questId) then return false end
	XPService.AddXP(profile, definition.XP)
	EconomyService.AddMoney(profile, definition.Money)
	PlayerService.Sync(player)
	sync(player, profile)
	return true
end

return QuestService
