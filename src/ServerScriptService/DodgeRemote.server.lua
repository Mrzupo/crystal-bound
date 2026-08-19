local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DodgeService = require(script.Parent.Services.DodgeService)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("DodgeRequest")
if remote then
	if not remote:IsA("RemoteEvent") then
		error(("Crystal Bound: DodgeRequest has class %s, expected RemoteEvent"):format(remote.ClassName))
	end
else
	remote = Instance.new("RemoteEvent")
	remote.Name = "DodgeRequest"
	remote.Parent = remotes
end

local REQUEST_INTERVAL = 0.05
local nextRequest = setmetatable({}, { __mode = "k" })

remote.OnServerEvent:Connect(function(player, direction)
	local now = os.clock()
	if now < (nextRequest[player] or 0) then return end
	nextRequest[player] = now + REQUEST_INTERVAL
	DodgeService.TryDodge(player, direction)
end)

Players.PlayerRemoving:Connect(function(player)
	nextRequest[player] = nil
end)
