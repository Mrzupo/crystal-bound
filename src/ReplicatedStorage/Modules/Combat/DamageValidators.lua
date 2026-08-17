local Validators = {}

function Validators.IsValid(request)
	return type(request) == "table"
		and request.Attacker ~= nil
		and request.Target ~= nil
		and type(request.Amount) == "number"
		and request.Amount >= 0
end

return Validators
