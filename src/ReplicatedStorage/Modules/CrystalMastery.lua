local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config.CrystalUpgradeConfig)
local CrystalConfig = require(ReplicatedStorage.Config.CrystalConfig)

local CrystalMastery = {}

local function finiteNumber(value)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return nil end
	return number
end

local function validCrystalId(crystalId)
	if type(crystalId) ~= "string" then return false end
	local required = finiteNumber(CrystalConfig.UnlockLevels[crystalId])
	if required == nil or required < 1 or required % 1 ~= 0 then return false end
	return type(CrystalConfig.Definitions) == "table"
		and type(CrystalConfig.Definitions[crystalId]) == "table"
		and type(CrystalConfig.BasicAttack) == "table"
		and type(CrystalConfig.BasicAttack[crystalId]) == "table"
		and type(CrystalConfig.Abilities) == "table"
		and type(CrystalConfig.Abilities[crystalId]) == "table"
		and type(CrystalConfig.Passives) == "table"
		and type(CrystalConfig.Passives[crystalId]) == "table"
end

local function neutralMastery()
	return { Level = 1, XP = 0 }
end

local function boundedPositiveConfig(value, fallback, maximum)
	local number = finiteNumber(value)
	if number == nil or number < 0 then return fallback end
	return math.clamp(number, 0, maximum)
end

local function ensure(profile, crystalId)
	if type(profile) ~= "table" or not validCrystalId(crystalId) then return nil end
	profile.CrystalMastery = type(profile.CrystalMastery) == "table" and profile.CrystalMastery or {}
	local mastery = profile.CrystalMastery[crystalId]
	if type(mastery) ~= "table" then
		mastery = neutralMastery()
		profile.CrystalMastery[crystalId] = mastery
	end
	local maxLevel = math.max(1, math.floor(finiteNumber(Config.MaxLevel) or 10))
	local maxExperience = math.max(0, math.floor(finiteNumber(Config.MaxExperience) or 100000000))
	mastery.Level = math.clamp(math.floor(finiteNumber(mastery.Level) or 1), 1, maxLevel)
	mastery.XP = math.clamp(math.floor(finiteNumber(mastery.XP) or 0), 0, maxExperience)
	if mastery.Level >= maxLevel then mastery.XP = 0 end
	return mastery
end

function CrystalMastery.Get(profile, crystalId)
	local mastery = ensure(profile, crystalId)
	return mastery and { Level = mastery.Level, XP = mastery.XP } or neutralMastery()
end

function CrystalMastery.GetRequiredXP(level)
	local maxLevel = math.max(1, math.floor(finiteNumber(Config.MaxLevel) or 10))
	local safeLevel = math.clamp(math.floor(finiteNumber(level) or 1), 1, maxLevel)
	local growth = math.clamp(finiteNumber(Config.Growth) or 1.35, 0.01, 10)
	local baseXP = math.max(1, finiteNumber(Config.BaseXP) or 1)
	local maxExperience = math.max(1, math.floor(finiteNumber(Config.MaxExperience) or 100000000))
	local required = baseXP * (safeLevel ^ growth)
	if required ~= required or required == math.huge or required == -math.huge then return maxExperience end
	return math.clamp(math.floor(required), 1, maxExperience)
end

function CrystalMastery.AddXP(profile, crystalId, amount)
	if not validCrystalId(crystalId) then return 1, 0, 0 end
	local mastery = ensure(profile, crystalId)
	if not mastery then return 1, 0, 0 end
	local maxLevel = math.max(1, math.floor(finiteNumber(Config.MaxLevel) or 10))
	if mastery.Level >= maxLevel then
		mastery.XP = 0
		return mastery.Level, mastery.XP, 0
	end
	local safeAmount = finiteNumber(amount)
	if safeAmount == nil or safeAmount < 0 or safeAmount % 1 ~= 0 then
		return mastery.Level, mastery.XP, 0
	end
	local maxExperience = math.max(0, math.floor(finiteNumber(Config.MaxExperience) or 100000000))
	mastery.XP = math.min(maxExperience, mastery.XP + safeAmount)
	local levels = 0
	while mastery.Level < maxLevel do
		local required = CrystalMastery.GetRequiredXP(mastery.Level)
		if mastery.XP < required then break end
		mastery.XP -= required
		mastery.Level += 1
		levels += 1
	end
	if mastery.Level >= maxLevel then mastery.XP = 0 end
	return mastery.Level, mastery.XP, levels
end

function CrystalMastery.GetBonuses(profile, crystalId)
	if not validCrystalId(crystalId) then
		return {
			DamageMultiplier = 1,
			AbilityDamageMultiplier = 1,
			MaxHealthBonus = 0,
			WalkSpeedBonus = 0,
		}
	end
	local mastery = ensure(profile, crystalId)
	if not mastery then
		return {
			DamageMultiplier = 1,
			AbilityDamageMultiplier = 1,
			MaxHealthBonus = 0,
			WalkSpeedBonus = 0,
		}
	end
	local extra = mastery.Level - 1
	local damagePerLevel = boundedPositiveConfig(Config.DamagePerLevel, 0, 1)
	local abilityDamagePerLevel = boundedPositiveConfig(Config.AbilityDamagePerLevel, 0, 1)
	local healthPerLevel = boundedPositiveConfig(Config.HealthPerLevel, 0, 100)
	local speedPerLevel = boundedPositiveConfig(Config.SpeedPerLevel, 0, 10)
	return {
		DamageMultiplier = math.clamp(1 + extra * damagePerLevel, 0.1, 10),
		AbilityDamageMultiplier = math.clamp(1 + extra * abilityDamagePerLevel, 0.1, 10),
		MaxHealthBonus = math.clamp(extra * healthPerLevel, 0, 1000),
		WalkSpeedBonus = math.clamp(extra * speedPerLevel, 0, 100),
	}
end

function CrystalMastery.GetUpgradeCost(profile, crystalId)
	if not validCrystalId(crystalId) then return nil end
	local mastery = ensure(profile, crystalId)
	if not mastery then return nil end
	local maxLevel = math.max(1, math.floor(finiteNumber(Config.MaxLevel) or 10))
	if mastery.Level >= maxLevel then return {} end
	local base = type(Config.BaseCosts) == "table" and Config.BaseCosts[crystalId] or nil
	if type(base) ~= "table" or next(base) == nil then return nil end
	local cost = {}
	local multiplier = math.max(1, mastery.Level)
	for itemId, amount in pairs(base) do
		local safeAmount = finiteNumber(amount)
		if type(itemId) ~= "string" or not safeAmount or safeAmount <= 0 or safeAmount % 1 ~= 0 then return nil end
		local total = math.floor(safeAmount) * multiplier
		if total > 1000000000 then return nil end
		cost[itemId] = total
	end
	return next(cost) and cost or nil
end

function CrystalMastery.Upgrade(profile, crystalId)
	if not validCrystalId(crystalId) then return false, 0 end
	local mastery = ensure(profile, crystalId)
	if not mastery then return false, 0 end
	local maxLevel = math.max(1, math.floor(finiteNumber(Config.MaxLevel) or 10))
	if mastery.Level >= maxLevel then return false, mastery.Level end
	mastery.Level += 1
	mastery.XP = 0
	return true, mastery.Level
end

return CrystalMastery
