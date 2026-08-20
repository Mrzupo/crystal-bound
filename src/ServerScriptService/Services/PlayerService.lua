local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SafeProfileStore = require(ReplicatedStorage.Modules.SafeProfileStore)
local PlayerService = require(script.Parent.PlayerServiceOriginal)

local originalLoad = PlayerService.Load

function PlayerService.Load(player)
	local success, profile, reason = xpcall(function()
		return originalLoad(player)
	end, debug.traceback)
	if success then
		return profile, reason
	end

	local released = SafeProfileStore.Release(player)
	warn(("Crystal Bound: PlayerService.Load failed before handoff for %s; session lock release=%s; error=%s"):format(player.Name, tostring(released), tostring(profile)))
	return nil, "Profile load initialization failed"
end

return PlayerService
