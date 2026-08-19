local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeProfileStore = require(ReplicatedStorage.Modules.SafeProfileStore)
local PlayerService = require(script.Parent.Services.PlayerService)

local HEARTBEAT_INTERVAL = 45
local MAX_CONSECUTIVE_FAILURES = 2
local failures = setmetatable({}, { __mode = "k" })

while true do
	task.wait(HEARTBEAT_INTERVAL)
	for _, player in ipairs(Players:GetPlayers()) do
		if PlayerService.GetProfile(player) then
			local ok, reason = SafeProfileStore.Refresh(player)
			player:SetAttribute("SessionHeartbeatOk", ok == true)
			if ok then
				failures[player] = 0
			else
				failures[player] = (failures[player] or 0) + 1
				warn(("Crystal Bound: session heartbeat failed for %s: %s"):format(player.Name, tostring(reason)))
				if failures[player] >= MAX_CONSECUTIVE_FAILURES then
					player:Kick("Crystal Bound lost the save-session lock. Please rejoin to protect your progress.")
				end
			end
		end
	end
end
