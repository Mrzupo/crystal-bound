local Players = game:GetService("Players")
local PlayerService = require(script.Parent.Services.PlayerService)

local function cleanupUnloadedPlayer(player)
	local characterConnection = PlayerService.CharacterConnections[player]
	if characterConnection and characterConnection.Connected then characterConnection:Disconnect() end
	PlayerService.CharacterConnections[player] = nil

	local humanoidConnections = PlayerService.HumanoidConnections[player]
	if humanoidConnections then
		for _, connection in ipairs(humanoidConnections) do
			if connection.Connected then connection:Disconnect() end
		end
	end
	PlayerService.HumanoidConnections[player] = nil
end

Players.PlayerRemoving:Connect(function(player)
	local ok = PlayerService.Remove(player)
	if not ok then
		warn(("Crystal Bound: profile remove failed for %s."):format(player.Name))
	end
	if PlayerService.Profiles[player] == nil then
		cleanupUnloadedPlayer(player)
	end
end)