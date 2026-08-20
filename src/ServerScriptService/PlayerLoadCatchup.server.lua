local Players = game:GetService("Players")
local PlayerService = require(script.Parent.Services.PlayerService)

-- Bootstrap owns normal PlayerAdded loading. This bounded catch-up covers players
-- entering while Bootstrap is still initializing the world and before its handler binds.
local STARTUP_WINDOW = 30
local SCAN_INTERVAL = 0.25

local function catchUpPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Parent
			and player:GetAttribute("ProfileLoadFailed") == nil
			and not PlayerService.GetProfile(player)
			and not PlayerService.LoadingByUserId[player.UserId]
		then
			local profile, reason = PlayerService.Load(player)
			if not profile and player.Parent then
				player:Kick(reason or "Unable to load your Crystal Bound profile safely.")
			end
		end
	end
end

task.spawn(function()
	local deadline = os.clock() + STARTUP_WINDOW
	repeat
		catchUpPlayers()
		task.wait(SCAN_INTERVAL)
	until os.clock() >= deadline
end)
