local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local PlayerData = require(script.Parent.PlayerData)

local SafeProfileStore = {}
local store = DataStoreService:GetDataStore("CrystalBound_PlayerData_v2")
local RETRIES = 3
local SESSION_TIMEOUT = 120
local SESSION_ID = game.JobId ~= "" and game.JobId or HttpService:GenerateGUID(false)

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

local function clone(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = clone(child) end
	return result
end

local function timestamp()
	return os.time()
end

function SafeProfileStore.Load(player)
	local key = tostring(player.UserId)
	local claimed = false
	local invalidStoredValue = false
	local ok, result = retry(function()
		claimed = false
		invalidStoredValue = false
		return store:UpdateAsync(key, function(current)
			claimed = false
			invalidStoredValue = false
			if current ~= nil and type(current) ~= "table" then
				invalidStoredValue = true
				return current
			end

			local data = type(current) == "table" and current or PlayerData.new()
			local lock = type(data.SessionLock) == "table" and data.SessionLock or nil
			local lockTimestamp = lock and tonumber(lock.Timestamp) or nil
			local age = lockTimestamp and math.max(0, timestamp() - lockTimestamp) or math.huge
			local sameServer = lock and lock.JobId == SESSION_ID

			if lock and not sameServer and age < SESSION_TIMEOUT then
				return current
			end

			data.SessionLock = { JobId = SESSION_ID, Timestamp = timestamp() }
			claimed = true
			return data
		end)
	end)

	if not ok then
		warn(("Crystal Bound: DataStore load failed for %s: %s"):format(player.Name, tostring(result)))
		return nil, "DataStore load failed"
	end
	if invalidStoredValue then
		warn(("Crystal Bound: refusing to replace invalid stored value for %s"):format(player.Name))
		return nil, "Invalid stored profile data"
	end
	if not claimed then
		return nil, "Profile is already open on another server"
	end
	if type(result) ~= "table" then
		return nil, "Invalid DataStore result"
	end

	local profile = PlayerData.Reconcile(result)
	profile.SessionLock = { JobId = SESSION_ID, Timestamp = timestamp() }
	return profile
end

function SafeProfileStore.Save(player, profile)
	if type(profile) ~= "table" then
		return false, "Invalid profile"
	end

	local key = tostring(player.UserId)
	local saved = false
	local ok, result = retry(function()
		saved = false
		return store:UpdateAsync(key, function(current)
			saved = false
			if type(current) ~= "table" then
				return current
			end
			local lock = current.SessionLock
			if type(lock) ~= "table" or lock.JobId ~= SESSION_ID then
				return current
			end
			local payload = PlayerData.Reconcile(clone(profile))
			payload.SessionLock = { JobId = SESSION_ID, Timestamp = timestamp() }
			saved = true
			return payload
		end)
	end)

	if not ok then
		warn(("Crystal Bound: DataStore save failed for %s: %s"):format(player.Name, tostring(result)))
		return false, result
	end
	if not saved then
		warn(("Crystal Bound: save refused for %s because the profile lock is not owned by this server"):format(player.Name))
		return false, "Profile lock lost"
	end
	return true, result
end

function SafeProfileStore.Refresh(player)
	local key = tostring(player.UserId)
	local refreshed = false
	local ok, result = retry(function()
		refreshed = false
		return store:UpdateAsync(key, function(current)
			refreshed = false
			if type(current) ~= "table" then return current end
			local lock = current.SessionLock
			if type(lock) ~= "table" or lock.JobId ~= SESSION_ID then
				return current
			end
			lock.Timestamp = timestamp()
			current.SessionLock = lock
			refreshed = true
			return current
		end)
	end)
	if not ok then
		warn(("Crystal Bound: session refresh failed for %s: %s"):format(player.Name, tostring(result)))
		return false, result
	end
	return refreshed, refreshed and nil or "Profile lock lost"
end

function SafeProfileStore.Release(player)
	local key = tostring(player.UserId)
	local released = false
	local ok, result = retry(function()
		released = false
		return store:UpdateAsync(key, function(current)
			released = false
			if type(current) ~= "table" then return current end
			local lock = current.SessionLock
			if type(lock) == "table" and lock.JobId == SESSION_ID then
				current.SessionLock = nil
				released = true
			end
			return current
		end)
	end)
	if not ok then
		warn(("Crystal Bound: failed to release profile for %s: %s"):format(player.Name, tostring(result)))
	end
	return ok and released
end

return SafeProfileStore