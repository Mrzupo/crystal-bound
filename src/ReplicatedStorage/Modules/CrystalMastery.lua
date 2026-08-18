local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config.CrystalUpgradeConfig)
local CrystalConfig = require(ReplicatedStorage.Config.CrystalConfig)

local CrystalMastery = {}
local DEFAULT_CRYSTAL = "EMBER"

local function finiteNumber(value)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return nil end
	return number
end

local function normalizeCrystalId(crystalId)
	return type(crystalId) == "string" and CrystalConfig.UnlockLevels[crystalId] and crystalId or DEFAULT_CRYSTAL
end

local function ensure(profile, crystalId)
	if type(profile) ~= "table" then return { Level = 1, XP = 0 } end
	profile.CrystalMastery = type(profile.CrystalMastery) == "table" and profile.CrystalMastery or {}
	crystalId = normalizeCrystalId(crystalId)
	local mastery = profile.CrystalMastery[crystalId]
	if type(mastery) ~= "table" then
		mastery = { Level = 1, XP = 0 }
		profile.CrystalMastery[crystalId] = mastery
	end
	mastery.Level = math.clamp(math.floor(finiteNumber(mastery.Level) or 1), 1, Config.MaxLevel)
	mastery.XP = math.clamp(math.floor(finiteNumber(mastery.XP) or 0), 0, math.max(0, math.floor(finiteNumber(Config.MaxExperience) or 100000000)))
	if mastery.Level >= Config.MaxLevel then mastery.XP = 0 end
	return mastery
end

function CrystalMastery.Get(profile, crystalId)
	return ensure(profile, crystalId)
end

function CrystalMastery.GetRequiredXP(level)
	local safeLevel = math.max(1, math.floor(finiteNumber(level) or 1))
	local growth = math.max(0, finiteNumber(Config.Growth) or 0)
	local baseXP = math.max(1, finiteNumber(Config.BaseXP) or 1)
	return math.max(1, math.floor(baseXP * (safeLevel ^ growth)))
end

function CrystalMastery.AddXP(profile, crystalId, amount)
	local mastery = ensure(profile, crystalId)
	if mastery.Level >= Config.MaxLevel then
		mastery.XP = 0
		return mastery.Level, mastery.XP, 0
	end
	local maxExperience = math.max(0, math.floor(finiteNumber(Config.MaxExperience) or 100000000))
	mastery.XP = math.min(maxExperience, mastery.XP + math.max(0, math.floor(finiteNumber(amount) or 0)))
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
		DamageMultiplier = 1 + extra * (finiteNumber(Config.DamagePerLevel) or 0),
		AbilityDamageMultiplier = 1 + extra * (finiteNumber(Config.AbilityDamagePerLevel) or 0),
		MaxHealthBonus = extra * (finiteNumber(Config.HealthPerLevel) or 0),
		WalkSpeedBonus = extra * (finiteNumber(Config.SpeedPerLevel) or 0),
	}
end

function CrystalMastery.GetUpgradeCost(profile, crystalId)
	crystalId = normalizeCrystalId(crystalId)
	local mastery = ensure(profile, crystalId)
	if mastery.Level >= Config.MaxLevel then return {} end
	local base = type(Config.BaseCosts) == "table" and Config.BaseCosts[crystalId] or nil
	if type(base) ~= "table" or next(base) == nil then return nil end
	local cost = {}
	local multiplier = math.max(1, mastery.Level)
	for itemId, amount in pairs(base) do
		local safeAmount = math.max(1, math.floor(finiteNumber(amount) or 1))
		cost[itemId] = safeAmount * multiplier
	end
	return cost
end

function CrystalMastery.Upgrade(profile, crystalId)
	crystalId = normalizeCrystalId(crystalId)
	local mastery = ensure(profile, crystalId)
	if mastery.Level >= Config.MaxLevel then
		return false, mastery.Level
	end
	mastery.Level += 1
	mastery.XP = 0
	return true, mastery.Level
end

return CrystalMastery
