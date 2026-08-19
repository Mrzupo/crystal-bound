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
	local safeLevel = math.clamp(math.floor(finiteNumber(level) or 1), 1, XPConfig.MaxLevel)
	local baseXP = math.clamp(math.floor(finiteNumber(XPConfig.BaseXP) or 1), 1, XPConfig.MaxExperience)
	local growth = math.clamp(finiteNumber(XPConfig.Growth) or 1, 0.01, 4)
	local required = baseXP * (safeLevel ^ growth)
	if required ~= required or required == math.huge or required == -math.huge then
		return XPConfig.MaxExperience
	end
	return math.clamp(math.floor(required), 1, XPConfig.MaxExperience)
end

return XPConfig
