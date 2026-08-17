local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SaveSystem = require(ReplicatedStorage.Modules.SaveSystem)
local PlayerData = require(ReplicatedStorage.Modules.PlayerData)

local PlayerService = { Profiles = {} }

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
	if PlayerService.Profiles[player] then
		return PlayerService.Profiles[player]
	end

	local profile = PlayerData.Reconcile(SaveSystem.Load(player))
	PlayerService.Profiles[player] = profile
	setupLeaderstats(player, profile)
	player:SetAttribute("Level", profile.Level)
	player:SetAttribute("Experience", profile.Experience)
	player:SetAttribute("Money", profile.Money)
	player:SetAttribute("EquippedCrystal", profile.Crystals.Equipped)
	return profile
end

function PlayerService.Sync(player)
	local profile = PlayerService.Profiles[player]
	if not profile then return end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local level = leaderstats:FindFirstChild("Level")
		local money = leaderstats:FindFirstChild("Money")
		if level then level.Value = profile.Level end
		if money then money.Value = profile.Money end
	end
	player:SetAttribute("Level", profile.Level)
	player:SetAttribute("Experience", profile.Experience)
	player:SetAttribute("Money", profile.Money)
	player:SetAttribute("EquippedCrystal", profile.Crystals.Equipped)
end

function PlayerService.Save(player)
	local profile = PlayerService.Profiles[player]
	if not profile then return false end
	PlayerService.Sync(player)
	return SaveSystem.Save(player, profile)
end

function PlayerService.Remove(player)
	PlayerService.Save(player)
	PlayerService.Profiles[player] = nil
end

Players.PlayerRemoving:Connect(function(player)
	PlayerService.Remove(player)
end)

return PlayerService