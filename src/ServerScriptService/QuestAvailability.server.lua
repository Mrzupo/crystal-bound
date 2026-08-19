local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerService = require(script.Parent.Services.PlayerService)
local QuestSystem = require(ReplicatedStorage.Modules.QuestSystem)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("GetAvailableQuests")
if remote then
	if not remote:IsA("RemoteFunction") then
		error(("Crystal Bound: GetAvailableQuests has class %s, expected RemoteFunction"):format(remote.ClassName))
	end
else
	remote = Instance.new("RemoteFunction")
	remote.Name = "GetAvailableQuests"
	remote.Parent = remotes
end

local REQUEST_INTERVAL = 0.2
local nextRequest = setmetatable({}, { __mode = "k" })

remote.OnServerInvoke = function(player)
	if not player or not player:IsA("Player") then return nil end
	local now = os.clock()
	if now < (nextRequest[player] or 0) then
		return nil
	end
	nextRequest[player] = now + REQUEST_INTERVAL
	local profile = PlayerService.GetProfile(player)
	if not profile then return {} end
	return QuestSystem.GetAvailable(profile)
end

Players.PlayerRemoving:Connect(function(player)
	nextRequest[player] = nil
end)
