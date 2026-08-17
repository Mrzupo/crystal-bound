local DataStoreService = game:GetService("DataStoreService")
local PlayerData = require(script.Parent.PlayerData)

local SaveSystem = {}
local store = DataStoreService:GetDataStore("CrystalBound_PlayerData_v2")
local RETRIES = 3

local function retry(callback)
	local lastError
	for attempt = 1, RETRIES do
		local ok, result = pcall(callback)
		if ok then
			return true, result
		end
		lastError = result
		task.wait(attempt)
	end
	return false, lastError
end

function SaveSystem.Load(player)
	local ok, data = retry(function()
		return store:GetAsync(tostring(player.UserId))
	end)

	if ok and type(data) == "table" then
		return PlayerData.Reconcile(data)
	end

	if not ok then
		warn(("Crystal Bound: failed to load %s: %s"):format(player.Name, tostring(data)))
	end
	return PlayerData.new()
end

function SaveSystem.Save(player, data)
	if type(data) ~= "table" then
		return false, "Invalid profile"
	end

	local payload = PlayerData.Reconcile(data)
	local ok, result = retry(function()
		return store:UpdateAsync(tostring(player.UserId), function()
			return payload
		end)
	end)

	if not ok then
		warn(("Crystal Bound: failed to save %s: %s"):format(player.Name, tostring(result)))
	end
	return ok, result
end

return SaveSystem