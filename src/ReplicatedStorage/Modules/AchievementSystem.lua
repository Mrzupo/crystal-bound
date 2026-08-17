local AchievementSystem = {}

local Definitions = {
	FIRST_BLOOD = { Name = "First Blood", Requirement = "Defeat your first enemy.", RewardMoney = 50, Title = "Fighter" },
	CRYSTAL_KEEPER = { Name = "Crystal Keeper", Requirement = "Own Ember, Tide and Gale.", RewardMoney = 250, Title = "Crystal Keeper" },
	MASTER_OF_ONE = { Name = "Master of One", Requirement = "Reach mastery level 10 with one crystal.", RewardMoney = 750, Title = "Crystal Master" },
	GUARDIAN_SLAYER = { Name = "Guardian Slayer", Requirement = "Defeat the Crystal Guardian.", RewardMoney = 2500, Title = "Guardian Slayer" },
	ANCIENT_EXPLORER = { Name = "Ancient Explorer", Requirement = "Defeat an Ancient Golem and a Crystal Bat.", RewardMoney = 1500, Title = "Ruins Explorer" },
	LEVEL_20 = { Name = "Veteran", Requirement = "Reach level 20.", RewardMoney = 1000, Title = "Veteran" },
}

function AchievementSystem.Get(id) return Definitions[id] end
function AchievementSystem.GetAll() return Definitions end
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
	profile.Achievements = profile.Achievements or {}; profile.Titles = profile.Titles or {}; profile.Stats = profile.Stats or {}
	local owned = profile.Crystals and profile.Crystals.Owned or {}
	local mastery = profile.CrystalMastery or {}
	local ancient = (profile.Stats.AncientGolemsDefeated or 0) > 0 and (profile.Stats.CrystalBatsDefeated or 0) > 0
	local checks = {
		FIRST_BLOOD = (profile.Stats.EnemiesDefeated or 0) >= 1,
		CRYSTAL_KEEPER = table.find(owned, "EMBER") and table.find(owned, "TIDE") and table.find(owned, "GALE"),
		MASTER_OF_ONE = (mastery.EMBER and mastery.EMBER.Level >= 10) or (mastery.TIDE and mastery.TIDE.Level >= 10) or (mastery.GALE and mastery.GALE.Level >= 10),
		GUARDIAN_SLAYER = (profile.Stats.BossesDefeated or 0) >= 1,
		ANCIENT_EXPLORER = ancient,
		LEVEL_20 = profile.Level >= 20,
	}
	local unlocked = {}
	for id, condition in pairs(checks) do if condition then local definition = AchievementSystem.Unlock(profile, id); if definition then table.insert(unlocked, definition) end end end
	return unlocked
end
return AchievementSystem
