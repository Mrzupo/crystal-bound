local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatModifierConfig = require(ReplicatedStorage.Config.CombatModifierConfig)
local rng = Random.new()

local CombatModifierService = {}

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then
		return fallback
	end
	return number
end

local function finiteLevel(value)
	return math.max(1, math.floor(finiteNumber(value, 1)))
end

function CombatModifierService.RollCritical(profile, crystalId)
	local mastery = profile.CrystalMastery and profile.CrystalMastery[crystalId]
	local masteryLevel = finiteLevel(mastery and mastery.Level)
	local config = CombatModifierConfig.Critical or {}
	local baseChance = math.clamp(finiteNumber(config.BaseChance, 0.08), 0, 1)
	local chancePerLevel = math.clamp(finiteNumber(config.ChancePerMasteryLevel, 0.01), 0, 1)
	local maxChance = math.clamp(finiteNumber(config.MaxChance, 0.22), baseChance, 1)
	local multiplier = math.clamp(finiteNumber(config.Multiplier, 1.65), 1, 10)
	local chance = math.clamp(baseChance + (masteryLevel - 1) * chancePerLevel, 0, maxChance)
	if rng:NextNumber() < chance then
		return true, multiplier
	end
	return false, 1
end

return CombatModifierService
