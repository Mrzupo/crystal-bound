local ReplicatedStorage = game:GetService("ReplicatedStorage")
local XPConfig = require(ReplicatedStorage.Config.XPConfig)

local XPService = {}

function XPService.AddXP(profile, amount)
	amount = math.max(0, tonumber(amount) or 0)
	local levelsGained = 0
	profile.Experience += amount

	while profile.Level < XPConfig.MaxLevel do
		local required = XPConfig.GetRequiredXP(profile.Level)
		if profile.Experience < required then
			break
		end
		profile.Experience -= required
		profile.Level += 1
		levelsGained += 1
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