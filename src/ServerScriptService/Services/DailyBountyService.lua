local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BountyConfig = require(ReplicatedStorage.Config.DailyBountyConfig)
local EconomyConfig = require(ReplicatedStorage.Config.EconomyConfig)

local DailyBountyService = {}
local GOALS = BountyConfig.Goals

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then
		return fallback
	end
	return number
end

local function utcDate()
	return os.date("!%Y-%m-%d")
end

local function indexForDate(date)
	local total = 0
	for index = 1, #date do total += string.byte(date, index) end
	if #GOALS == 0 then return nil end
	return (total % #GOALS) + 1
end

local function findDefinition(enemyType)
	if type(enemyType) ~= "string" then return nil end
	for _, definition in ipairs(GOALS) do
		if type(definition) == "table" and definition.EnemyType == enemyType then
			return definition
		end
	end
	return nil
end

local function snapshot(bounty)
	if type(bounty) ~= "table" then return {} end
	return {
		Date = bounty.Date,
		EnemyType = bounty.EnemyType,
		Goal = bounty.Goal,
		Progress = bounty.Progress,
		RewardMoney = bounty.RewardMoney,
		Claimed = bounty.Claimed == true,
	}
end

function DailyBountyService.Refresh(profile)
	profile.DailyBounty = type(profile.DailyBounty) == "table" and profile.DailyBounty or {}
	local date = utcDate()
	local definition

	if profile.DailyBounty.Date ~= date then
		local index = indexForDate(date)
		definition = index and GOALS[index]
		if not definition then return profile.DailyBounty end
		profile.DailyBounty = {
			Date = date,
			EnemyType = definition.EnemyType,
			Goal = definition.Goal,
			Progress = 0,
			RewardMoney = definition.RewardMoney,
			Claimed = false,
		}
	else
		definition = findDefinition(profile.DailyBounty.EnemyType)
		if not definition then
			local index = indexForDate(date)
			definition = index and GOALS[index]
			if not definition then return profile.DailyBounty end
			profile.DailyBounty.EnemyType = definition.EnemyType
			profile.DailyBounty.Progress = 0
			profile.DailyBounty.Claimed = false
		end
	end

	profile.DailyBounty.Goal = math.clamp(math.floor(finiteNumber(definition.Goal, 1)), 1, 100)
	profile.DailyBounty.Progress = math.clamp(math.floor(finiteNumber(profile.DailyBounty.Progress, 0)), 0, profile.DailyBounty.Goal)
	profile.DailyBounty.RewardMoney = math.clamp(math.floor(finiteNumber(definition.RewardMoney, 0)), 0, EconomyConfig.MaxMoney)
	profile.DailyBounty.Claimed = profile.DailyBounty.Claimed == true
	return profile.DailyBounty
end

function DailyBountyService.AddProgress(player, profile, enemyType, EconomyService, PlayerService)
	local bounty = DailyBountyService.Refresh(profile)
	if bounty.Claimed or bounty.EnemyType ~= enemyType then return false end
	bounty.Progress = math.min(bounty.Goal, bounty.Progress + 1)
	if bounty.Progress >= bounty.Goal then
		local currentMoney = math.clamp(finiteNumber(profile.Money, 0), EconomyConfig.MinMoney, EconomyConfig.MaxMoney)
		if currentMoney + bounty.RewardMoney > EconomyConfig.MaxMoney then
			bounty.Progress = math.max(0, bounty.Goal - 1)
			bounty.Claimed = false
			player:SetAttribute("BountyMessage", "Spend some Money before claiming the Daily Bounty.")
			PlayerService.Sync(player)
			return false
		end

		local _, earned = EconomyService.AddMoney(profile, bounty.RewardMoney)
		earned = finiteNumber(earned, 0)
		if earned ~= bounty.RewardMoney then
			player:SetAttribute("BountyMessage", "Daily Bounty reward could not be fully granted.")
			bounty.Progress = math.max(0, bounty.Goal - 1)
			bounty.Claimed = false
			PlayerService.Sync(player)
			return false
		end

		bounty.Claimed = true
		player:SetAttribute("BountyMessage", string.format("Daily Bounty complete! +%d Money", earned))
		PlayerService.Sync(player)
		return true
	end
	player:SetAttribute("BountyMessage", string.format("Daily Bounty: %s %d/%d", bounty.EnemyType, bounty.Progress, bounty.Goal))
	return false
end

function DailyBountyService.Get(profile)
	return snapshot(DailyBountyService.Refresh(profile))
end

return DailyBountyService
