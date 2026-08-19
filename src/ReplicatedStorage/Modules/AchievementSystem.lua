local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CrystalUpgradeConfig = require(ReplicatedStorage.Config.CrystalUpgradeConfig)

local AchievementSystem = {}

local masteryMaxLevel = math.max(1, math.floor(tonumber(CrystalUpgradeConfig.MaxLevel) or 10))

local Definitions = {
	FIRST_BLOOD = { Name = "First Blood", Requirement = "Defeat your first enemy.", RewardMoney = 50, Title = "Fighter" },
	CRYSTAL_KEEPER = { Name = "Crystal Keeper", Requirement = "Own Ember, Tide and Gale.", RewardMoney = 250, Title = "Crystal Keeper" },
	MASTER_OF_ONE = { Name = "Master of One", Requirement = string.format("Reach mastery level %d with one crystal.", masteryMaxLevel), RewardMoney = 750, Title = "Crystal Master" },
	GUARDIAN_SLAYER = { Name = "Guardian Slayer", Requirement = "Defeat the Crystal Guardian.", RewardMoney = 2500, Title = "Guardian Slayer" },
	ANCIENT_EXPLORER = { Name = "Ancient Explorer", Requirement = "Defeat an Ancient Golem and a Crystal Bat.", RewardMoney = 1500, Title = "Ruins Explorer" },
	LEVEL_20 = { Name = "Veteran", Requirement = "Reach level 20.", RewardMoney = 1000, Title = "Veteran" },
}

local ORDER = {
	"FIRST_BLOOD",
	"CRYSTAL_KEEPER",
	"MASTER_OF_ONE",
	"GUARDIAN_SLAYER",
	"ANCIENT_EXPLORER",
	"LEVEL_20",
}

local VALID_TITLES = {}
for _, definition in pairs(Definitions) do
	if definition.Title then VALID_TITLES[definition.Title] = true end
end

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return fallback end
	return number
end

function AchievementSystem.Get(id) return Definitions[id] end
function AchievementSystem.GetAll() return Definitions end
function AchievementSystem.GetOrder() return ORDER end
function AchievementSystem.GetOrdered()
	local result = {}
	for _, id in ipairs(ORDER) do
		local definition = Definitions[id]
		if definition then
			table.insert(result, {
				Id = id,
				Name = definition.Name,
				Requirement = definition.Requirement,
				RewardMoney = definition.RewardMoney,
				Title = definition.Title,
			})
		end
	end
	return result
end
function AchievementSystem.IsValidTitle(title) return type(title) == "string" and VALID_TITLES[title] == true end
function AchievementSystem.Has(profile, id) return table.find(profile.Achievements or {}, id) ~= nil end
function AchievementSystem.Unlock(profile, id)
	if not Definitions[id] or AchievementSystem.Has(profile, id) then return nil end
	profile.Achievements = profile.Achievements or {}; profile.Titles = profile.Titles or {}
	table.insert(profile.Achievements, id)
	local definition = Definitions[id]
	if definition.Title and not table.find(profile.Titles, definition.Title) then table.insert(profile.Titles, definition.Title) end
	return definition
end
function AchievementSystem.Check(profile)
	profile.Achievements = profile.Achievements or {}
	profile.Titles = profile.Titles or {}
	profile.Stats = profile.Stats or {}

	-- Titles are canonical consequences of earned achievements; never trust a
	-- standalone title from persisted data.
	local canonicalTitles = {}
	for _, achievementId in ipairs(profile.Achievements) do
		local definition = Definitions[achievementId]
		if definition and definition.Title and not table.find(canonicalTitles, definition.Title) then
			table.insert(canonicalTitles, definition.Title)
		end
	end
	profile.Titles = canonicalTitles

	local owned = profile.Crystals and profile.Crystals.Owned or {}
	local mastery = profile.CrystalMastery or {}
	local ancient = (finiteNumber(profile.Stats.AncientGolemsDefeated, 0) > 0) and (finiteNumber(profile.Stats.CrystalBatsDefeated, 0) > 0)
	local checks = {
		FIRST_BLOOD = finiteNumber(profile.Stats.EnemiesDefeated, 0) >= 1,
		CRYSTAL_KEEPER = table.find(owned, "EMBER") ~= nil and table.find(owned, "TIDE") ~= nil and table.find(owned, "GALE") ~= nil,
		MASTER_OF_ONE = (mastery.EMBER and finiteNumber(mastery.EMBER.Level, 0) >= masteryMaxLevel) or (mastery.TIDE and finiteNumber(mastery.TIDE.Level, 0) >= masteryMaxLevel) or (mastery.GALE and finiteNumber(mastery.GALE.Level, 0) >= masteryMaxLevel),
		GUARDIAN_SLAYER = finiteNumber(profile.Stats.BossesDefeated, 0) >= 1,
		ANCIENT_EXPLORER = ancient,
		LEVEL_20 = finiteNumber(profile.Level, 0) >= 20,
	}
	local unlocked = {}
	for _, id in ipairs(ORDER) do
		if checks[id] then
			local definition = AchievementSystem.Unlock(profile, id)
			if definition then table.insert(unlocked, definition) end
		end
	end
	return unlocked
end
return AchievementSystem