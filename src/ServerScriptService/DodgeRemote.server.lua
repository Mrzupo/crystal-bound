local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DodgeService = require(script.Parent.Services.DodgeService)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("DodgeRequest")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "DodgeRequest"
	remote.Parent = remotes
end

remote.OnServerEvent:Connect(function(player, direction)
	DodgeService.TryDodge(player, direction)
end)
