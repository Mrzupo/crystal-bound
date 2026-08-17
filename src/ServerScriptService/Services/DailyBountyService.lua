local DailyBountyService = {}

local GOALS = {
	{ EnemyType = "Emberling", Goal = 8, RewardMoney = 120 },
	{ EnemyType = "Tidecrawler", Goal = 6, RewardMoney = 180 },
	{ EnemyType = "Galewisp", Goal = 5, RewardMoney = 250 },
	{ EnemyType = "CrystalBat", Goal = 4, RewardMoney = 320 },
	{ EnemyType = "AncientGolem", Goal = 2, RewardMoney = 450 },
}

local function utcDate()
	return os.date("!%Y-%m-%d")
end

local function indexForDate(date)
	local total = 0
	for index = 1, #date do total += string.byte(date, index) end
	return (total % #GOALS) + 1
end

function DailyBountyService.Refresh(profile)
	profile.DailyBounty = type(profile.DailyBounty) == "table" and profile.DailyBounty or {}
	local date = utcDate()
	if profile.DailyBounty.Date ~= date then
		local definition = GOALS[indexForDate(date)]
		profile.DailyBounty = {
			Date = date,
			EnemyType = definition.EnemyType,
			Goal = definition.Goal,
			Progress = 0,
			RewardMoney = definition.RewardMoney,
			Claimed = false,
		}
	end
	profile.DailyBounty.Progress = math.max(0, math.min(profile.DailyBounty.Goal or 1, math.floor(tonumber(profile.DailyBounty.Progress) or 0)))
	profile.DailyBounty.Claimed = profile.DailyBounty.Claimed == true
	return profile.DailyBounty
end

function DailyBountyService.AddProgress(player, profile, enemyType, EconomyService, PlayerService)
	local bounty = DailyBountyService.Refresh(profile)
	if bounty.Claimed or bounty.EnemyType ~= enemyType then return false end
	bounty.Progress = math.min(bounty.Goal, bounty.Progress + 1)
	if bounty.Progress >= bounty.Goal then
		bounty.Claimed = true
		EconomyService.AddMoney(profile, bounty.RewardMoney)
		player:SetAttribute("BountyMessage", string.format("Daily Bounty complete! +%d Money", bounty.RewardMoney))
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
