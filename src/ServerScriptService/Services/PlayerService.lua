local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SaveSystem = require(ReplicatedStorage.Modules.SaveSystem)
local PlayerData = require(ReplicatedStorage.Modules.PlayerData)
local CrystalSystem = require(ReplicatedStorage.Modules.CrystalSystem)
local CrystalMastery = require(ReplicatedStorage.Modules.CrystalMastery)
local AchievementService = require(script.Parent.AchievementService)
local EconomyService = require(script.Parent.EconomyService)

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

function PlayerService.GetProfile(player)
	return PlayerService.Profiles[player]
end

function PlayerService.Load(player)
	if PlayerService.Profiles[player] then return PlayerService.Profiles[player] end
	local profile = PlayerData.Reconcile(SaveSystem.Load(player))
	PlayerService.Profiles[player] = profile
	setupLeaderstats(player, profile)
	if PlayerService.CharacterConnections[player] then
		PlayerService.CharacterConnections[player]:Disconnect()
	end
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

	local newAchievements = AchievementService.Check(profile)
	for _, reward in ipairs(newAchievements) do
		local definition = reward.Definition
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
	player:SetAttribute("Level", profile.Level)
	player:SetAttribute("Experience", profile.Experience)
	player:SetAttribute("Money", profile.Money)
	player:SetAttribute("EquippedCrystal", crystalId)
	player:SetAttribute("DamageMultiplier", (passive.DamageMultiplier or 1) * masteryBonuses.DamageMultiplier)
	player:SetAttribute("WalkSpeedBonus", (passive.WalkSpeedBonus or 0) + masteryBonuses.WalkSpeedBonus)
	player:SetAttribute("MaxHealthBonus", (passive.MaxHealthBonus or 0) + masteryBonuses.MaxHealthBonus)
	player:SetAttribute("CrystalMasteryLevel", mastery.Level)
	player:SetAttribute("CrystalMasteryXP", mastery.XP)
	player:SetAttribute("Title", (profile.Titles and profile.Titles[#profile.Titles]) or "")

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
