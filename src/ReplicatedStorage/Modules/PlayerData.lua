local PlayerData = {}

function PlayerData.new()
	return {
		Level = 1,
		Experience = 0,
		Crystals = { Owned = {}, Equipped = "" },
		Money = 0,
		Stats = {},
		Inventory = {},
		ActiveQuests = {},
		CompletedQuests = {},
		UnlockedIslands = {},
		Titles = {},
	}
end

return PlayerData
