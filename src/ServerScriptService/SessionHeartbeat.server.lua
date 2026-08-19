local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeProfileStore = require(ReplicatedStorage.Modules.SafeProfileStore)
local PlayerService = require(script.Parent.Services.PlayerService)

local HEARTBEAT_INTERVAL = 45
local MAX_CONSECUTIVE_FAILURES = 2
local SHUTDOWN_TIMEOUT = 25
local failures = setmetatable({}, { __mode = "k" })
local shuttingDown = false

local function shutdownProfiles()
	shuttingDown = true
	local pending = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if PlayerService.GetProfile(player) then
			pending += 1
			task.spawn(function()
				local ok = PlayerService.Remove(player)
				if not ok then
					warn(("Crystal Bound: shutdown removal failed for %s; session lock may remain until timeout."):format(player.Name))
				end
				pending -= 1
			end)
		end
	end

	local deadline = os.clock() + SHUTDOWN_TIMEOUT
	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
	if pending > 0 then
		warn(("Crystal Bound: shutdown save/release timed out with %d player profile(s) still pending."):format(pending))
	end
end

game:BindToClose(shutdownProfiles)

task.spawn(function()
	while not shuttingDown do
		task.wait(HEARTBEAT_INTERVAL)
		if shuttingDown then break end
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
end)
