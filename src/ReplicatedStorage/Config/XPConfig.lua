local XPConfig = {}
function XPConfig.GetRequiredXP(level) return math.max(100, level * 100) end
return XPConfig
