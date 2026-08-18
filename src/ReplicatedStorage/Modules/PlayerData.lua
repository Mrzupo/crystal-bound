local PlayerData = {}
local InventoryConfig = require(game.ReplicatedStorage.Config.InventoryConfig)
local EconomyConfig = require(game.ReplicatedStorage.Config.EconomyConfig)
local XPConfig = require(game.ReplicatedStorage.Config.XPConfig)
local CrystalConfig = require(game.ReplicatedStorage.Config.CrystalConfig)
local CrystalUpgradeConfig = require(game.ReplicatedStorage.Config.CrystalUpgradeConfig)
local WorldConfig = require(game.ReplicatedStorage.Config.WorldConfig)
local AchievementSystem = require(script.Parent.AchievementSystem)
local QuestSystem = require(script.Parent.QuestSystem)

local VALID_BOUNTY_ENEMIES = {
	Emberling = true,
	Tidecrawler = true,
	Galewisp = true,
	CrystalBat = true,
	AncientGolem = true,
}

local function isFiniteNumber(value)
	return type(value) == "number" and value == value and value < math.huge and value > -math.huge
end

local function clone(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = clone(child) end
	return result
end

local function clampInt(value, minimum, maximum, fallback)
	local number = tonumber(value)
	if not isFiniteNumber(number) then return fallback end
	return math.clamp(math.floor(number), minimum, maximum)
end

local function normalizeList(list, validator)
	local result, seen = {}, {}
	if type(list) ~= "table" then return result end
	for _, value in ipairs(list) do
		if type(value) == "string" and (not validator or validator(value)) and not seen[value] then
			seen[value] = true
			table.insert(result, value)
		end
	end
	return result
end

local function normalizeInventory(inventory)
	local result = {}
	if type(inventory) ~= "table" then return result end
	for itemId, amount in pairs(inventory) do
		if type(itemId) == "string" and InventoryConfig.GetItemConfig(itemId) then
			local maxStack = InventoryConfig.GetMaxStackSize(itemId)
			local normalized = clampInt(amount, 0, maxStack, 0)
			if normalized > 0 then result[itemId] = normalized end
		end
	end
	return result
end

local function isQuestId(value)
	return type(value) == "string" and QuestSystem.GetDefinition(value) ~= nil
end

local function isAchievementId(value)
	return type(value) == "string" and AchievementSystem.Get(value) ~= nil
end

local function titleMatchesAchievement(title, unlocked)
	if not AchievementSystem.IsValidTitle(title) then return false end
	for achievementId in pairs(unlocked) do
		local definition = AchievementSystem.Get(achievementId)
		if definition and definition.Title == title then return true end
	end
	return false
end

local function isCrystalId(value)
	return type(value) == "string" and CrystalConfig.UnlockLevels[value] ~= nil
end

local function isIslandId(value)
	return type(value) == "string" and WorldConfig.Islands[value] ~= nil
end

function PlayerData.new()
	return {
		Version = 13,
		Level = 1,
		Experience = 0,
		Crystals = { Owned = { "EMBER" }, Equipped = "EMBER" },
		CrystalMastery = { EMBER = { Level = 1, XP = 0 }, TIDE = { Level = 1, XP = 0 }, GALE = { Level = 1, XP = 0 } },
		Money = EconomyConfig.StartingMoney,
		Stats = { Damage = 10, Health = 100, EnemiesDefeated = 0, BossesDefeated = 0, AncientGolemsDefeated = 0, CrystalBatsDefeated = 0 },
		Inventory = {},
		ActiveQuests = {}, CompletedQuests = {}, QuestProgress = {},
		UnlockedIslands = { "STARTER" },
		Titles = {}, Achievements = {},
		DailyBounty = { Date = "", EnemyType = "Emberling", Goal = 8, Progress = 0, RewardMoney = 120, Claimed = false },
		SessionId = "",
		SessionLockedAt = 0,
		SessionLock = nil,
	}
end

function PlayerData.Reconcile(data)
	local defaults = PlayerData.new()
	data = type(data) == "table" and data or {}
	local oldVersion = tonumber(data.Version) or 0
	local masteryMaxLevel = math.max(1, math.floor(tonumber(CrystalUpgradeConfig.MaxLevel) or 10))

	local function merge(target, fallback)
		for key, value in pairs(fallback) do
			if target[key] == nil then
				target[key] = clone(value)
			elseif type(value) == "table" and type(target[key]) == "table" then
				merge(target[key], value)
			end
		end
	end
	merge(data, defaults)

	data.Level = clampInt(data.Level, 1, XPConfig.MaxLevel, defaults.Level)
	data.Experience = clampInt(data.Experience, 0, 1000000000, defaults.Experience)
	if data.Level >= XPConfig.MaxLevel then data.Experience = 0 end
	data.Money = clampInt(data.Money, EconomyConfig.MinMoney, EconomyConfig.MaxMoney, defaults.Money)

	data.Crystals = type(data.Crystals) == "table" and data.Crystals or clone(defaults.Crystals)
	data.Crystals.Owned = normalizeList(data.Crystals.Owned, isCrystalId)
	if not table.find(data.Crystals.Owned, "EMBER") then table.insert(data.Crystals.Owned, "EMBER") end
	if not isCrystalId(data.Crystals.Equipped) or not table.find(data.Crystals.Owned, data.Crystals.Equipped) then data.Crystals.Equipped = "EMBER" end

	local sourceMastery = type(data.CrystalMastery) == "table" and data.CrystalMastery or {}
	local normalizedMastery = {}
	for crystalId in pairs(CrystalConfig.UnlockLevels) do
		local source = type(sourceMastery[crystalId]) == "table" and sourceMastery[crystalId] or {}
		local mastery = {
			Level = clampInt(source.Level, 1, masteryMaxLevel, 1),
			XP = clampInt(source.XP, 0, 100000000, 0),
		}
		if mastery.Level >= masteryMaxLevel then mastery.XP = 0 end
		normalizedMastery[crystalId] = mastery
	end
	data.CrystalMastery = normalizedMastery

	data.Stats = type(data.Stats) == "table" and data.Stats or clone(defaults.Stats)
	data.Stats.Damage = clampInt(data.Stats.Damage, 0, 100000, defaults.Stats.Damage)
	data.Stats.Health = clampInt(data.Stats.Health, 1, 1000000, defaults.Stats.Health)
	data.Stats.EnemiesDefeated = clampInt(data.Stats.EnemiesDefeated, 0, 100000000, 0)
	data.Stats.BossesDefeated = clampInt(data.Stats.BossesDefeated, 0, 100000000, 0)
	data.Stats.AncientGolemsDefeated = clampInt(data.Stats.AncientGolemsDefeated, 0, 100000000, 0)
	data.Stats.CrystalBatsDefeated = clampInt(data.Stats.CrystalBatsDefeated, 0, 100000000, 0)

	data.Achievements = normalizeList(data.Achievements, isAchievementId)
	local achievementSet = {}
	for _, achievementId in ipairs(data.Achievements) do achievementSet[achievementId] = true end
	data.Titles = normalizeList(data.Titles, function(title) return titleMatchesAchievement(title, achievementSet) end)
	data.Inventory = normalizeInventory(data.Inventory)
	data.ActiveQuests = normalizeList(data.ActiveQuests, isQuestId)
	data.CompletedQuests = normalizeList(data.CompletedQuests, isQuestId)

	local completedSet = {}
	for _, questId in ipairs(data.CompletedQuests) do completedSet[questId] = true end
	local filteredActive = {}
	for _, questId in ipairs(data.ActiveQuests) do
		if not completedSet[questId] and #filteredActive == 0 then table.insert(filteredActive, questId) end
	end
	data.ActiveQuests = filteredActive

	data.QuestProgress = type(data.QuestProgress) == "table" and data.QuestProgress or {}
	local normalizedProgress = {}
	for questId, progress in pairs(data.QuestProgress) do
		if isQuestId(questId) then
			local definition = QuestSystem.GetDefinition(questId)
			normalizedProgress[questId] = math.clamp(clampInt(progress, 0, definition.Goal, 0), 0, definition.Goal)
		end
	end
	data.QuestProgress = normalizedProgress

	data.UnlockedIslands = normalizeList(data.UnlockedIslands, isIslandId)
	if not table.find(data.UnlockedIslands, "STARTER") and WorldConfig.Islands.STARTER then table.insert(data.UnlockedIslands, "STARTER") end

	data.DailyBounty = type(data.DailyBounty) == "table" and data.DailyBounty or clone(defaults.DailyBounty)
	data.DailyBounty.Date = type(data.DailyBounty.Date) == "string" and data.DailyBounty.Date or ""
	if not VALID_BOUNTY_ENEMIES[data.DailyBounty.EnemyType] then data.DailyBounty.EnemyType = defaults.DailyBounty.EnemyType end
	data.DailyBounty.Goal = clampInt(data.DailyBounty.Goal, 1, 100, defaults.DailyBounty.Goal)
	data.DailyBounty.Progress = clampInt(data.DailyBounty.Progress, 0, data.DailyBounty.Goal, 0)
	data.DailyBounty.RewardMoney = clampInt(data.DailyBounty.RewardMoney, 0, EconomyConfig.MaxMoney, defaults.DailyBounty.RewardMoney)
	data.DailyBounty.Claimed = data.DailyBounty.Claimed == true

	data.SessionId = type(data.SessionId) == "string" and data.SessionId or ""
	data.SessionLockedAt = clampInt(data.SessionLockedAt, 0, 4102444800, 0)
	if type(data.SessionLock) ~= "table" then
		data.SessionLock = nil
	else
		local jobId = type(data.SessionLock.JobId) == "string" and data.SessionLock.JobId or ""
		local sessionTimestamp = clampInt(data.SessionLock.Timestamp, 0, 4102444800, 0)
		data.SessionLock = jobId ~= "" and sessionTimestamp > 0 and { JobId = jobId, Timestamp = sessionTimestamp } or nil
	end

	data.Version = defaults.Version
	data.LegacyVersion = oldVersion
	return data
end

return PlayerData
