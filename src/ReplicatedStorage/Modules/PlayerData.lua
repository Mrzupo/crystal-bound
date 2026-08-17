local PlayerData = {}

local VALID_CRYSTALS = {
	EMBER = true,
	TIDE = true,
	GALE = true,
}

local function clone(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = clone(child) end
	return result
end

local function clampInt(value, minimum, maximum, fallback)
	local number = tonumber(value)
	if not number then return fallback end
	number = math.floor(number)
	return math.clamp(number, minimum, maximum)
end

local function normalizeList(list, validator)
	local result = {}
	local seen = {}
	if type(list) ~= "table" then return result end
	for _, value in ipairs(list) do
		if type(value) == "string" and (not validator or validator(value)) and not seen[value] then
			seen[value] = true
			table.insert(result, value)
		end
	end
	return result
end

function PlayerData.new()
	return {
		Version = 8,
		Level = 1,
		Experience = 0,
		Crystals = { Owned = { "EMBER" }, Equipped = "EMBER" },
		CrystalMastery = { EMBER = { Level = 1, XP = 0 }, TIDE = { Level = 1, XP = 0 }, GALE = { Level = 1, XP = 0 } },
		Money = 100,
		Stats = { Damage = 10, Health = 100, EnemiesDefeated = 0, BossesDefeated = 0, AncientGolemsDefeated = 0, CrystalBatsDefeated = 0 },
		Inventory = {},
		ActiveQuests = {}, CompletedQuests = {}, QuestProgress = {},
		UnlockedIslands = { "STARTER" },
		Titles = {}, Achievements = {},
		SessionId = "",
		SessionLockedAt = 0,
	}
end

function PlayerData.Reconcile(data)
	local defaults = PlayerData.new()
	data = type(data) == "table" and data or {}
	local oldVersion = tonumber(data.Version) or 0

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

	data.Level = clampInt(data.Level, 1, 1000, defaults.Level)
	data.Experience = clampInt(data.Experience, 0, 1000000000, defaults.Experience)
	data.Money = clampInt(data.Money, 0, 1000000, defaults.Money)

	data.Crystals = type(data.Crystals) == "table" and data.Crystals or clone(defaults.Crystals)
	data.Crystals.Owned = normalizeList(data.Crystals.Owned, function(id) return VALID_CRYSTALS[id] end)
	if not table.find(data.Crystals.Owned, "EMBER") then table.insert(data.Crystals.Owned, "EMBER") end
	if not VALID_CRYSTALS[data.Crystals.Equipped] or not table.find(data.Crystals.Owned, data.Crystals.Equipped) then
		data.Crystals.Equipped = "EMBER"
	end

	data.CrystalMastery = type(data.CrystalMastery) == "table" and data.CrystalMastery or clone(defaults.CrystalMastery)
	for crystalId in pairs(VALID_CRYSTALS) do
		local mastery = type(data.CrystalMastery[crystalId]) == "table" and data.CrystalMastery[crystalId] or {}
		mastery.Level = clampInt(mastery.Level, 1, 10, 1)
		mastery.XP = clampInt(mastery.XP, 0, 100000000, 0)
		data.CrystalMastery[crystalId] = mastery
	end

	data.Stats = type(data.Stats) == "table" and data.Stats or clone(defaults.Stats)
	data.Stats.Damage = clampInt(data.Stats.Damage, 0, 100000, defaults.Stats.Damage)
	data.Stats.Health = clampInt(data.Stats.Health, 1, 1000000, defaults.Stats.Health)
	data.Stats.EnemiesDefeated = clampInt(data.Stats.EnemiesDefeated, 0, 100000000, 0)
	data.Stats.BossesDefeated = clampInt(data.Stats.BossesDefeated, 0, 100000000, 0)
	data.Stats.AncientGolemsDefeated = clampInt(data.Stats.AncientGolemsDefeated, 0, 100000000, 0)
	data.Stats.CrystalBatsDefeated = clampInt(data.Stats.CrystalBatsDefeated, 0, 100000000, 0)

	data.Titles = normalizeList(data.Titles)
	data.Achievements = normalizeList(data.Achievements)
	data.Inventory = type(data.Inventory) == "table" and data.Inventory or {}
	data.ActiveQuests = normalizeList(data.ActiveQuests)
	data.CompletedQuests = normalizeList(data.CompletedQuests)
	data.QuestProgress = type(data.QuestProgress) == "table" and data.QuestProgress or {}
	data.UnlockedIslands = normalizeList(data.UnlockedIslands)
	if not table.find(data.UnlockedIslands, "STARTER") then table.insert(data.UnlockedIslands, "STARTER") end
	data.SessionId = type(data.SessionId) == "string" and data.SessionId or ""
	data.SessionLockedAt = clampInt(data.SessionLockedAt, 0, 2147483647, 0)

	data.Version = defaults.Version
	data.LegacyVersion = oldVersion
	return data
end

return PlayerData
