local Players = game:GetService("Players")
local PlayerService = require(script.Parent.Services.PlayerService)

Players.PlayerRemoving:Connect(function(player)
	local ok = PlayerService.Remove(player)
	if not ok then
		warn(("Crystal Bound: profile remove failed for %s."):format(player.Name))
	end
end)
