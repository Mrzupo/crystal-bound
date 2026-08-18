local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DamageTypes = require(script.Parent.DamageTypes)

local Validators = {}

local function isFiniteNumber(value)
	return type(value) == "number" and value == value and value < math.huge and value > -math.huge
end

local function isKnownDamageType(value)
	if value == nil then return true end
	for _, damageType in pairs(DamageTypes) do
		if value == damageType then return true end
	end
	return false
end

function Validators.IsValid(request)
	return type(request) == "table"
		and request.Attacker ~= nil
		and request.Target ~= nil
		and isFiniteNumber(request.Amount)
		and request.Amount >= 0
		and isKnownDamageType(request.DamageType)
end

return Validators
