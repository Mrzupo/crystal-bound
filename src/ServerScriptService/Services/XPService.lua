local ReplicatedStorage = game:GetService("ReplicatedStorage")
local XPConfig = require(ReplicatedStorage.Config.XPConfig)

local XPService = {}

local function finiteNumber(value)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return nil end
	return number
end

local function normalizedLevel(profile)
	return math.clamp(math.floor(finiteNumber(profile.Level) or 1), 1, XPConfig.MaxLevel)
end

local function normalizedXP(profile)
	return math.clamp(math.floor(finiteNumber(profile.Experience) or 0), 0, XPConfig.MaxExperience)
end

local function positiveInteger(value)
	local number = finiteNumber(value)
	if number == nil or number < 0 or number % 1 ~= 0 then return nil end
	return number
end

function XPService.AddXP(profile, amount)
	local level = normalizedLevel(profile)
	local experience = normalizedXP(profile)
	amount = positiveInteger(amount)
	if amount == nil then return level, experience, 0 end
	local levelsGained = 0
	if level >= XPConfig.MaxLevel then
		profile.Level = XPConfig.MaxLevel
		profile.Experience = 0
		return profile.Level, profile.Experience, levelsGained
	end

	profile.Level = level
	profile.Experience = math.min(XPConfig.MaxExperience, experience + amount)

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
		profile.Level = XPConfig.MaxLevel
		profile.Experience = 0
	end
	return profile.Level, profile.Experience, levelsGained
end

function XPService.GetLevel(profile)
	return normalizedLevel(profile)
end

function XPService.GetXP(profile)
	local level = normalizedLevel(profile)
	if level >= XPConfig.MaxLevel then return 0 end
	return normalizedXP(profile)
end

function XPService.GetRequiredXP(profile)
	local level = normalizedLevel(profile)
	if level >= XPConfig.MaxLevel then return 0 end
	return XPConfig.GetRequiredXP(level)
end

return XPService
