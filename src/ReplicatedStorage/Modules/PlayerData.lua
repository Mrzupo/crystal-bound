local PlayerData = {}

local function clone(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, child in pairs(value) do
		result[key] = clone(child)
	end
	return result
end

function PlayerData.new()
	return {
		Version = 1,
		Level = 1,
		Experience = 0,
		Crystals = {
			Owned = { "EMBER" },
			Equipped = "EMBER",
		},
		Money = 100,
		Stats = {
			Damage = 10,
			Health = 100,
		},
		Inventory = {},
		ActiveQuests = {},
		CompletedQuests = {},
		UnlockedIslands = { "STARTER" },
		Titles = {},
	}
end

function PlayerData.Reconcile(data)
	local defaults = PlayerData.new()
	data = type(data) == "table" and data or {}

	local function merge(target, fallback)
		for key, value in pairs(fallback) do
			if target[key] == nil then
				target[key] = clone(value)
			elseif type(value) == "table" and type(target[key]) == "table" then
				merge(target[key], value)
			end
		end
	end

	merge(data, defaults)
	data.Version = defaults.Version
	return data
end

return PlayerData