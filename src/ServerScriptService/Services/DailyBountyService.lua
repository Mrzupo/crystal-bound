local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BountyConfig = require(ReplicatedStorage.Config.DailyBountyConfig)
local EconomyConfig = require(ReplicatedStorage.Config.EconomyConfig)

local DailyBountyService = {}
local GOALS = BountyConfig.Goals

local function utcDate()
	return os.date("!%Y-%m-%d")
end

local function indexForDate(date)
	local total = 0
	for index = 1, #date do total += string.byte(date, index) end
	if #GOALS == 0 then return nil end
	return (total % #GOALS) + 1
end

function DailyBountyService.Refresh(profile)
	profile.DailyBounty = type(profile.DailyBounty) == "table" and profile.DailyBounty or {}
	local date = utcDate()
	if profile.DailyBounty.Date ~= date then
		local index = indexForDate(date)
		local definition = index and GOALS[index]
		if not definition then return profile.DailyBounty end
		profile.DailyBounty = {
			Date = date,
			EnemyType = definition.EnemyType,
			Goal = definition.Goal,
			Progress = 0,
			RewardMoney = definition.RewardMoney,
			Claimed = false,
		}
	end
	profile.DailyBounty.Goal = math.clamp(math.floor(tonumber(profile.DailyBounty.Goal) or 1), 1, 100)
	profile.DailyBounty.Progress = math.clamp(math.floor(tonumber(profile.DailyBounty.Progress) or 0), 0, profile.DailyBounty.Goal)
	profile.DailyBounty.RewardMoney = math.clamp(math.floor(tonumber(profile.DailyBounty.RewardMoney) or 0), 0, EconomyConfig.MaxMoney)
	profile.DailyBounty.Claimed = profile.DailyBounty.Claimed == true
	return profile.DailyBounty
end

function DailyBountyService.AddProgress(player, profile, enemyType, EconomyService, PlayerService)
	local bounty = DailyBountyService.Refresh(profile)
	if bounty.Claimed or bounty.EnemyType ~= enemyType then return false end
	bounty.Progress = math.min(bounty.Goal, bounty.Progress + 1)
	if bounty.Progress >= bounty.Goal then
		bounty.Claimed = true
		local _, earned = EconomyService.AddMoney(profile, bounty.RewardMoney)
		player:SetAttribute("BountyMessage", string.format("Daily Bounty complete! +%d Money", earned or 0))
		PlayerService.Sync(player)
		return true
	end
	player:SetAttribute("BountyMessage", string.format("Daily Bounty: %s %d/%d", bounty.EnemyType, bounty.Progress, bounty.Goal))
	return false
end

function DailyBountyService.Get(profile)
	return DailyBountyService.Refresh(profile)
end

return DailyBountyService
