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

local function finiteNonNegativeInteger(value)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge or number < 0 or number % 1 ~= 0 then
		return nil
	end
	return math.floor(number)
end

local function validPlayerProfile(player, profile)
	return player ~= nil
		and player:IsA("Player")
		and player:GetAttribute("ProfileLoaded") == true
		and PlayerService.Profiles[player] == profile
		and type(profile) == "table"
end

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
	if not validPlayerProfile(player, profile) then return false end
	local allowed, reason = QuestSystem.CanStart(profile, questId)
	if not allowed then
		if reason then player:SetAttribute("QuestMessage", reason) end
		return false
	end
	local started = QuestSystem.Start(profile, questId)
	if started then
		PlayerService.Sync(player)
		sync(player, profile)
		local definition = QuestSystem.GetDefinition(questId)
		if definition then player:SetAttribute("QuestMessage", "Started: " .. definition.Name) end
	end
	return started
end

function QuestService.Complete(player, profile, questId, message)
	if not validPlayerProfile(player, profile) then return false end
	local definition = QuestSystem.GetDefinition(questId)
	if not definition or not QuestSystem.IsActive(profile, questId) then return false end

	local progress = QuestSystem.GetProgress(profile, questId)
	local reachedGoal = progress >= (definition.Goal or 0)
	if not reachedGoal and not SERVER_TRIGGERED_SINGLE_STEP[questId] then
		player:SetAttribute("QuestMessage", string.format("Complete the objective first: %d/%d", progress, definition.Goal or 0))
		return false
	end

	local rewardXP = finiteNonNegativeInteger(definition.XP)
	local rewardMoney = finiteNonNegativeInteger(definition.Money)
	if rewardXP == nil or rewardMoney == nil then
		player:SetAttribute("QuestMessage", "Quest reward configuration is unavailable.")
		return false
	end

	if not QuestSystem.Complete(profile, questId) then return false end

	XPService.AddXP(profile, rewardXP)
	local _, earnedMoney = EconomyService.AddMoney(profile, rewardMoney)
	PlayerService.Sync(player)
	sync(player, profile)
	if earnedMoney < rewardMoney then
		player:SetAttribute("QuestMessage", string.format("%s (Money capped at wallet limit; +%d Money)", message or (definition.Name .. " complete!"), earnedMoney))
	else
		player:SetAttribute("QuestMessage", message or (definition.Name .. " complete!"))
	end
	QuestService.TryStartNext(player, profile)
	return true
end

function QuestService.TryStartNext(player, profile)
	if not validPlayerProfile(player, profile) then return false end
	for _, questId in ipairs(QuestSystem.GetChainOrder()) do
		local allowed = QuestSystem.CanStart(profile, questId)
		if allowed then
			return QuestService.Start(player, profile, questId)
		end
	end
	return false
end

return QuestService
