local CombatModifierService = {}
local rng = Random.new()

local function finiteLevel(value)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then
		return 1
	end
	return math.max(1, math.floor(number))
end

function CombatModifierService.RollCritical(profile, crystalId)
	local mastery = profile.CrystalMastery and profile.CrystalMastery[crystalId]
	local masteryLevel = finiteLevel(mastery and mastery.Level)
	local chance = math.clamp(0.08 + (masteryLevel - 1) * 0.01, 0.08, 0.22)
	if rng:NextNumber() <= chance then
		return true, 1.65
	end
	return false, 1
end

return CombatModifierService
