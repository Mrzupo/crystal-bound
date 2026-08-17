local DamageResult = {}

function DamageResult.new(success, amount, reason)
	return { Success = success, Amount = amount or 0, Reason = reason }
end

return DamageResult
