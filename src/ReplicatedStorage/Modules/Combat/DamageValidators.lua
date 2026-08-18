local Validators = {}

local function isFiniteNumber(value)
	return type(value) == "number" and value == value and value < math.huge and value > -math.huge
end

function Validators.IsValid(request)
	return type(request) == "table"
		and request.Attacker ~= nil
		and request.Target ~= nil
		and isFiniteNumber(request.Amount)
		and request.Amount >= 0
end

return Validators