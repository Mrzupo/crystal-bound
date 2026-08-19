local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestSystem = require(ReplicatedStorage.Modules.QuestSystem)
local XPService = require(script.Parent.XPService)
local EconomyService = require(script.Parent.EconomyService)
local PlayerService = require(script.Parent.PlayerService)

local QuestService = {}

local SERVER_TRIGGERED_SINGLE_STEP = {
	FIRST_FIGHT = true,
	GUARDIAN_TRIAL = true,
}

local function sync(player, profile)
	player:SetAttribute("ActiveQuestCount", #(profile.ActiveQuests or {}))
	player:SetAttribute("CompletedQuestCount", #(profile.CompletedQuests or {}))
end

local function copyArray(values)
	local result = {}
	if type(values) ~= "table" then return result end
	for index, value in ipairs(values) do
		result[index] = value
	end
	return result
end

function QuestService.GetActive(profile)
	return copyArray(profile.ActiveQuests)
end

function QuestService.GetCompleted(profile)
	return copyArray(profile.CompletedQuests)
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

function QuestService.Complete(player, profile, questId, message)
	local definition = QuestSystem.GetDefinition(questId)
	if not definition or not QuestSystem.IsActive(profile, questId) then return false end

	local progress = QuestSystem.GetProgress(profile, questId)
	local reachedGoal = progress >= (definition.Goal or 0)
	if not reachedGoal and not SERVER_TRIGGERED_SINGLE_STEP[questId] then
		if player then
			player:SetAttribute("QuestMessage", string.format("Complete the objective first: %d/%d", progress, definition.Goal or 0))
		end
		return false
	end

	if not QuestSystem.Complete(profile, questId) then return false end

	XPService.AddXP(profile, definition.XP)
	EconomyService.AddMoney(profile, definition.Money)
	PlayerService.Sync(player)
	sync(player, profile)
	if player then
		player:SetAttribute("QuestMessage", message or (definition.Name .. " complete!"))
	end
	QuestService.TryStartNext(player, profile)
	return true
end

function QuestService.TryStartNext(player, profile)
	for _, questId in ipairs(QuestSystem.GetChainOrder()) do
		local allowed = QuestSystem.CanStart(profile, questId)
		if allowed then
			return QuestService.Start(player, profile, questId)
		end
	end
	return false
end

return QuestService
