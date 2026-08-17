local CombatModifierService = {}
local rng = Random.new()

function CombatModifierService.RollCritical(profile, crystalId)
	local mastery = profile.CrystalMastery and profile.CrystalMastery[crystalId]
	local masteryLevel = mastery and math.max(1, tonumber(mastery.Level) or 1) or 1
	local chance = math.clamp(0.08 + (masteryLevel - 1) * 0.01, 0.08, 0.22)
	if rng:NextNumber() <= chance then
		return true, 1.65
	end
	return false, 1
end

return CombatModifierService
