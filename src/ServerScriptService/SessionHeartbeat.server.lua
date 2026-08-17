local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeProfileStore = require(ReplicatedStorage.Modules.SafeProfileStore)
local PlayerService = require(script.Parent.Services.PlayerService)

local HEARTBEAT_INTERVAL = 45

while true do
	task.wait(HEARTBEAT_INTERVAL)
	for _, player in ipairs(Players:GetPlayers()) do
		if PlayerService.GetProfile(player) then
			local ok, reason = SafeProfileStore.Refresh(player)
			player:SetAttribute("SessionHeartbeatOk", ok == true)
			if not ok then
				warn(("Crystal Bound: session heartbeat failed for %s: %s"):format(player.Name, tostring(reason)))
			end
		end
	end
end
