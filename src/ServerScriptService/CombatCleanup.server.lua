local Players = game:GetService("Players")
local CombatService = require(script.Parent.Services.CombatService)

Players.PlayerRemoving:Connect(function(player)
	CombatService.CleanupPlayer(player)
end)
