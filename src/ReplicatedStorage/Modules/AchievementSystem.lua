local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CrystalUpgradeConfig = require(ReplicatedStorage.Config.CrystalUpgradeConfig)
local EconomyConfig = require(ReplicatedStorage.Config.EconomyConfig)

local AchievementSystem = {}

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return fallback end
	return number
end

local masteryMaxLevel = math.clamp(math.floor(finiteNumber(CrystalUpgradeConfig.MaxLevel, 10)), 1, 100)

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

local function copyDefinition(definition)
	if type(definition) ~= "table" then return definition end
	local result = {}
	for key, value in pairs(definition) do result[key] = value end
	return result
end

function AchievementSystem.Get(id) return copyDefinition(Definitions[id]) end
function AchievementSystem.GetAll()
	local result = {}
	for id, definition in pairs(Definitions) do result[id] = copyDefinition(definition) end
	return result
end
function AchievementSystem.GetOrder()
	local result = table.create(#ORDER)
	for index, id in ipairs(ORDER) do result[index] = id end
	return result
end
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
	return copyDefinition(definition)
end
function AchievementSystem.Check(profile)
	profile.Achievements = profile.Achievements or {}
	profile.Titles = profile.Titles or {}
	profile.Stats = profile.Stats or {}

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
	local hasMastery = function(crystalId)
		return table.find(owned, crystalId) ~= nil
			and type(mastery[crystalId]) == "table"
			and finiteNumber(mastery[crystalId].Level, 0) >= masteryMaxLevel
	end
	local ancient = (finiteNumber(profile.Stats.AncientGolemsDefeated, 0) > 0) and (finiteNumber(profile.Stats.CrystalBatsDefeated, 0) > 0)
	local checks = {
		FIRST_BLOOD = finiteNumber(profile.Stats.EnemiesDefeated, 0) >= 1,
		CRYSTAL_KEEPER = table.find(owned, "EMBER") ~= nil and table.find(owned, "TIDE") ~= nil and table.find(owned, "GALE") ~= nil,
		MASTER_OF_ONE = hasMastery("EMBER") or hasMastery("TIDE") or hasMastery("GALE"),
		GUARDIAN_SLAYER = finiteNumber(profile.Stats.BossesDefeated, 0) >= 1,
		ANCIENT_EXPLORER = ancient,
		LEVEL_20 = finiteNumber(profile.Level, 0) >= 20,
	}
	local unlocked = {}
	local projectedMoney = math.clamp(math.floor(finiteNumber(profile.Money, 0)), EconomyConfig.MinMoney, EconomyConfig.MaxMoney)
	for _, id in ipairs(ORDER) do
		if checks[id] then
			local definition = Definitions[id]
			local reward = math.clamp(math.floor(finiteNumber(definition and definition.RewardMoney, 0)), 0, EconomyConfig.MaxMoney)
			if definition and projectedMoney + reward <= EconomyConfig.MaxMoney then
				local unlockedDefinition = AchievementSystem.Unlock(profile, id)
				if unlockedDefinition then
					projectedMoney += reward
					table.insert(unlocked, unlockedDefinition)
				end
			end
		end
	end
	return unlocked
end
return AchievementSystem
