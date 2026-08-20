local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerService = require(script.Parent.Services.PlayerService)

local HEARTBEAT_INTERVAL = 45
local AUTOSAVE_INTERVAL = 60
local MAX_CONSECUTIVE_FAILURES = 2
local SHUTDOWN_TIMEOUT = 25
local failures = setmetatable({}, { __mode = "k" })
local autosaveFailures = setmetatable({}, { __mode = "k" })
local shuttingDown = false

ReplicatedStorage:SetAttribute("CrystalBoundShuttingDown", false)

local function shutdownProfiles()
	shuttingDown = true
	PlayerService.BeginShutdown()
	ReplicatedStorage:SetAttribute("CrystalBoundShuttingDown", true)
	local pending = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if PlayerService.HasLoadedProfile(player) then
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
	while os.clock() < deadline do
		if pending <= 0 and PlayerService.GetPendingLoadCount() <= 0 then
			break
		end
		task.wait(0.1)
	end
	local pendingLoads = PlayerService.GetPendingLoadCount()
	if pending > 0 or pendingLoads > 0 then
		warn(("Crystal Bound: shutdown save/release timed out with %d loaded profile(s) and %d pending load(s)."):format(pending, pendingLoads))
	end
end

game:BindToClose(shutdownProfiles)

task.spawn(function()
	while not shuttingDown do
		task.wait(HEARTBEAT_INTERVAL)
		if shuttingDown then break end
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Parent and PlayerService.GetProfile(player) then
				local ok = PlayerService.RefreshSession(player)
				player:SetAttribute("SessionHeartbeatOk", ok == true)
				if ok then
					failures[player] = 0
				else
					failures[player] = (failures[player] or 0) + 1
					warn(("Crystal Bound: session heartbeat failed for %s."):format(player.Name))
					if failures[player] >= MAX_CONSECUTIVE_FAILURES then
						player:Kick("Crystal Bound lost the save-session lock. Please rejoin to protect your progress.")
					end
				end
			end
		end
	end
end)

task.spawn(function()
	while not shuttingDown do
		task.wait(AUTOSAVE_INTERVAL)
		if shuttingDown then break end
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Parent and PlayerService.GetProfile(player) then
				local ok = PlayerService.Save(player)
				player:SetAttribute("AutosaveOk", ok == true)
				if ok then
					autosaveFailures[player] = 0
				else
					autosaveFailures[player] = (autosaveFailures[player] or 0) + 1
					warn(("Crystal Bound: autosave failed for %s."):format(player.Name))
					if autosaveFailures[player] >= MAX_CONSECUTIVE_FAILURES then
						player:Kick("Crystal Bound could not safely save your progress. Please rejoin to protect it.")
					end
				end
			end
		end
	end
end)