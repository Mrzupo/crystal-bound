local Utility = {}
function Utility.Clamp(value, minValue, maxValue) return math.max(minValue, math.min(maxValue, value)) end
function Utility.DeepCopy(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for key, item in pairs(value) do copy[Utility.DeepCopy(key)] = Utility.DeepCopy(item) end
	return copy
end
return Utility
