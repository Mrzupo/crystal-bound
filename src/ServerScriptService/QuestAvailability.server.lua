local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerService = require(script.Parent.Services.PlayerService)
local QuestSystem = require(ReplicatedStorage.Modules.QuestSystem)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("GetAvailableQuests")
if not remote then
	remote = Instance.new("RemoteFunction")
	remote.Name = "GetAvailableQuests"
	remote.Parent = remotes
end

remote.OnServerInvoke = function(player)
	if not player or not player:IsA("Player") then return {} end
	local profile = PlayerService.GetProfile(player)
	if not profile then return {} end
	return QuestSystem.GetAvailable(profile)
end

Players.PlayerRemoving:Connect(function(player)
	-- RemoteFunction remains shared; profiles are owned by PlayerService.
end)
