local PlayerData = {}

local function clone(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = clone(child) end
	return result
end

function PlayerData.new()
	return {
		Version = 6,
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

	-- Normalize legacy profiles without deleting progress.
	data.Crystals = data.Crystals or clone(defaults.Crystals)
	data.Crystals.Owned = type(data.Crystals.Owned) == "table" and data.Crystals.Owned or { "EMBER" }
	data.Crystals.Equipped = type(data.Crystals.Equipped) == "string" and data.Crystals.Equipped or "EMBER"
	data.CrystalMastery = data.CrystalMastery or clone(defaults.CrystalMastery)
	data.Stats = data.Stats or clone(defaults.Stats)
	data.Titles = type(data.Titles) == "table" and data.Titles or {}
	data.Achievements = type(data.Achievements) == "table" and data.Achievements or {}
	data.Inventory = type(data.Inventory) == "table" and data.Inventory or {}
	data.ActiveQuests = type(data.ActiveQuests) == "table" and data.ActiveQuests or {}
	data.CompletedQuests = type(data.CompletedQuests) == "table" and data.CompletedQuests or {}
	data.QuestProgress = type(data.QuestProgress) == "table" and data.QuestProgress or {}
	data.UnlockedIslands = type(data.UnlockedIslands) == "table" and data.UnlockedIslands or { "STARTER" }

	-- Version 3/4 profiles did not have mastery or achievement fields; the merge above supplies them.
	-- Keep the original level, XP, money and inventory values untouched.
	data.Version = defaults.Version
	data.LegacyVersion = oldVersion
	return data
end

return PlayerData
