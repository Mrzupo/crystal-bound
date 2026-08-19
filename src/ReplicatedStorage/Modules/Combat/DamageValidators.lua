local DamageTypes = require(script.Parent.DamageTypes)

local Validators = {}

local MAX_DAMAGE = 1000

local function isFiniteNumber(value)
	return type(value) == "number" and value == value and value < math.huge and value > -math.huge
end

local function isKnownDamageType(value)
	if type(value) ~= "string" then return false end
	for _, damageType in pairs(DamageTypes) do
		if value == damageType then return true end
	end
	return false
end

function Validators.IsValid(request)
	if type(request) ~= "table" or request.Target == nil then return false end
	if request.Attacker == nil and request.DamageType ~= DamageTypes.Environmental then return false end
	return isFiniteNumber(request.Amount)
		and request.Amount > 0
		and request.Amount <= MAX_DAMAGE
		and isKnownDamageType(request.DamageType)
end

return Validators
