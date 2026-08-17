local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestSystem = require(ReplicatedStorage.Modules.QuestSystem)

local QuestService = {}

local QuestOrder = {
	"FIRST_FIGHT",
	"CRYSTAL_POWER",
	"HUNT_EMBERLINGS",
	"TIDE_EXPEDITION",
	"WIND_TRIAL",
	"GUARDIAN_TRIAL",
	"GOLEM_HUNT",
	"BAT_HUNT",
}

local function sync(player, profile)
	player:SetAttribute("ActiveQuestCount", #(profile.ActiveQuests or {}))
	player:SetAttribute("CompletedQuestCount", #(profile.CompletedQuests or {}))
end

function QuestService.GetActive(profile)
	return profile.ActiveQuests or {}
end

function QuestService.GetCompleted(profile)
	return profile.CompletedQuests or {}
end

function QuestService.Start(player, profile, questId)
	local allowed, reason = QuestSystem.CanStart(profile, questId)
	if not allowed then
		if player and reason then player:SetAttribute("QuestMessage", reason) end
		return false
	end
	local started = QuestSystem.Start(profile, questId)
	if started then
		sync(player, profile)
		local definition = QuestSystem.GetDefinition(questId)
		if definition then player:SetAttribute("QuestMessage", "Started: " .. definition.Name) end
	end
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

function QuestService.TryStartNext(player, profile)
	for _, questId in ipairs(QuestOrder) do
		local allowed = QuestSystem.CanStart(profile, questId)
		if allowed then
			return QuestService.Start(player, profile, questId)
		end
	end
	return false
end

return QuestService
