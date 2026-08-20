local Players = game:GetService("Players")
local PlayerService = require(script.Parent.Services.PlayerService)

-- Bootstrap owns normal PlayerAdded loading. This catch-up only covers players
-- who already exist before Bootstrap finishes binding PlayerAdded.
task.defer(function()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Parent and not PlayerService.GetProfile(player) and not PlayerService.LoadingByUserId[player.UserId] then
			local profile, reason = PlayerService.Load(player)
			if not profile and player.Parent then
				player:Kick(reason or "Unable to load your Crystal Bound profile safely.")
			end
		end
	end
end)
