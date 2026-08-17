local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SaveSystem = require(ReplicatedStorage.Modules.SaveSystem)
local PlayerData = require(ReplicatedStorage.Modules.PlayerData)
local CrystalSystem = require(ReplicatedStorage.Modules.CrystalSystem)
local CrystalMastery = require(ReplicatedStorage.Modules.CrystalMastery)
local EconomyService = require(script.Parent.EconomyService)
local BossService = require(script.Parent.BossService)

local AchievementDefinitions = {
	FIRST_BLOOD = { Name = "First Blood", RewardMoney = 50, Title = "Fighter" },
	CRYSTAL_KEEPER = { Name = "Crystal Keeper", RewardMoney = 250, Title = "Crystal Keeper" },
	MASTER_OF_ONE = { Name = "Master of One", RewardMoney = 750, Title = "Crystal Master" },
	GUARDIAN_SLAYER = { Name = "Guardian Slayer", RewardMoney = 2500, Title = "Guardian Slayer" },
	LEVEL_20 = { Name = "Veteran", RewardMoney = 1000, Title = "Veteran" },
}

local function hasAchievement(profile, id)
	return table.find(profile.Achievements or {}, id) ~= nil
end

local function unlockAchievement(profile, id)
	if hasAchievement(profile, id) or not AchievementDefinitions[id] then return nil end
	profile.Achievements = profile.Achievements or {}
	profile.Titles = profile.Titles or {}
	table.insert(profile.Achievements, id)
	local definition = AchievementDefinitions[id]
	if definition.Title and not table.find(profile.Titles, definition.Title) then
		table.insert(profile.Titles, definition.Title)
	end
	return definition
end

local function checkAchievements(profile)
	local unlocked = {}
	profile.Stats = profile.Stats or {}
	local owned = profile.Crystals and profile.Crystals.Owned or {}
	local allCrystals = table.find(owned, "EMBER") and table.find(owned, "TIDE") and table.find(owned, "GALE")
	local mastery = profile.CrystalMastery or {}
	local masteryTen = (mastery.EMBER and mastery.EMBER.Level >= 10)
		or (mastery.TIDE and mastery.TIDE.Level >= 10)
		or (mastery.GALE and mastery.GALE.Level >= 10)
	local checks = {
		FIRST_BLOOD = (profile.Stats.EnemiesDefeated or 0) >= 1,
		CRYSTAL_KEEPER = allCrystals,
		MASTER_OF_ONE = masteryTen,
		GUARDIAN_SLAYER = (profile.Stats.BossesDefeated or 0) >= 1,
		LEVEL_20 = profile.Level >= 20,
	}
	for id, condition in pairs(checks) do
		if condition then
			local definition = unlockAchievement(profile, id)
			if definition then table.insert(unlocked, definition) end
		end
	end
	return unlocked
end

local PlayerService = { Profiles = {}, CharacterConnections = {} }

local function setupLeaderstats(player, profile)
	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local level = leaderstats:FindFirstChild("Level") or Instance.new("IntValue")
	level.Name = "Level"
	level.Value = profile.Level
	level.Parent = leaderstats
	local money = leaderstats:FindFirstChild("Money") or Instance.new("IntValue")
	money.Name = "Money"
	money.Value = profile.Money
	money.Parent = leaderstats
end

local function updateTitleTag(player, title)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then return end
	local existing = head:FindFirstChild("CrystalBoundTitle")
	if existing then existing:Destroy() end
	if not title or title == "" then return end
	local tag = Instance.new("BillboardGui")
	tag.Name = "CrystalBoundTitle"
	tag.Size = UDim2.fromOffset(240, 36)
	tag.StudsOffset = Vector3.new(0, 2.8, 0)
	tag.AlwaysOnTop = true
	tag.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "< " .. title .. " >"
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.Parent = tag
end

function PlayerService.GetProfile(player)
	return PlayerService.Profiles[player]
end

function PlayerService.Load(player)
	if PlayerService.Profiles[player] then return PlayerService.Profiles[player] end
	BossService.Bind()
	local profile = PlayerData.Reconcile(SaveSystem.Load(player))
	PlayerService.Profiles[player] = profile
	setupLeaderstats(player, profile)
	if PlayerService.CharacterConnections[player] then PlayerService.CharacterConnections[player]:Disconnect() end
	PlayerService.CharacterConnections[player] = player.CharacterAdded:Connect(function()
		task.defer(function()
			if PlayerService.Profiles[player] then PlayerService.Sync(player) end
		end)
	end)
	PlayerService.Sync(player)
	return profile
end

function PlayerService.Sync(player)
	local profile = PlayerService.Profiles[player]
	if not profile then return end

	local unlocked = checkAchievements(profile)
	for _, definition in ipairs(unlocked) do
		EconomyService.AddMoney(profile, definition.RewardMoney or 0)
		player:SetAttribute("AchievementMessage", "Achievement unlocked: " .. definition.Name)
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local level = leaderstats:FindFirstChild("Level")
		local money = leaderstats:FindFirstChild("Money")
		if level then level.Value = profile.Level end
		if money then money.Value = profile.Money end
	end

	local crystalId = profile.Crystals.Equipped
	local passive = CrystalSystem.GetPassive(crystalId)
	local mastery = CrystalMastery.Get(profile, crystalId)
	local masteryBonuses = CrystalMastery.GetBonuses(profile, crystalId)
	local title = (profile.Titles and profile.Titles[#profile.Titles]) or ""
	player:SetAttribute("Level", profile.Level)
	player:SetAttribute("Experience", profile.Experience)
	player:SetAttribute("Money", profile.Money)
	player:SetAttribute("EquippedCrystal", crystalId)
	player:SetAttribute("DamageMultiplier", (passive.DamageMultiplier or 1) * masteryBonuses.DamageMultiplier)
	player:SetAttribute("WalkSpeedBonus", (passive.WalkSpeedBonus or 0) + masteryBonuses.WalkSpeedBonus)
	player:SetAttribute("MaxHealthBonus", (passive.MaxHealthBonus or 0) + masteryBonuses.MaxHealthBonus)
	player:SetAttribute("CrystalMasteryLevel", mastery.Level)
	player:SetAttribute("CrystalMasteryXP", mastery.XP)
	player:SetAttribute("Title", title)
	player:SetAttribute("AchievementCount", #(profile.Achievements or {}))
	updateTitleTag(player, title)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16 + (passive.WalkSpeedBonus or 0) + masteryBonuses.WalkSpeedBonus
		local maxHealth = 100 + (passive.MaxHealthBonus or 0) + masteryBonuses.MaxHealthBonus
		local oldMax = humanoid.MaxHealth
		humanoid.MaxHealth = maxHealth
		if humanoid.Health > 0 and humanoid.Health == oldMax then humanoid.Health = maxHealth end
	end
end

function PlayerService.Save(player)
	local profile = PlayerService.Profiles[player]
	if not profile then return false end
	PlayerService.Sync(player)
	return SaveSystem.Save(player, profile)
end

function PlayerService.Remove(player)
	PlayerService.Save(player)
	if PlayerService.CharacterConnections[player] then
		PlayerService.CharacterConnections[player]:Disconnect()
		PlayerService.CharacterConnections[player] = nil
	end
	PlayerService.Profiles[player] = nil
end

return PlayerService
