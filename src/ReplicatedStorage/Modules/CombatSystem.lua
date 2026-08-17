local CombatSystem = {}

function CombatSystem.CreateRequest(attacker, target, amount, damageType)
	return {
		Attacker = attacker,
		Target = target,
		Amount = amount,
		DamageType = damageType or "Physical",
	}
end

return CombatSystem
