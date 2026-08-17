local Config = require(game.ReplicatedStorage.Config.CrystalUpgradeConfig)

local CrystalMastery = {}

local function ensure(profile, crystalId)
	profile.CrystalMastery = profile.CrystalMastery or {}
	local mastery = profile.CrystalMastery[crystalId]
	if type(mastery) ~= "table" then
		mastery = { Level = 1, XP = 0 }
		profile.CrystalMastery[crystalId] = mastery
	end
	mastery.Level = math.clamp(math.floor(tonumber(mastery.Level) or 1), 1, Config.MaxLevel)
	mastery.XP = math.max(0, math.floor(tonumber(mastery.XP) or 0))
	if mastery.Level >= Config.MaxLevel then mastery.XP = 0 end
	return mastery
end

function CrystalMastery.Get(profile, crystalId)
	return ensure(profile, crystalId)
end

function CrystalMastery.GetRequiredXP(level)
	return math.floor(Config.BaseXP * (math.max(1, level) ^ Config.Growth))
end

function CrystalMastery.AddXP(profile, crystalId, amount)
	local mastery = ensure(profile, crystalId)
	if mastery.Level >= Config.MaxLevel then
		mastery.XP = 0
		return mastery.Level, mastery.XP, 0
	end
	mastery.XP = math.min(100000000, mastery.XP + math.max(0, math.floor(tonumber(amount) or 0)))
	local levels = 0
	while mastery.Level < Config.MaxLevel do
		local required = CrystalMastery.GetRequiredXP(mastery.Level)
		if mastery.XP < required then break end
		mastery.XP -= required
		mastery.Level += 1
		levels += 1
	end
	if mastery.Level >= Config.MaxLevel then mastery.XP = 0 end
	return mastery.Level, mastery.XP, levels
end

function CrystalMastery.GetBonuses(profile, crystalId)
	local mastery = ensure(profile, crystalId)
	local extra = mastery.Level - 1
	return {
		DamageMultiplier = 1 + extra * Config.DamagePerLevel,
		AbilityDamageMultiplier = 1 + extra * Config.AbilityDamagePerLevel,
		MaxHealthBonus = extra * Config.HealthPerLevel,
		WalkSpeedBonus = extra * Config.SpeedPerLevel,
	}
end

function CrystalMastery.GetUpgradeCost(profile, crystalId)
	local mastery = ensure(profile, crystalId)
	if mastery.Level >= Config.MaxLevel then return {} end
	local base = Config.BaseCosts[crystalId] or {}
	local cost = {}
	local multiplier = mastery.Level
	for itemId, amount in pairs(base) do
		cost[itemId] = amount * multiplier
	end
	return cost
end

return CrystalMastery