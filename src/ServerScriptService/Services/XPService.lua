local XPConfig = require(game.ReplicatedStorage.Config.XPConfig)
local XPService = {}

function XPService.AddXP(profile, amount)
	profile.Experience += math.max(0, amount)
	while profile.Level < 100 and profile.Experience >= XPConfig.GetRequiredXP(profile.Level) do
		profile.Experience -= XPConfig.GetRequiredXP(profile.Level)
		profile.Level += 1
	end
	return profile.Level, profile.Experience
end
function XPService.GetLevel(profile) return profile.Level end
function XPService.GetXP(profile) return profile.Experience end
return XPService
