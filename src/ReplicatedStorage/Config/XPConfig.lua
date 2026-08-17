local XPConfig = {
	MaxLevel = 100,
	BaseXP = 100,
	Growth = 1.25,
}

function XPConfig.GetRequiredXP(level)
	level = math.max(1, level)
	return math.floor(XPConfig.BaseXP * (level ^ XPConfig.Growth))
end

return XPConfig