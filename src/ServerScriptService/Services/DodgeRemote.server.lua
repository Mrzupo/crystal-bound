local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DodgeService = require(script.Parent.Services.DodgeService)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("DodgeRequest")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "DodgeRequest"
	remote.Parent = remotes
end

local function isFiniteVector3(value)
	if typeof(value) ~= "Vector3" then return false end
	return math.abs(value.X) < 10000 and math.abs(value.Y) < 10000 and math.abs(value.Z) < 10000
end

remote.OnServerEvent:Connect(function(player, direction)
	if direction ~= nil and not isFiniteVector3(direction) then
		return
	end
	DodgeService.TryDodge(player, direction)
end)
