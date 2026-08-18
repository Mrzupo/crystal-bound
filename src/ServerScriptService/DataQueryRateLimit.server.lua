local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = require(script.Parent.Services.PlayerService)
local QuestSystem = require(ReplicatedStorage.Modules.QuestSystem)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local playerDataRemote = remotes:WaitForChild("GetPlayerData")
local questDataRemote = remotes:WaitForChild("GetQuestData")

local INTERVAL = 0.2
local nextPlayerData = setmetatable({}, { __mode = "k" })
local nextQuestData = setmetatable({}, { __mode = "k" })

local function allowed(bucket, player)
	local now = os.clock()
	if now < (bucket[player] or 0) then return false end
	bucket[player] = now + INTERVAL
	return true
end

playerDataRemote.OnServerInvoke = function(player)
	if not allowed(nextPlayerData, player) then return nil end
	local profile = PlayerService.GetProfile(player)
	if not profile then return nil end
	return {
		Level = profile.Level,
		Experience = profile.Experience,
		Money = profile.Money,
		Crystals = profile.Crystals,
		CrystalMastery = profile.CrystalMastery,
		Inventory = profile.Inventory,
		Achievements = profile.Achievements,
		Titles = profile.Titles,
	}
end

questDataRemote.OnServerInvoke = function(player)
	if not allowed(nextQuestData, player) then
		return { Active = {}, Completed = {}, Progress = {}, Definitions = {} }
	end
	local profile = PlayerService.GetProfile(player)
	if not profile then
		return { Active = {}, Completed = {}, Progress = {}, Definitions = QuestSystem.GetDefinitions() }
	end
	return {
		Active = profile.ActiveQuests,
		Completed = profile.CompletedQuests,
		Progress = profile.QuestProgress,
		Definitions = QuestSystem.GetDefinitions(),
	}
end

Players.PlayerRemoving:Connect(function(player)
	nextPlayerData[player] = nil
	nextQuestData[player] = nil
end)
