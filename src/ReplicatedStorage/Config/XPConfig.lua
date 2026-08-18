local XPConfig = {
	MaxLevel = 100,
	MaxExperience = 1000000000,
	BaseXP = 100,
	Growth = 1.25,
}

local function finiteNumber(value)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return nil end
	return number
end

function XPConfig.GetRequiredXP(level)
	local safeLevel = math.max(1, math.floor(finiteNumber(level) or 1))
	local baseXP = math.max(1, math.floor(finiteNumber(XPConfig.BaseXP) or 1))
	local growth = math.max(0.01, finiteNumber(XPConfig.Growth) or 1)
	return math.max(1, math.floor(baseXP * (safeLevel ^ growth)))
end

return XPConfig
