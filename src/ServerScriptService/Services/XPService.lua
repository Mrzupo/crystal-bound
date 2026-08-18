local ReplicatedStorage = game:GetService("ReplicatedStorage")
local XPConfig = require(ReplicatedStorage.Config.XPConfig)

local XPService = {}

local function finiteNumber(value)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return nil end
	return number
end

function XPService.AddXP(profile, amount)
	amount = math.max(0, finiteNumber(amount) or 0)
	local levelsGained = 0
	if profile.Level >= XPConfig.MaxLevel then
		profile.Experience = 0
		return profile.Level, profile.Experience, levelsGained
	end

	profile.Experience = math.min(1000000000, profile.Experience + amount)

	while profile.Level < XPConfig.MaxLevel do
		local required = XPConfig.GetRequiredXP(profile.Level)
		if profile.Experience < required then
			break
		end
		profile.Experience -= required
		profile.Level += 1
		levelsGained += 1
	end

	if profile.Level >= XPConfig.MaxLevel then
		profile.Experience = 0
	end
	return profile.Level, profile.Experience, levelsGained
end

function XPService.GetLevel(profile)
	return profile.Level
end

function XPService.GetXP(profile)
	return profile.Experience
end

function XPService.GetRequiredXP(profile)
	return XPConfig.GetRequiredXP(profile.Level)
end

return XPService