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

local function cleanupFailedRemoval(player)
	cleanupUnloadedPlayer(player)
	PlayerService.Profiles[player] = nil
	PlayerService.ProfileRevisions[player] = nil
	PlayerService.RemovalResults[player] = false
	PlayerService.Closing[player] = true
	if player.Parent then player:SetAttribute("ProfileLoaded", false) end
end

Players.PlayerRemoving:Connect(function(player)
	local ok = PlayerService.Remove(player)
	if not ok then
		warn(("Crystal Bound: profile remove failed for %s; local player state was quarantined and the session lock was retained by PlayerService."):format(player.Name))
		cleanupFailedRemoval(player)
		return
	end
	if PlayerService.Profiles[player] == nil then
		cleanupUnloadedPlayer(player)
	end
end)
