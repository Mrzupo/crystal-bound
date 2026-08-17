local DamageRequest = {}

function DamageRequest.new(attacker, target, amount, damageType)
	return { Attacker = attacker, Target = target, Amount = amount, DamageType = damageType }
end

return DamageRequest
