local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EconomyConfig = require(ReplicatedStorage.Config.EconomyConfig)
local InventoryConfig = require(ReplicatedStorage.Config.InventoryConfig)
local XPConfig = require(ReplicatedStorage.Config.XPConfig)
local WorldConfig = require(ReplicatedStorage.Config.WorldConfig)
local CrystalSystem = require(ReplicatedStorage.Modules.CrystalSystem)
local CrystalUpgradeConfig = require(ReplicatedStorage.Config.CrystalUpgradeConfig)
local CrystalMastery = require(ReplicatedStorage.Modules.CrystalMastery)
local DailyBountyConfig = require(ReplicatedStorage.Config.DailyBountyConfig)
local AchievementSystem = require(ReplicatedStorage.Modules.AchievementSystem)
local QuestSystem = require(ReplicatedStorage.Modules.QuestSystem)

local PlayerData = {}

local function finiteNumber(value)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return nil end
	return number
end

local function clampInt(value, minimum, maximum, fallback)
	local number = finiteNumber(value)
	if number == nil then number = fallback end
	return math.clamp(math.floor(number), minimum, maximum)
end

local function clone(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = clone(child) end
	return result
end

local function normalizeList(value, validator)
	local result = {}
	if type(value) ~= "table" then return result end
	for _, entry in ipairs(value) do
		if validator(entry) and not table.find(result, entry) then table.insert(result, entry) end
	end
	return result
end

local function CrystalSystemExists(value)
	return type(value) == "string" and CrystalSystem.Exists(value)
end

local function capExperienceBelowNextLevel(level, experience, maxLevel, maxExperience, requiredXP)
	if level >= maxLevel then return 0 end
	local required = requiredXP(level)
	return math.clamp(experience, 0, math.max(0, required - 1))
end

local function firstDailyBounty()
	local goals = DailyBountyConfig.Goals
	local definition = type(goals) == "table" and goals[1] or {}
	return {
		Date = "",
		EnemyType = type(definition.EnemyType) == "string" and definition.EnemyType or "",
		Goal = clampInt(definition.Goal, 1, 100, 1),
		Progress = 0,
		RewardMoney = clampInt(definition.RewardMoney, 0, EconomyConfig.MaxMoney, 0),
		Claimed = false,
	}
end

function PlayerData.new()
	return {
		Version = 4,
		LegacyVersion = 0,
		Level = 1,
		Experience = 0,
		Money = EconomyConfig.StartingMoney,
		Inventory = {},
		Crystals = { Owned = { "EMBER" }, Equipped = "EMBER" },
		CrystalMastery = { EMBER = { Level = 1, XP = 0 } },
		ActiveQuests = {},
		CompletedQuests = {},
		QuestProgress = {},
		UnlockedIslands = { "STARTER" },
		Stats = { Damage = 10, EnemiesDefeated = 0, BossesDefeated = 0, AncientGolemsDefeated = 0, CrystalBatsDefeated = 0 },
		Achievements = {},
		Titles = {},
		DailyBounty = firstDailyBounty(),
		SessionId = "",
		SessionLockedAt = 0,
		SessionLock = nil,
	}
end

function PlayerData.Reconcile(input)
	local defaults = PlayerData.new()
	local data = type(input) == "table" and clone(input) or defaults
	local oldVersion = clampInt(data.Version, 0, 1000, 0)

	data.Level = clampInt(data.Level, 1, XPConfig.MaxLevel, defaults.Level)
	data.Experience = clampInt(data.Experience, 0, XPConfig.MaxExperience, defaults.Experience)
	data.Experience = capExperienceBelowNextLevel(data.Level, data.Experience, XPConfig.MaxLevel, XPConfig.MaxExperience, XPConfig.GetRequiredXP)
	data.Money = clampInt(data.Money, EconomyConfig.MinMoney, EconomyConfig.MaxMoney, defaults.Money)

	local inventory = {}
	if type(data.Inventory) == "table" then
		for itemId, amount in pairs(data.Inventory) do
			if InventoryConfig.GetItemConfig(itemId) then
				local maxStack = InventoryConfig.GetMaxStackSize(itemId)
				local normalized = clampInt(amount, 0, maxStack, 0)
				if normalized > 0 then inventory[itemId] = normalized end
			end
		end
	end
	data.Inventory = inventory

	local crystals = type(data.Crystals) == "table" and data.Crystals or clone(defaults.Crystals)
	local owned = normalizeList(crystals.Owned, CrystalSystemExists)
	if not table.find(owned, "EMBER") and CrystalSystem.Exists("EMBER") then table.insert(owned, 1, "EMBER") end
	data.Crystals = {
		Owned = owned,
		Equipped = CrystalSystemExists(crystals.Equipped) and table.find(owned, crystals.Equipped) and crystals.Equipped or "EMBER",
	}

	local mastery = type(data.CrystalMastery) == "table" and data.CrystalMastery or {}
	local normalizedMastery = {}
	for crystalId, state in pairs(mastery) do
		if CrystalSystemExists(crystalId) and table.find(owned, crystalId) then
			local value = type(state) == "table" and state or {}
			local maxLevel = math.max(1, math.floor(finiteNumber(CrystalUpgradeConfig.MaxLevel) or 10))
			local maxExperience = math.max(0, math.floor(finiteNumber(CrystalUpgradeConfig.MaxExperience) or 100000000))
			local xp = clampInt(value.XP, 0, maxExperience, 0)
			local level = clampInt(value.Level, 1, maxLevel, 1)
			xp = capExperienceBelowNextLevel(level, xp, maxLevel, maxExperience, CrystalMastery.GetRequiredXP)
			normalizedMastery[crystalId] = { Level = level, XP = xp }
		end
	end
	if not normalizedMastery.EMBER and table.find(owned, "EMBER") then normalizedMastery.EMBER = { Level = 1, XP = 0 } end
	data.CrystalMastery = normalizedMastery

	local stats = type(data.Stats) == "table" and data.Stats or {}
	data.Stats = {
		Damage = clampInt(stats.Damage, 0, 1000, defaults.Stats.Damage),
		EnemiesDefeated = clampInt(stats.EnemiesDefeated, 0, 1000000000, defaults.Stats.EnemiesDefeated),
		BossesDefeated = clampInt(stats.BossesDefeated, 0, 1000000000, defaults.Stats.BossesDefeated),
		AncientGolemsDefeated = clampInt(stats.AncientGolemsDefeated, 0, 1000000000, defaults.Stats.AncientGolemsDefeated),
		CrystalBatsDefeated = clampInt(stats.CrystalBatsDefeated, 0, 1000000000, defaults.Stats.CrystalBatsDefeated),
	}

	local function isQuestId(value)
		return type(value) == "string" and QuestSystem.GetDefinition(value) ~= nil
	end
	local function isIslandId(value)
		return type(value) == "string" and WorldConfig.Islands[value] ~= nil
	end
	local function isBountyEnemy(value)
		if type(value) ~= "string" or type(DailyBountyConfig.Goals) ~= "table" then return false end
		for _, definition in ipairs(DailyBountyConfig.Goals) do
			if type(definition) == "table" and definition.EnemyType == value then return true end
		end
		return false
	end
	local function isAchievementId(value)
		return type(value) == "string" and AchievementSystem.Get(value) ~= nil
	end

	data.ActiveQuests = normalizeList(data.ActiveQuests, isQuestId)
	local candidateCompleted = normalizeList(data.CompletedQuests, isQuestId)
	local normalizedCompleted = {}
	local completedSet = {}
	local remaining = true
	while remaining do
		remaining = false
		for _, questId in ipairs(candidateCompleted) do
			if not completedSet[questId] then
				local definition = QuestSystem.GetDefinition(questId)
				if definition and (not definition.Requires or completedSet[definition.Requires]) then
					completedSet[questId] = true
					table.insert(normalizedCompleted, questId)
					remaining = true
				end
			end
		end
	end
	data.CompletedQuests = normalizedCompleted

	local filteredActive = {}
	for _, questId in ipairs(data.ActiveQuests) do
		local definition = QuestSystem.GetDefinition(questId)
		local minimumLevel = definition and math.max(1, math.floor(finiteNumber(definition.MinLevel) or 1)) or math.huge
		if not completedSet[questId]
			and #filteredActive == 0
			and definition
			and data.Level >= minimumLevel
			and (not definition.Requires or completedSet[definition.Requires])
		then
			table.insert(filteredActive, questId)
		end
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

	data.Achievements = normalizeList(data.Achievements, isAchievementId)
	local canonicalTitles = {}
	for _, achievementId in ipairs(data.Achievements) do
		local definition = AchievementSystem.Get(achievementId)
		if definition and definition.Title and AchievementSystem.IsValidTitle(definition.Title) and not table.find(canonicalTitles, definition.Title) then table.insert(canonicalTitles, definition.Title) end
	end
	data.Titles = canonicalTitles

	data.DailyBounty = type(data.DailyBounty) == "table" and data.DailyBounty or clone(defaults.DailyBounty)
	data.DailyBounty.Date = type(data.DailyBounty.Date) == "string" and data.DailyBounty.Date or ""
	data.DailyBounty.Claimed = data.DailyBounty.Claimed == true
	local bountyDefinition
	if isBountyEnemy(data.DailyBounty.EnemyType) then
		for _, definition in ipairs(DailyBountyConfig.Goals) do
			if definition.EnemyType == data.DailyBounty.EnemyType then bountyDefinition = definition; break end
		end
	end
	if not bountyDefinition then
		bountyDefinition = (DailyBountyConfig.Goals and DailyBountyConfig.Goals[1]) or { Goal = 1, RewardMoney = 0, EnemyType = "" }
		data.DailyBounty.Date = ""
		data.DailyBounty.EnemyType = bountyDefinition.EnemyType
		data.DailyBounty.Progress = 0
		data.DailyBounty.Claimed = false
	else
		data.DailyBounty.Progress = clampInt(data.DailyBounty.Progress, 0, clampInt(bountyDefinition.Goal, 1, 100, 1), 0)
	end
	data.DailyBounty.Goal = clampInt(bountyDefinition.Goal, 1, 100, 1)
	data.DailyBounty.Progress = math.clamp(data.DailyBounty.Progress, 0, data.DailyBounty.Goal)
	if data.DailyBounty.Claimed and data.DailyBounty.Progress < data.DailyBounty.Goal then
		data.DailyBounty.Claimed = false
	end
	data.DailyBounty.RewardMoney = clampInt(bountyDefinition.RewardMoney, 0, EconomyConfig.MaxMoney, 0)

	data.SessionId = type(data.SessionId) == "string" and data.SessionId or ""
	data.SessionLockedAt = clampInt(data.SessionLockedAt, 0, 4102444800, 0)
	if type(data.SessionLock) ~= "table" then
		data.SessionLock = nil
	else
		local jobId = type(data.SessionLock.JobId) == "string" and data.SessionLock.JobId or ""
		local token = type(data.SessionLock.Token) == "string" and data.SessionLock.Token or ""
		local sessionTimestamp = clampInt(data.SessionLock.Timestamp, 0, 4102444800, 0)
		data.SessionLock = jobId ~= "" and token ~= "" and sessionTimestamp > 0 and { JobId = jobId, Token = token, Timestamp = sessionTimestamp } or nil
	end

	data.Version = defaults.Version
	data.LegacyVersion = oldVersion
	return data
end

return PlayerData
